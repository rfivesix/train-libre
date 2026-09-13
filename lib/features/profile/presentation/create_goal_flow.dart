// lib/features/profile/presentation/create_goal_flow.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart';
import '../../../widgets/common/summary_card.dart';
import '../data/goal_repository_impl.dart';
import '../domain/models/goal_model.dart';
import '../domain/repositories/goal_repository.dart';

class CreateGoalFlow extends StatefulWidget {
  final IGoalRepository? repository;

  const CreateGoalFlow({super.key, this.repository});

  @override
  State<CreateGoalFlow> createState() => _CreateGoalFlowState();
}

class _CreateGoalFlowState extends State<CreateGoalFlow> {
  late final IGoalRepository _repository =
      widget.repository ?? GoalRepositoryImpl();

  int _currentStep = 0;
  static const int _totalSteps = 6;

  // Step 0: Absicht / Preset
  GoalPreset _preset = GoalPreset.loseWeight;
  final _customTitleController = TextEditingController();
  String _customDirection = 'lose'; // 'lose', 'gain', 'maintain'

  // Step 1: Startdatum & Baseline
  DateTime _startDate = DateTime.now();
  double? _detectedBaselineWeight; // in kg
  DateTime? _detectedBaselineDate;
  final _baselineWeightController = TextEditingController();
  bool _isManualBaselineMode = false;

  // Step 2: Zielgewicht
  final _targetWeightController = TextEditingController();

  // Step 3: Tempo & Zieldatum (Interaktiver Planer)
  DateTime? _targetDate;
  double _weeklyRateKg = 0.50; // positive magnitude

  // Step 4: Motivation
  final _reasonController = TextEditingController();
  final _reasonFocusNode = FocusNode();

  // Step 5: Review & Aktivieren
  bool _isNutritionDriver = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _detectBaseline();
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _baselineWeightController.dispose();
    _targetWeightController.dispose();
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _detectBaseline() async {
    final startEndOfDay = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      23,
      59,
      59,
    );

    final database = DatabaseHelper.instance.dbInstance;
    final allMeasurements = await (database.select(database.measurements)
          ..where((t) => t.type.equals('weight')))
        .get();
    final valid = allMeasurements
        .where((m) =>
            m.date.isBefore(startEndOfDay) ||
            m.date.isAtSameMomentAs(startEndOfDay))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final row = valid.firstOrNull;

