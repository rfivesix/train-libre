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
import '../../domain/services/goal_notification_orchestrator.dart';
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
  final DateTime? recommendedTargetDate;
  final double? recommendedWeeklyRateKg;
  final bool embedded;
  final bool showSaveButton;

  const GoalAdjustmentSheet({
    super.key,
    required this.goal,
    required this.startWeightKg,
    required this.repository,
    this.onSaved,
    this.recommendedTargetDate,
    this.recommendedWeeklyRateKg,
    this.embedded = false,
    this.showSaveButton = true,
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
  State<GoalAdjustmentSheet> createState() => GoalAdjustmentSheetState();
}

class GoalAdjustmentSheetState extends State<GoalAdjustmentSheet> {
  late double _targetWeightKg;
  late DateTime _targetDate;
  late double _weeklyRateKg;
  late DateTime _adjustmentDate;
  late GoalTrackingMode _trackingMode;
  late bool _hasTargetDate;
  AdjustmentFixOption _fixOption = AdjustmentFixOption.keepDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _adjustmentDate = DateTime(now.year, now.month, now.day);
    _trackingMode = widget.goal.preset == GoalPreset.recomposition
        ? GoalTrackingMode.open
        : widget.goal.preset == GoalPreset.maintainWeight &&
                widget.goal.trackingMode == GoalTrackingMode.weeklyRate
            ? GoalTrackingMode.open
            : widget.goal.trackingMode;
    _hasTargetDate = widget.goal.targetDate != null;
    _targetWeightKg = widget.goal.targetValue ?? widget.startWeightKg;
    _targetDate =
        widget.goal.targetDate ?? DateTime.now().add(const Duration(days: 90));
    _weeklyRateKg = widget.goal.desiredWeeklyRateKg ??
        (widget.goal.targetValue != null
            ? GoalTrajectoryCalculator.calculateWeeklyRate(
                startWeight: widget.startWeightKg,
                targetWeight: _targetWeightKg,
                startDate: _adjustmentDate,
                targetDate: _targetDate,
              )
            : switch (widget.goal.preset) {
                GoalPreset.loseWeight => -0.50,
                GoalPreset.gainWeight => 0.25,
                _ => 0.0,
              });
  }

  void _onWeightChanged(double newWeight) {
    setState(() {
      _targetWeightKg = newWeight;
      if (_fixOption == AdjustmentFixOption.keepDate) {
        final res = GoalTrajectoryCalculator.onWeightChangedKeepDate(
          startWeight: widget.startWeightKg,
          newTargetWeight: _targetWeightKg,
          startDate: _adjustmentDate,
          fixedTargetDate: _targetDate,
        );
        _weeklyRateKg = res.weeklyRateKg;
      } else {
        final res = GoalTrajectoryCalculator.onWeightChangedKeepRate(
          startWeight: widget.startWeightKg,
          newTargetWeight: _targetWeightKg,
          startDate: _adjustmentDate,
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
        startDate: _adjustmentDate,
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
          startDate: _adjustmentDate,
          fixedTargetDate: _targetDate,
          newWeeklyRate: _weeklyRateKg,
        );
        _targetWeightKg = res.targetWeight;
      } else {
        final res = GoalTrajectoryCalculator.onRateChangedKeepWeight(
          startWeight: widget.startWeightKg,
          fixedTargetWeight: _targetWeightKg,
          startDate: _adjustmentDate,
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

  Future<void> confirmAndSave() => _confirmAndSave();

  Future<void> acceptRecommendedAndSave() async {
    final recommendedDate = widget.recommendedTargetDate;
    final recommendedRate = widget.recommendedWeeklyRateKg;
    if (recommendedDate != null && recommendedRate != null) {
      setState(() {
        _fixOption = recommendationKeepsDateForSave
            ? AdjustmentFixOption.keepDate
            : AdjustmentFixOption.keepRate;
        _weeklyRateKg = recommendedRate;
        _targetDate = recommendedDate;
      });
    }
    await _confirmAndSave();
  }

  bool get recommendationKeepsDateForSave =>
      widget.goal.targetDate != null &&
      widget.recommendedTargetDate != null &&
      DateUtils.isSameDay(widget.goal.targetDate, widget.recommendedTargetDate);

  Future<void> _saveAdjustment() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      await widget.repository.reviseGoal(
        currentGoal: widget.goal,
        trackingMode: _trackingMode,
        targetValue: _trackingMode == GoalTrackingMode.targetWeight
            ? _targetWeightKg
            : null,
        targetDate:
            _trackingMode == GoalTrackingMode.targetWeight && _hasTargetDate
                ? _targetDate
                : null,
        desiredWeeklyRateKg:
            _trackingMode == GoalTrackingMode.weeklyRate ? _weeklyRateKg : null,
        anchorValue: widget.startWeightKg,
        reason: 'Goal planning mode or trajectory adjusted',
      );
      final notifications =
          GoalNotificationOrchestrator(goalRepository: widget.repository);
      await notifications.synchronize();
      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        if (!widget.embedded) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.goalAdjustError(e.toString()))),
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
    final recommendedDisplayRate = widget.recommendedWeeklyRateKg == null
        ? null
        : unitService.convertDisplayValue(
            widget.recommendedWeeklyRateKg!,
            UnitDimension.weight,
          );
    final unitStr = unitService.unitString(UnitDimension.weight);

    final isSafe = GoalTrajectoryCalculator.isRateSafe(_weeklyRateKg);
    final recommendationKeepsDate = widget.goal.targetDate != null &&
        widget.recommendedTargetDate != null &&
        DateUtils.isSameDay(
          widget.goal.targetDate,
          widget.recommendedTargetDate,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded) ...[
            Text(
              l10n.adjustGoalDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
          ],

          AppSegmentedControl<GoalTrackingMode>(
            children: {
              GoalTrackingMode.open: l10n.goalTrackingModeOpen,
              if (widget.goal.preset != GoalPreset.recomposition &&
                  widget.goal.preset != GoalPreset.maintainWeight)
                GoalTrackingMode.weeklyRate: l10n.goalTrackingModeWeeklyRate,
              if (widget.goal.preset != GoalPreset.recomposition)
                GoalTrackingMode.targetWeight:
                    l10n.goalTrackingModeTargetWeight,
            },
            groupValue: _trackingMode,
            onValueChanged: (mode) => setState(() => _trackingMode = mode),
          ),
          const SizedBox(height: DesignConstants.spacingL),

          if (_trackingMode == GoalTrackingMode.open) ...[
            Text(
              l10n.goalTrackingOpenReady,
              style: theme.textTheme.bodyMedium,
            ),
          ],

          if (_trackingMode == GoalTrackingMode.targetWeight &&
              widget.recommendedTargetDate != null &&
              widget.recommendedWeeklyRateKg != null) ...[
            Container(
              padding: const EdgeInsets.all(DesignConstants.spacingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusM),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adjustGoalRecommendedTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingXS),
                  Text(
                    recommendationKeepsDate
                        ? l10n.adjustGoalRecommendedKeepDatePlan(
                            dateFormat.format(widget.recommendedTargetDate!),
                            '${recommendedDisplayRate! >= 0 ? '+' : ''}${recommendedDisplayRate.toStringAsFixed(2)} $unitStr/${l10n.weekShort}',
                          )
                        : l10n.adjustGoalRecommendedPlan(
                            dateFormat.format(widget.recommendedTargetDate!),
                            '${recommendedDisplayRate! >= 0 ? '+' : ''}${recommendedDisplayRate.toStringAsFixed(2)} $unitStr/${l10n.weekShort}',
                          ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  AppButton.secondary(
                    label: l10n.adjustGoalSelectRecommendedPlan,
                    onPressed: () {
                      setState(() {
                        _fixOption = recommendationKeepsDate
                            ? AdjustmentFixOption.keepDate
                            : AdjustmentFixOption.keepRate;
                        _weeklyRateKg = widget.recommendedWeeklyRateKg!;
                        _targetDate = widget.recommendedTargetDate!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingL),
          ],

          // Strategy Selector: Fixed Date vs Fixed Rate (Clean Apple HIG segment control, no emojis)
          if (_trackingMode == GoalTrackingMode.targetWeight && _hasTargetDate)
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
          if (_trackingMode == GoalTrackingMode.targetWeight && _hasTargetDate)
            const SizedBox(height: DesignConstants.spacingL),

          // Target Weight Row (No emojis/icons, opens glass number input)
          if (_trackingMode == GoalTrackingMode.targetWeight)
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
          if (_trackingMode == GoalTrackingMode.targetWeight)
            const Divider(height: 1),

          // Target Date Row (No emojis/icons, opens glass date picker)
          if (_trackingMode == GoalTrackingMode.targetWeight)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adjustGoalTargetDateLabel),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _hasTargetDate
                        ? dateFormat.format(_targetDate)
                        : l10n.goalNoDeadlineOption,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (_hasTargetDate)
                    IconButton(
                      tooltip: l10n.delete,
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => setState(() => _hasTargetDate = false),
                    )
                  else
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
                if (picked != null) {
                  _hasTargetDate = true;
                  _onDateChanged(picked);
                }
              },
            ),
          if (_trackingMode == GoalTrackingMode.targetWeight)
            const Divider(height: 1),

          // Weekly Rate Row (No emojis/icons, opens glass rate ruler input)
          if (_trackingMode == GoalTrackingMode.weeklyRate)
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
                  final signedRate =
                      isNegative ? -newDisplayRate : newDisplayRate;
                  final metric = unitService.convertToMetric(
                    signedRate,
                    UnitDimension.weight,
                  );
                  _onRateChanged(metric);
                }
              },
            ),
          if (_trackingMode == GoalTrackingMode.weeklyRate)
            const Divider(height: 1),

          if (_trackingMode == GoalTrackingMode.weeklyRate && !isSafe) ...[
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

          if (widget.showSaveButton) ...[
            const SizedBox(height: DesignConstants.spacingXL),
            AppButton.primary(
              label: _isSaving ? '...' : l10n.adjustGoalUpdatePlanButton,
              tooltip: l10n.adjustGoalUpdatePlanButton,
              onPressed: _isSaving ? null : _confirmAndSave,
            ),
          ],
        ],
      ),
    );
  }
}
