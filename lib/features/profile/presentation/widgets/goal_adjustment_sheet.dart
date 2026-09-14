// lib/features/profile/presentation/widgets/goal_adjustment_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/app_segmented_control.dart';
import '../../../../widgets/common/platform_adaptive_pickers.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../domain/models/goal_model.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/services/goal_trajectory_calculator.dart';

enum AdjustmentFixOption {
  keepDate,
  keepRate,
}

class GoalAdjustmentSheet extends StatefulWidget {
  final Goal goal;
  final double startWeightKg;
  final IGoalRepository repository;
  final VoidCallback? onSaved;

  const GoalAdjustmentSheet({
    super.key,
    required this.goal,
    required this.startWeightKg,
    required this.repository,
    this.onSaved,
  });

  /// Shows the Goal Adjustment sheet within the app's standard liquid glass bottom menu.
  static Future<bool?> show(
    BuildContext context, {
    required Goal goal,
    required double startWeightKg,
    required IGoalRepository repository,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showGlassBottomMenu<bool>(
      context: context,
      title: l10n.adjustGoalTitle,
      contentBuilder: (ctx, close) => SingleChildScrollView(
        child: GoalAdjustmentSheet(
          goal: goal,
          startWeightKg: startWeightKg,
          repository: repository,
          onSaved: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );
  }

  @override
  State<GoalAdjustmentSheet> createState() => _GoalAdjustmentSheetState();
}

class _GoalAdjustmentSheetState extends State<GoalAdjustmentSheet> {
  late double _targetWeightKg;
  late DateTime _targetDate;
  late double _weeklyRateKg;
  AdjustmentFixOption _fixOption = AdjustmentFixOption.keepDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _targetWeightKg = widget.goal.targetValue ?? widget.startWeightKg;
    _targetDate = widget.goal.targetDate ??
        DateTime.now().add(const Duration(days: 90));
    _weeklyRateKg = widget.goal.desiredWeeklyRateKg ??
        GoalTrajectoryCalculator.calculateWeeklyRate(
          startWeight: widget.startWeightKg,
          targetWeight: _targetWeightKg,
          startDate: widget.goal.startDate,
          targetDate: _targetDate,
        );
  }

  void _onWeightChanged(double newWeight) {
    setState(() {
      _targetWeightKg = newWeight;
      if (_fixOption == AdjustmentFixOption.keepDate) {
        final res = GoalTrajectoryCalculator.onWeightChangedKeepDate(
          startWeight: widget.startWeightKg,
          newTargetWeight: _targetWeightKg,
          startDate: widget.goal.startDate,
          fixedTargetDate: _targetDate,
        );
        _weeklyRateKg = res.weeklyRateKg;
      } else {
        final res = GoalTrajectoryCalculator.onWeightChangedKeepRate(
          startWeight: widget.startWeightKg,
          newTargetWeight: _targetWeightKg,
          startDate: widget.goal.startDate,
          fixedWeeklyRate: _weeklyRateKg,
        );
        _targetDate = res.targetDate;
      }
    });
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _targetDate = newDate;
      final res = GoalTrajectoryCalculator.onDateChangedKeepWeight(
        startWeight: widget.startWeightKg,
        fixedTargetWeight: _targetWeightKg,
        startDate: widget.goal.startDate,
        newTargetDate: _targetDate,
      );
      _weeklyRateKg = res.weeklyRateKg;
    });
  }

  void _onRateChanged(double newRate) {
    setState(() {
      _weeklyRateKg = newRate;
      if (_fixOption == AdjustmentFixOption.keepDate) {
        final res = GoalTrajectoryCalculator.onRateChangedKeepDate(
          startWeight: widget.startWeightKg,
          startDate: widget.goal.startDate,
          fixedTargetDate: _targetDate,
          newWeeklyRate: _weeklyRateKg,
        );
        _targetWeightKg = res.targetWeight;
      } else {
        final res = GoalTrajectoryCalculator.onRateChangedKeepWeight(
          startWeight: widget.startWeightKg,
          fixedTargetWeight: _targetWeightKg,
          startDate: widget.goal.startDate,
          newWeeklyRate: _weeklyRateKg,
        );
        _targetDate = res.targetDate;
      }
    });
  }