    if (!mounted) return;
    final unitService = context.read<UnitService>();
    setState(() {
      _detectedBaselineWeight = row?.value;
      _detectedBaselineDate = row?.date;
      if (row?.value != null && _baselineWeightController.text.isEmpty) {
        final disp =
            unitService.convertDisplayValue(row!.value, UnitDimension.weight);
        _baselineWeightController.text = disp.toStringAsFixed(1);
      }
    });
  }

  double? _getBaselineKg(UnitService unitService) {
    if (!_isManualBaselineMode && _detectedBaselineWeight != null) {
      return _detectedBaselineWeight;
    }
    final text = _baselineWeightController.text.trim();
    if (text.isEmpty) return _detectedBaselineWeight;
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return _detectedBaselineWeight;
    return unitService.convertToMetric(parsed, UnitDimension.weight);
  }

  double? _getTargetKg(UnitService unitService) {
    final text = _targetWeightController.text.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    return unitService.convertToMetric(parsed, UnitDimension.weight);
  }

  double _getDeltaKg(UnitService unitService) {
    final b = _getBaselineKg(unitService);
    final t = _getTargetKg(unitService);
    if (b == null || t == null) return 0.0;
    return (t - b).abs();
  }

  void _onTargetDateChanged(DateTime newDate, UnitService unitService) {
    setState(() {
      _targetDate = newDate;
      final delta = _getDeltaKg(unitService);
      if (delta > 0) {
        final days = max(7, newDate.difference(_startDate).inDays);
        final weeks = days / 7.0;
        _weeklyRateKg = (delta / weeks).clamp(0.05, 2.0);
      }
    });
  }

  void _onWeeklyRateChanged(double newRate, UnitService unitService) {
    setState(() {
      _weeklyRateKg = newRate;
      final delta = _getDeltaKg(unitService);
      if (delta > 0 && newRate > 0) {
        final weeks = delta / newRate;
        final days = (weeks * 7).round();
        _targetDate = _startDate.add(Duration(days: max(7, days)));
      }
    });
  }

  void _nextStep() {
    final unitService = context.read<UnitService>();
    final l10n = AppLocalizations.of(context)!;

    if (_currentStep == 0) {
      if (_preset == GoalPreset.custom &&
          _customTitleController.text.trim().isEmpty) {
        _customTitleController.text = l10n.goalPresetCustom;
      }
    } else if (_currentStep == 1) {
      final baseline = _getBaselineKg(unitService);
      if (baseline == null || baseline <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.goalEnterBaselineWeightPrompt(
                unitService.unitString(UnitDimension.weight),
              ),
            ),
          ),
        );
        return;
      }

      // Pre-fill target weight if empty
      if (_targetWeightController.text.trim().isEmpty) {
        final dispBase =
            unitService.convertDisplayValue(baseline, UnitDimension.weight);
        if (_preset == GoalPreset.loseWeight ||
            (_preset == GoalPreset.custom && _customDirection == 'lose')) {
          final diff =
              unitService.convertDisplayValue(5.0, UnitDimension.weight);
          final targetDisp = max(30.0, dispBase - diff);
          _targetWeightController.text = targetDisp.toStringAsFixed(1);
        } else if (_preset == GoalPreset.gainWeight ||
            (_preset == GoalPreset.custom && _customDirection == 'gain')) {
          final diff =
              unitService.convertDisplayValue(3.0, UnitDimension.weight);
          _targetWeightController.text = (dispBase + diff).toStringAsFixed(1);
        } else {
          _targetWeightController.text = dispBase.toStringAsFixed(1);
        }
      }
    } else if (_currentStep == 2) {
      final target = _getTargetKg(unitService);
      if (target == null || target <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.goalTargetWeightLabel(
                unitService.unitString(UnitDimension.weight),
              ),
            ),
          ),
        );
        return;
      }

      // Initialize trajectory defaults if not yet set
      final baseline = _getBaselineKg(unitService) ?? target;
      final delta = (target - baseline).abs();
      if (delta > 0) {
        if (_preset == GoalPreset.gainWeight ||
            (_preset == GoalPreset.custom && _customDirection == 'gain')) {
          _weeklyRateKg = 0.25;
        } else {
          _weeklyRateKg = 0.50;
        }
        final days = (delta / _weeklyRateKg * 7).round();
        _targetDate = _startDate.add(Duration(days: max(7, days)));
      } else {
        _weeklyRateKg = 0.0;
        _targetDate = _startDate.add(const Duration(days: 84));
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitGoal() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final unitService = context.read<UnitService>();
    final l10n = AppLocalizations.of(context)!;

    String title;
    if (_preset == GoalPreset.custom &&
        _customTitleController.text.trim().isNotEmpty) {
      title = _customTitleController.text.trim();
    } else {
      switch (_preset) {
        case GoalPreset.loseWeight:
          title = l10n.goalPresetLoseWeight;
          break;
        case GoalPreset.gainWeight:
          title = l10n.goalPresetGainWeight;
          break;
        case GoalPreset.maintainWeight:
          title = l10n.goalPresetMaintainWeight;
          break;
        case GoalPreset.recomposition:
          title = l10n.goalPresetRecomposition;
          break;
        case GoalPreset.custom:
          title = l10n.goalPresetCustom;
          break;
      }
    }

    final baselineKg = _getBaselineKg(unitService);
    final targetKg = _getTargetKg(unitService);

    // If user entered a manual baseline and no measurement was recorded at _startDate,
    // record this measurement now so trajectory calculations have an immediate starting anchor.
    if (_detectedBaselineWeight == null && baselineKg != null) {
      try {
        final database = DatabaseHelper.instance.dbInstance;
        await database.into(database.measurements).insert(
              db.MeasurementsCompanion.insert(
                date: _startDate,
                type: 'weight',
                value: baselineKg,
                unit: 'kg',
              ),
            );
      } catch (_) {
        // Silently ignore measurement insertion errors to avoid blocking goal creation
      }
    }

    double? signedWeeklyRateKg;
    if (_preset == GoalPreset.loseWeight ||
        (_preset == GoalPreset.custom && _customDirection == 'lose')) {
      signedWeeklyRateKg = -_weeklyRateKg.abs();
    } else if (_preset == GoalPreset.gainWeight ||
        (_preset == GoalPreset.custom && _customDirection == 'gain')) {
      signedWeeklyRateKg = _weeklyRateKg.abs();
    } else {
      signedWeeklyRateKg = 0.0;
    }

    try {
      await _repository.createGoal(
        preset: _preset,
        title: title,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
        startDate: _startDate,
        targetDate: _targetDate,
        targetMetric: 'weight',
        targetValue: targetKg,
        targetUnit: 'kg',
        desiredWeeklyRateKg: signedWeeklyRateKg,
        isNutritionDriver: _isNutritionDriver,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Erstellen des Ziels: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.createGoalTitle,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: _previousStep,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(_currentStep),
                padding: DesignConstants.screenPadding,
                child: _buildCurrentStepContent(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignConstants.spacingL),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: AppButton.secondary(
                        label: l10n.back,
                        onPressed: _previousStep,
                      ),
                    ),
                  if (_currentStep > 0)
                    const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      label: _currentStep == _totalSteps - 1
                          ? (_isSaving
                              ? l10n.saving
                              : l10n.goalConfirmCreateButton)
                          : l10n.continueButton,
                      onPressed: _isSaving
                          ? null
                          : (_currentStep == _totalSteps - 1
                              ? _submitGoal
                              : _nextStep),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Preset(context);
      case 1:
        return _buildStep1Baseline(context);
      case 2:
        return _buildStep2TargetWeight(context);
      case 3:
        return _buildStep3Trajectory(context);
      case 4:
        return _buildStep4Reason(context);
      case 5:
        return _buildStep5Review(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // -------------------------------------------------------------
  // Step 0: Absicht / Preset
  // -------------------------------------------------------------
  Widget _buildStep0Preset(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalStep1Question,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.goalStep1Description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),
        _buildPresetTile(
          context,
          preset: GoalPreset.loseWeight,
          title: l10n.goalPresetLoseWeight,
          subtitle: l10n.goalPresetLoseWeightDescription,
          icon: LucideIcons.trending_down,
        ),
        _buildPresetTile(
          context,
          preset: GoalPreset.gainWeight,
          title: l10n.goalPresetGainWeight,
          subtitle: l10n.goalPresetGainWeightDescription,
          icon: LucideIcons.trending_up,
        ),
        _buildPresetTile(
          context,
          preset: GoalPreset.maintainWeight,
          title: l10n.goalPresetMaintainWeight,
          subtitle: l10n.goalPresetMaintainWeightDescription,
          icon: LucideIcons.scale,
        ),
        _buildPresetTile(
          context,
          preset: GoalPreset.recomposition,
          title: l10n.goalPresetRecomposition,
          subtitle: l10n.goalPresetRecompositionDescription,
          icon: LucideIcons.refresh_cw,
        ),
        _buildPresetTile(
          context,
          preset: GoalPreset.custom,
          title: l10n.goalPresetCustom,
          subtitle: l10n.goalPresetCustomDescription,
          icon: LucideIcons.target,
        ),
        if (_preset == GoalPreset.custom) ...[
          const SizedBox(height: DesignConstants.spacingM),
          TextField(
            controller: _customTitleController,
            decoration: InputDecoration(
              labelText: l10n.goalCustomTitleLabel,
              hintText: l10n.goalCustomTitleHint,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Text(
            l10n.goalCustomDirectionPrompt,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'lose',
                label: Text(l10n.goalPresetLoseWeight),
                icon: const Icon(LucideIcons.trending_down, size: 16),
              ),
              ButtonSegment(
                value: 'gain',
                label: Text(l10n.goalPresetGainWeight),
                icon: const Icon(LucideIcons.trending_up, size: 16),
              ),
              ButtonSegment(
                value: 'maintain',
                label: Text(l10n.goalPresetMaintainWeight),
                icon: const Icon(LucideIcons.scale, size: 16),
              ),
            ],
            selected: {_customDirection},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                setState(() => _customDirection = set.first);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPresetTile(
    BuildContext context, {
    required GoalPreset preset,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = _preset == preset;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: InkWell(
        onTap: () {
          setState(() {
            _preset = preset;
          });
        },
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: Container(
          padding: const EdgeInsets.all(DesignConstants.spacingM),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.check, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Step 1: Startdatum & Baseline
  // -------------------------------------------------------------
  Widget _buildStep1Baseline(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final unitStr = unitService.unitString(UnitDimension.weight);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    final hasDetected = _detectedBaselineWeight != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalStepBaselineQuestion,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.goalStepBaselineDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        // Start Date Picker
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              Icon(LucideIcons.calendar_days, color: theme.colorScheme.primary),
          title: Text(
            dateFormat.format(_startDate),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(l10n.goalStartDateLabel),
          trailing: const Icon(LucideIcons.chevron_right),
          onTap: () async {
            final picked = await showAdaptiveDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _startDate = picked);
              _detectBaseline();
            }
          },
        ),
        const SizedBox(height: DesignConstants.spacingL),

        // Baseline Status / Input Card
        if (hasDetected && !_isManualBaselineMode) ...[
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Row(
                children: [
                  const Icon(LucideIcons.circle_check,
                      color: Colors.green, size: 28),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.goalBaselineFoundTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${unitService.convertDisplayValue(_detectedBaselineWeight!, UnitDimension.weight).toStringAsFixed(1)} $unitStr'
                          '${_detectedBaselineDate != null ? ' (${dateFormat.format(_detectedBaselineDate!)})' : ''}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isManualBaselineMode = true;
                      });
                    },
                    child: Text(l10n.edit),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.scale,
                          color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: DesignConstants.spacingM),
                      Expanded(
                        child: Text(
                          l10n.goalEnterBaselineWeightPrompt(unitStr),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (hasDetected)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isManualBaselineMode = false;
                            });
                          },
                          child: Text(l10n.cancel),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  TextField(
                    controller: _baselineWeightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.goalStartLabel,
                      suffixText: unitStr,
                      hintText: 'z.B. 80.0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            DesignConstants.borderRadiusM),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // Step 2: Zielgewicht
  // -------------------------------------------------------------
  Widget _buildStep2TargetWeight(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final unitStr = unitService.unitString(UnitDimension.weight);

    final baselineKg = _getBaselineKg(unitService);
    final targetKg = _getTargetKg(unitService);
    final double? baselineDisp = baselineKg != null
        ? unitService.convertDisplayValue(baselineKg, UnitDimension.weight)
        : null;
    final double? targetDisp = targetKg != null
        ? unitService.convertDisplayValue(targetKg, UnitDimension.weight)
        : null;
    final double? deltaDisp = (baselineDisp != null && targetDisp != null)
        ? (targetDisp - baselineDisp)
        : null;

    final isMaintain = _preset == GoalPreset.maintainWeight ||
        _preset == GoalPreset.recomposition ||
        (_preset == GoalPreset.custom && _customDirection == 'maintain');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalStepTargetWeightQuestion,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.goalStepTargetWeightDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        TextField(
          controller: _targetWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.goalTargetWeightLabel(unitStr),
            suffixText: unitStr,
            prefixIcon: const Icon(LucideIcons.target),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        // Live Delta / Calculation Card
        if (baselineDisp != null && targetDisp != null && deltaDisp != null) ...[
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.goalWeightDifferenceLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${deltaDisp >= 0 ? '+' : ''}${deltaDisp.toStringAsFixed(1)} $unitStr',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: deltaDisp == 0
                              ? theme.colorScheme.primary
                              : (deltaDisp < 0
                                  ? Colors.blueAccent
                                  : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.goalBaselineHeader}: ${baselineDisp.toStringAsFixed(1)} $unitStr',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Icon(LucideIcons.arrow_right, size: 14),
                      Text(
                        '${l10n.goalTargetHeader}: ${targetDisp.toStringAsFixed(1)} $unitStr',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
        ],

        // Quick adjustment chips
        if (!isMaintain && baselineDisp != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_preset == GoalPreset.gainWeight ||
                    (_preset == GoalPreset.custom && _customDirection == 'gain'))
                ? [2.0, 4.0, 6.0, 8.0].map((delta) {
                    final target = baselineDisp + delta;
                    return ActionChip(
                      label: Text('+$delta $unitStr (${target.toStringAsFixed(1)})'),
                      onPressed: () {
                        setState(() {
                          _targetWeightController.text =
                              target.toStringAsFixed(1);
                        });
                      },
                    );
                  }).toList()
                : [2.0, 5.0, 10.0, 15.0].map((delta) {
                    final target = max(30.0, baselineDisp - delta);
                    return ActionChip(
                      label: Text('-$delta $unitStr (${target.toStringAsFixed(1)})'),
                      onPressed: () {
                        setState(() {
                          _targetWeightController.text =
                              target.toStringAsFixed(1);
                        });
                      },
                    );
                  }).toList(),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // Step 3: Tempo & Zieldatum (Interaktiver Planer)
  // -------------------------------------------------------------
  Widget _buildStep3Trajectory(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final unitStr = unitService.unitString(UnitDimension.weight);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    final deltaKg = _getDeltaKg(unitService);
    final isMaintain = deltaKg <= 0.05;

    // Daily Calorie impact estimate
    // ~7700 kcal per kg of fat mass
    final dailyCalorieImpact = (_weeklyRateKg * 7700 / 7).round();
    final isLosing = _preset == GoalPreset.loseWeight ||
        (_preset == GoalPreset.custom && _customDirection == 'lose');

    final int weeks = _targetDate != null
        ? max(1, (_targetDate!.difference(_startDate).inDays / 7).round())
        : 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalStepTrajectoryQuestion,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.goalStepTrajectoryDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        if (isMaintain) ...[
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Row(
                children: [
                  const Icon(LucideIcons.scale, color: Colors.green, size: 28),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.goalPresetMaintainWeight,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.goalPaceFeedbackMaintain,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
        ] else ...[
          // Control 1: Weekly Rate Slider & Quick Chips
          Text(
            '${l10n.goalWeeklyRateLabel}: ${_weeklyRateKg.toStringAsFixed(2)} $unitStr / ${l10n.weekShort}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _weeklyRateKg.clamp(0.10, 1.25),
            min: 0.10,
            max: 1.25,
            divisions: 23,
            label: '${_weeklyRateKg.toStringAsFixed(2)} $unitStr',
            onChanged: (val) => _onWeeklyRateChanged(val, unitService),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: Text(l10n.goalRateGentle),
                onPressed: () => _onWeeklyRateChanged(0.25, unitService),
              ),
              ActionChip(
                label: Text(l10n.goalRateModerate),
                onPressed: () => _onWeeklyRateChanged(0.50, unitService),
              ),
              ActionChip(
                label: Text(l10n.goalRateAthletic),
                onPressed: () => _onWeeklyRateChanged(0.75, unitService),
              ),
              ActionChip(
                label: Text(l10n.goalRateAggressive),
                onPressed: () => _onWeeklyRateChanged(1.00, unitService),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Control 2: Target Date Picker & Quick Duration Chips
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(LucideIcons.calendar,
                color: theme.colorScheme.primary),
            title: Text(
              _targetDate != null
                  ? dateFormat.format(_targetDate!)
                  : l10n.goalNoDeadlineOption,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(l10n.goalTargetDateLabel),
            trailing: const Icon(LucideIcons.chevron_right),
            onTap: () async {
              final picked = await showAdaptiveDatePicker(
                context: context,
                initialDate: _targetDate ??
                    _startDate.add(const Duration(days: 84)),
                firstDate: _startDate.add(const Duration(days: 7)),
                lastDate: _startDate.add(const Duration(days: 730)),
              );
              if (picked != null) {
                _onTargetDateChanged(picked, unitService);
              }
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [8, 12, 16, 24].map((w) {
              return ActionChip(
                label: Text(l10n.goalEstimatedDuration(w)),
                onPressed: () {
                  final newDate =
                      _startDate.add(Duration(days: w * 7));
                  _onTargetDateChanged(newDate, unitService);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Live Interactive Trajectory Summary Card
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.goalEstimatedDuration(weeks),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_targetDate != null)
                        Text(
                          dateFormat.format(_targetDate!),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  const Divider(height: 1),
                  const SizedBox(height: DesignConstants.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.goalEstimatedDailyDelta,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${isLosing ? '-' : '+'}$dailyCalorieImpact kcal / Tag',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLosing
                              ? Colors.orangeAccent
                              : Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  Row(
                    children: [
                      Icon(
                        _weeklyRateKg > 1.0
                            ? LucideIcons.triangle_alert
                            : (_weeklyRateKg < 0.3
                                ? LucideIcons.info
                                : LucideIcons.circle_check),
                        size: 16,
                        color: _weeklyRateKg > 1.0
                            ? Colors.orange
                            : (_weeklyRateKg < 0.3
                                ? Colors.blue
                                : Colors.green),
                      ),
                      const SizedBox(width: DesignConstants.spacingS),
                      Expanded(
                        child: Text(
                          _weeklyRateKg > 1.0
                              ? l10n.goalPaceFeedbackAggressive
                              : (_weeklyRateKg < 0.3
                                  ? l10n.goalPaceFeedbackGentle
                                  : l10n.goalPaceFeedbackSafe),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // Step 4: Motivation & Grund
  // -------------------------------------------------------------
  Widget _buildStep4Reason(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalStep6Question,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.goalStep6Description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        // Quick suggestion chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(LucideIcons.heart_pulse, size: 14),
              label: Text(l10n.goalReasonSuggestionHealth),
              onPressed: () {
                setState(() {
                  _reasonController.text = l10n.goalReasonSuggestionHealth;
                });
              },
            ),
            ActionChip(
              avatar: const Icon(LucideIcons.biceps_flexed, size: 14),
              label: Text(l10n.goalReasonSuggestionFitness),
              onPressed: () {
                setState(() {
                  _reasonController.text = l10n.goalReasonSuggestionFitness;
                });
              },
            ),
            ActionChip(
              avatar: const Icon(LucideIcons.sparkles, size: 14),
              label: Text(l10n.goalReasonSuggestionShape),
              onPressed: () {
                setState(() {
                  _reasonController.text = l10n.goalReasonSuggestionShape;
                });
              },
            ),
            ActionChip(
              avatar: const Icon(LucideIcons.trophy, size: 14),
              label: Text(l10n.goalReasonSuggestionEvent),
              onPressed: () {
                setState(() {
                  _reasonController.text = l10n.goalReasonSuggestionEvent;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingM),

        // Multi-line Reason TextField with guaranteed focus
        InkWell(
          onTap: () => _reasonFocusNode.requestFocus(),
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
          child: TextField(
            key: const ValueKey('reason_text_field'),
            focusNode: _reasonFocusNode,
            controller: _reasonController,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.goalReasonPlaceholder,
              filled: true,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        Text(
          l10n.goalReasonPrivacyNotice,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Step 5: Review & Aktivieren
  // -------------------------------------------------------------
  Widget _buildStep5Review(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();
    final unitStr = unitService.unitString(UnitDimension.weight);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    final baselineKg = _getBaselineKg(unitService);
    final targetKg = _getTargetKg(unitService);
    final double? baselineDisp = baselineKg != null
        ? unitService.convertDisplayValue(baselineKg, UnitDimension.weight)
        : null;
    final double? targetDisp = targetKg != null
        ? unitService.convertDisplayValue(targetKg, UnitDimension.weight)
        : null;

    String title;
    if (_preset == GoalPreset.custom &&
        _customTitleController.text.trim().isNotEmpty) {
      title = _customTitleController.text.trim();
    } else {
      switch (_preset) {
        case GoalPreset.loseWeight:
          title = l10n.goalPresetLoseWeight;
          break;
        case GoalPreset.gainWeight:
          title = l10n.goalPresetGainWeight;
          break;
        case GoalPreset.maintainWeight:
          title = l10n.goalPresetMaintainWeight;
          break;
        case GoalPreset.recomposition:
          title = l10n.goalPresetRecomposition;
          break;
        case GoalPreset.custom:
          title = l10n.goalPresetCustom;
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalStep7Question,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          l10n.goalStep7Description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        SummaryCard(
          child: Padding(
            padding: DesignConstants.cardPadding,
            child: Column(
              children: [
                _buildReviewRow(
                  context,
                  label: l10n.goalAreaLabel,
                  value: title,
                  icon: LucideIcons.target,
                ),
                const Divider(height: DesignConstants.spacingL),
                _buildReviewRow(
                  context,
                  label: l10n.goalStartLabel,
                  value: baselineDisp != null
                      ? '${baselineDisp.toStringAsFixed(1)} $unitStr'
                      : l10n.goalWaitingForMeasurementShort,
                  icon: LucideIcons.play,
                ),
                const Divider(height: DesignConstants.spacingL),
                _buildReviewRow(
                  context,
                  label: l10n.goalTargetLabel,
                  value: targetDisp != null
                      ? '${targetDisp.toStringAsFixed(1)} $unitStr'
                      : '--',
                  icon: LucideIcons.flag,
                ),
                const Divider(height: DesignConstants.spacingL),
                _buildReviewRow(
                  context,
                  label: l10n.goalWeeklyRateLabel,
                  value: '${_weeklyRateKg.toStringAsFixed(2)} $unitStr / ${l10n.weekShort}',
                  icon: LucideIcons.gauge,
                ),
                const Divider(height: DesignConstants.spacingL),
                _buildReviewRow(
                  context,
                  label: l10n.goalTargetDateLabel,
                  value: _targetDate != null
                      ? dateFormat.format(_targetDate!)
                      : l10n.goalNoTargetDateShort,
                  icon: LucideIcons.calendar,
                ),
                if (_reasonController.text.trim().isNotEmpty) ...[
                  const Divider(height: DesignConstants.spacingL),
                  _buildReviewRow(
                    context,
                    label: l10n.goalStep6Question,
                    value: _reasonController.text.trim(),
                    icon: LucideIcons.heart,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingL),

        // Nutrition driver toggle
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.goalDriverSettingLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Passt tägliche Kalorien und Makros adaptiv an dieses Ziel an.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          value: _isNutritionDriver,
          onChanged: (val) => setState(() => _isNutritionDriver = val),
        ),
      ],
    );
  }

  Widget _buildReviewRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: DesignConstants.spacingM),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
