// lib/features/profile/presentation/widgets/goal_adjustment_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/platform_adaptive_pickers.dart';
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

  const GoalAdjustmentSheet({
    super.key,
    required this.goal,
    required this.startWeightKg,
    required this.repository,
  });

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
      Navigator.of(context).pop(true);
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

    return Container(
      padding: EdgeInsets.only(
        top: DesignConstants.spacingL,
        left: DesignConstants.spacingL,
        right: DesignConstants.spacingL,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            DesignConstants.spacingL +
            16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignConstants.borderRadiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.adjustGoalTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            l10n.adjustGoalDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Strategy Selector: Keep Date vs Keep Rate
          Text(
            l10n.adjustGoalTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<AdjustmentFixOption>(
            segments: [
              ButtonSegment(
                value: AdjustmentFixOption.keepDate,
                label: Text(l10n.adjustGoalFixOptionKeepDate),
                icon: const Icon(LucideIcons.calendar),
              ),
              ButtonSegment(
                value: AdjustmentFixOption.keepRate,
                label: Text(l10n.adjustGoalFixOptionKeepRate),
                icon: const Icon(LucideIcons.gauge),
              ),
            ],
            selected: {_fixOption},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) setState(() => _fixOption = set.first);
            },
          ),
          const SizedBox(height: DesignConstants.spacingL),

          // Target Weight Row
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(LucideIcons.scale, color: theme.colorScheme.primary),
            title: Text(l10n.adjustGoalTargetWeightLabel),
            trailing: Text(
              '${displayWeight.toStringAsFixed(1)} $unitStr',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              final newWeight = await showDialog<double>(
                context: context,
                builder: (ctx) {
                  final ctrl = TextEditingController(
                    text: displayWeight.toStringAsFixed(1),
                  );
                  return AlertDialog(
                    title: Text(l10n.adjustGoalTargetWeightLabel),
                    content: TextField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          final val = double.tryParse(ctrl.text.trim());
                          if (val != null) {
                            final metric = unitService.convertToMetric(
                              val,
                              UnitDimension.weight,
                            );
                            Navigator.of(ctx).pop(metric);
                          }
                        },
                        child: Text(l10n.save),
                      ),
                    ],
                  );
                },
              );
              if (newWeight != null) _onWeightChanged(newWeight);
            },
          ),
          const Divider(height: 1),

          // Target Date Row
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                Icon(LucideIcons.calendar, color: theme.colorScheme.primary),
            title: Text(l10n.goalTargetDateLabel),
            trailing: Text(
              dateFormat.format(_targetDate),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

          // Weekly Rate Row
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(LucideIcons.gauge, color: theme.colorScheme.primary),
            title: Text(l10n.goalWeeklyRateLabel),
            trailing: Text(
              '${displayRate >= 0 ? '+' : ''}${displayRate.toStringAsFixed(2)} $unitStr/${l10n.weekShort}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSafe ? null : Colors.orange,
              ),
            ),
            onTap: () async {
              final newRate = await showDialog<double>(
                context: context,
                builder: (ctx) {
                  final ctrl = TextEditingController(
                    text: displayRate.toStringAsFixed(2),
                  );
                  return AlertDialog(
                    title: Text(l10n.goalWeeklyRateLabel),
                    content: TextField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          final val = double.tryParse(ctrl.text.trim());
                          if (val != null) {
                            final metric = unitService.convertToMetric(
                              val,
                              UnitDimension.weight,
                            );
                            Navigator.of(ctx).pop(metric);
                          }
                        },
                        child: Text(l10n.save),
                      ),
                    ],
                  );
                },
              );
              if (newRate != null) _onRateChanged(newRate);
            },
          ),
          const Divider(height: 1),
          const SizedBox(height: DesignConstants.spacingM),

          if (!isSafe)
            Container(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusS),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.triangle_alert, color: Colors.orange, size: 20),
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

          const SizedBox(height: DesignConstants.spacingXL),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: _isSaving
                  ? '...'
                  : l10n.adjustGoalApplyAsSuccessorButton,
              tooltip: l10n.adjustGoalApplyAsSuccessorButton,
              onPressed: _isSaving ? null : _saveAdjustment,
            ),
          ),
        ],
      ),
    );
  }
}
