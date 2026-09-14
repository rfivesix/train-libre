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
import '../../../widgets/common/app_ruler_picker.dart';
import '../../../widgets/common/app_segmented_control.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/platform_adaptive_dropdown.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/value_summary_card.dart';
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
  bool _showManualTargetWeightInput = false;

  // Step 3: Tempo & Zieldatum (Interaktiver Planer)
  DateTime? _targetDate;
  double _weeklyRateKg = 0.50; // positive magnitude
  String _selectedRatePreset = 'moderate'; // 'gentle', 'moderate', 'athletic', 'aggressive', 'custom'
  String _selectedDurationPreset = 'custom'; // '8', '12', '16', '24', 'custom'

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
    if (text.isEmpty) {
      return _detectedBaselineWeight ??
          unitService.convertToMetric(75.0, UnitDimension.weight);
    }
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return _detectedBaselineWeight ??
          unitService.convertToMetric(75.0, UnitDimension.weight);
    }
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

  void _onTargetDateChanged(DateTime newDate, UnitService unitService,
      {String? durationPreset}) {
    setState(() {
      _targetDate = newDate;
      final delta = _getDeltaKg(unitService);
      if (delta > 0) {
        final days = max(7, newDate.difference(_startDate).inDays);
        final weeks = days / 7.0;
        _weeklyRateKg = (delta / weeks).clamp(0.05, 2.0);
      }
      if (durationPreset != null) {
        _selectedDurationPreset = durationPreset;
      } else {
        _syncDurationPreset();
      }
      _syncRatePreset();
    });
  }

  void _onWeeklyRateChanged(double newRate, UnitService unitService,
      {String? ratePreset}) {
    setState(() {
      _weeklyRateKg = newRate;
      final delta = _getDeltaKg(unitService);
      if (delta > 0 && newRate > 0) {
        final weeks = delta / newRate;
        final days = (weeks * 7).round();
        _targetDate = _startDate.add(Duration(days: max(7, days)));
      }
      if (ratePreset != null) {
        _selectedRatePreset = ratePreset;
      } else {
        _syncRatePreset();
      }
      _syncDurationPreset();
    });
  }

  void _syncRatePreset() {
    if ((_weeklyRateKg - 0.25).abs() < 0.03) {
      _selectedRatePreset = 'gentle';
    } else if ((_weeklyRateKg - 0.50).abs() < 0.03) {
      _selectedRatePreset = 'moderate';
    } else if ((_weeklyRateKg - 0.75).abs() < 0.03) {
      _selectedRatePreset = 'athletic';
    } else if ((_weeklyRateKg - 1.00).abs() < 0.03) {
      _selectedRatePreset = 'aggressive';
    } else {
      _selectedRatePreset = 'custom';
    }
  }

  void _syncDurationPreset() {
    if (_targetDate == null) {
      _selectedDurationPreset = 'custom';
      return;
    }
    final days = _targetDate!.difference(_startDate).inDays;
    final weeks = (days / 7).round();
    if (weeks == 8 && (days - 56).abs() <= 3) {
      _selectedDurationPreset = '8';
    } else if (weeks == 12 && (days - 84).abs() <= 3) {
      _selectedDurationPreset = '12';
    } else if (weeks == 16 && (days - 112).abs() <= 3) {
      _selectedDurationPreset = '16';
    } else if (weeks == 24 && (days - 168).abs() <= 3) {
      _selectedDurationPreset = '24';
    } else {
      _selectedDurationPreset = 'custom';
    }
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
          AppSegmentedControl<String>(
            children: {
              'lose': l10n.goalPresetLoseWeight,
              'gain': l10n.goalPresetGainWeight,
              'maintain': l10n.goalPresetMaintainWeight,
            },
            groupValue: _customDirection,
            onValueChanged: (val) {
              setState(() => _customDirection = val);
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
                  Center(
                    child: Text(
                      '${(double.tryParse(_baselineWeightController.text.replaceAll(',', '.')) ?? 75.0).toStringAsFixed(1)} $unitStr',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  AppRulerPicker.weight(
                    value: double.tryParse(_baselineWeightController.text
                            .replaceAll(',', '.')) ??
                        75.0,
                    imperial: unitService.isImperial,
                    onChanged: (val) {
                      setState(() {
                        _baselineWeightController.text =
                            val.toStringAsFixed(1);
                      });
                    },
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

        SummaryCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM,
              vertical: DesignConstants.spacingL,
            ),
            child: Column(
              children: [
                Text(
                  l10n.goalTargetWeightLabel(unitStr),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      targetDisp?.toStringAsFixed(1) ?? '--',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Text(
                      unitStr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    IconButton(
                      icon: Icon(
                        _showManualTargetWeightInput
                            ? LucideIcons.sliders_horizontal
                            : LucideIcons.pencil,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showManualTargetWeightInput =
                              !_showManualTargetWeightInput;
                        });
                      },
                    ),
                  ],
                ),
                if (_showManualTargetWeightInput) ...[
                  const SizedBox(height: DesignConstants.spacingM),
                  TextField(
                    controller: _targetWeightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            DesignConstants.borderRadiusM),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: DesignConstants.spacingM),
                AppRulerPicker.weight(
                  value: targetDisp ?? (baselineDisp ?? 75.0),
                  imperial: unitService.isImperial,
                  onChanged: (newWeight) {
                    setState(() {
                      _targetWeightController.text =
                          newWeight.toStringAsFixed(1);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),

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
          const SizedBox(height: DesignConstants.spacingM),
        ],

        // 3-Column Summary Cards: Baseline, Planned Delta, Target
        if (baselineDisp != null && targetDisp != null && deltaDisp != null) ...[
          Row(
            children: [
              Expanded(
                child: ValueSummaryCard(
                  label: l10n.goalBaselineHeader,
                  value: '${baselineDisp.toStringAsFixed(1)} $unitStr',
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: ValueSummaryCard(
                  label: l10n.goalWeightDifferenceLabel,
                  value:
                      '${deltaDisp >= 0 ? '+' : ''}${deltaDisp.toStringAsFixed(1)} $unitStr',
                  valueColor: deltaDisp == 0
                      ? theme.colorScheme.primary
                      : (deltaDisp < 0 ? Colors.green : Colors.orange),
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: ValueSummaryCard(
                  label: l10n.goalTargetHeader,
                  value: '${targetDisp.toStringAsFixed(1)} $unitStr',
                  valueColor: theme.colorScheme.primary,
                ),
              ),
            ],
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
          // 1. Live Interactive Trajectory Summary Card (Hero at the Top)
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_targetDate != null)
                        Text(
                          dateFormat.format(_targetDate!),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  const Divider(height: 1),
                  const SizedBox(height: DesignConstants.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.goalEstimatedDailyDelta,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: DesignConstants.spacingS),
                      Text(
                        '${isLosing ? '-' : '+'}$dailyCalorieImpact ${l10n.analyticsKcalPerDay}',
                        style: theme.textTheme.titleSmall?.copyWith(
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
                        size: 18,
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // 2. Control: Pace Selection with Dropdown & Custom Ruler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.goalWeeklyRateLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_weeklyRateKg.toStringAsFixed(2)} $unitStr / ${l10n.weekShort}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          PlatformAdaptiveDropdownFormField<String>(
            key: ValueKey('rate_dropdown_$_selectedRatePreset'),
            value: _selectedRatePreset,
            items: [
              DropdownMenuItem(
                value: 'gentle',
                child: Text(l10n.goalRateGentle),
              ),
              DropdownMenuItem(
                value: 'moderate',
                child: Text(l10n.goalRateModerate),
              ),
              DropdownMenuItem(
                value: 'athletic',
                child: Text(l10n.goalRateAthletic),
              ),
              DropdownMenuItem(
                value: 'aggressive',
                child: Text(l10n.goalRateAggressive),
              ),
              DropdownMenuItem(
                value: 'custom',
                child: Text(l10n.goalRateCustom),
              ),
            ],
            onChanged: (val) {
              if (val == null) return;
              if (val == 'gentle') {
                _onWeeklyRateChanged(0.25, unitService, ratePreset: 'gentle');
              } else if (val == 'moderate') {
                _onWeeklyRateChanged(0.50, unitService, ratePreset: 'moderate');
              } else if (val == 'athletic') {
                _onWeeklyRateChanged(0.75, unitService, ratePreset: 'athletic');
              } else if (val == 'aggressive') {
                _onWeeklyRateChanged(1.00, unitService, ratePreset: 'aggressive');
              } else {
                setState(() => _selectedRatePreset = 'custom');
              }
            },
          ),
          if (_selectedRatePreset == 'custom') ...[
            const SizedBox(height: DesignConstants.spacingM),
            AppRulerPicker.rate(
              value: _weeklyRateKg,
              imperial: unitService.isImperial,
              onChanged: (val) => _onWeeklyRateChanged(val, unitService,
                  ratePreset: 'custom'),
              unit: unitStr,
            ),
          ],
          const SizedBox(height: DesignConstants.spacingL),

          // 3. Control: Target Date & Duration Selection with Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.goalTargetDateLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_targetDate != null)
                Text(
                  dateFormat.format(_targetDate!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          PlatformAdaptiveDropdownFormField<String>(
            key: ValueKey('duration_dropdown_$_selectedDurationPreset'),
            value: _selectedDurationPreset,
            items: [
              DropdownMenuItem(
                value: '8',
                child: Text(l10n.goalEstimatedDuration(8)),
              ),
              DropdownMenuItem(
                value: '12',
                child: Text(l10n.goalEstimatedDuration(12)),
              ),
              DropdownMenuItem(
                value: '16',
                child: Text(l10n.goalEstimatedDuration(16)),
              ),
              DropdownMenuItem(
                value: '24',
                child: Text(l10n.goalEstimatedDuration(24)),
              ),
              DropdownMenuItem(
                value: 'custom',
                child: Text(l10n.goalDurationCustom),
              ),
            ],
            onChanged: (val) {
              if (val == null) return;
              if (val == 'custom') {
                setState(() => _selectedDurationPreset = 'custom');
              } else {
                final w = int.tryParse(val) ?? 12;
                final newDate = _startDate.add(Duration(days: w * 7));
                _onTargetDateChanged(newDate, unitService, durationPreset: val);
              }
            },
          ),
          if (_selectedDurationPreset == 'custom') ...[
            const SizedBox(height: DesignConstants.spacingM),
            SummaryCard(
              child: ListTile(
                leading: Icon(LucideIcons.calendar,
                    color: theme.colorScheme.primary),
                title: Text(
                  _targetDate != null
                      ? dateFormat.format(_targetDate!)
                      : l10n.goalNoDeadlineOption,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(l10n.goalTargetDateLabel),
                trailing: const Icon(LucideIcons.chevron_right, size: 18),
                onTap: () async {
                  final picked = await showAdaptiveDatePicker(
                    context: context,
                    initialDate: _targetDate ??
                        _startDate.add(const Duration(days: 84)),
                    firstDate: _startDate.add(const Duration(days: 7)),
                    lastDate: _startDate.add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    _onTargetDateChanged(picked, unitService,
                        durationPreset: 'custom');
                  }
                },
              ),
            ),
          ],
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

        // Quick suggestion catalog without emojis (compact, multiple per line)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            l10n.goalReasonSuggestionHealth,
            l10n.goalReasonSuggestionFitness,
            l10n.goalReasonSuggestionShape,
            l10n.goalReasonSuggestionEnergy,
            l10n.goalReasonSuggestionStrength,
            l10n.goalReasonSuggestionConfidence,
            l10n.goalReasonSuggestionEvent,
            l10n.goalReasonSuggestionLongevity,
            l10n.goalReasonSuggestionHabits,
            l10n.goalReasonSuggestionClothing,
          ].map((suggestion) {
            final isSelected = _reasonController.text.trim() == suggestion;
            return ActionChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              label: Text(
                suggestion,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              side: isSelected
                  ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                  : BorderSide(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.15),
                    ),
              backgroundColor: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : null,
              onPressed: () {
                setState(() {
                  _reasonController.text = suggestion;
                });
              },
            );
          }).toList(),
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