  Future<void> _confirmAndSave() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGlassConfirmation(
      context: context,
      title: l10n.adjustGoalConfirmTitle,
      content: l10n.adjustGoalConfirmContent,
      confirmLabel: l10n.adjustGoalConfirmButton,
    );
    if (confirmed == true) {
      await _saveAdjustment();
    }
  }

  Future<void> _saveAdjustment() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await widget.repository.supersedeGoal(
        currentGoal: widget.goal,
        targetValue: _targetWeightKg,
        targetDate: _targetDate,
        desiredWeeklyRateKg: _weeklyRateKg,
        reason: 'Trajektorie angepasst',
      );
      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Anpassen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unitService = context.watch<UnitService>();

    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    final displayWeight = unitService.convertDisplayValue(
      _targetWeightKg,
      UnitDimension.weight,
    );
    final displayRate = unitService.convertDisplayValue(
      _weeklyRateKg,
      UnitDimension.weight,
    );
    final unitStr = unitService.unitString(UnitDimension.weight);

    final isSafe = GoalTrajectoryCalculator.isRateSafe(_weeklyRateKg);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.adjustGoalDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Strategy Selector: Fixed Date vs Fixed Rate (Clean Apple HIG segment control, no emojis)
          AppSegmentedControl<AdjustmentFixOption>(
            children: {
              AdjustmentFixOption.keepDate: l10n.adjustGoalFixOptionKeepDate,
              AdjustmentFixOption.keepRate: l10n.adjustGoalFixOptionKeepRate,
            },
            groupValue: _fixOption,
            onValueChanged: (val) {
              setState(() => _fixOption = val);
            },
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Target Weight Row (No emojis/icons, opens glass number input)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adjustGoalTargetWeightLabel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${displayWeight.toStringAsFixed(1)} $unitStr',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            onTap: () async {
              final newDisplayWeight = await showGlassWeightRulerInput(
                context: context,
                title: l10n.adjustGoalTargetWeightLabel,
                initialValue: displayWeight,
                imperial: unitService.isImperial,
                unit: unitStr,
              );
              if (newDisplayWeight != null && newDisplayWeight > 0) {
                final metric = unitService.convertToMetric(
                  newDisplayWeight,
                  UnitDimension.weight,
                );
                _onWeightChanged(metric);
              }
            },
          ),
          const Divider(height: 1),

          // Target Date Row (No emojis/icons, opens glass date picker)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adjustGoalTargetDateLabel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateFormat.format(_targetDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            onTap: () async {
              final picked = await showAdaptiveDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (picked != null) _onDateChanged(picked);
            },
          ),
          const Divider(height: 1),

          // Weekly Rate Row (No emojis/icons, opens glass rate ruler input)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adjustGoalWeeklyRateLabel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${displayRate >= 0 ? '+' : ''}${displayRate.toStringAsFixed(2)} $unitStr/${l10n.weekShort}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSafe ? null : Colors.orange,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            onTap: () async {
              final isNegative = displayRate < 0;
              final newDisplayRate = await showGlassRateRulerInput(
                context: context,
                title: l10n.adjustGoalWeeklyRateLabel,
                initialValue: displayRate.abs(),
                imperial: unitService.isImperial,
                unit: '$unitStr/${l10n.weekShort}',
                allowNegative: false,
              );
              if (newDisplayRate != null) {
                final signedRate = isNegative ? -newDisplayRate : newDisplayRate;
                final metric = unitService.convertToMetric(
                  signedRate,
                  UnitDimension.weight,
                );
                _onRateChanged(metric);
              }
            },
          ),
          const Divider(height: 1),

          if (!isSafe) ...[
            const SizedBox(height: DesignConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusS),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.triangle_alert,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                    child: Text(
                      l10n.adjustGoalExtremeRateWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: DesignConstants.spacingXL),
          AppButton.primary(
            label: _isSaving
                ? '...'
                : l10n.adjustGoalApplyAsSuccessorButton,
            tooltip: l10n.adjustGoalApplyAsSuccessorButton,
            onPressed: _isSaving ? null : _confirmAndSave,
          ),
        ],
      ),
    );
  }
}
