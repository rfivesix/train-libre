// lib/features/profile/presentation/widgets/active_goal_dashboard_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_button.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../../../widgets/common/glass_progress_bar.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/models/goal_model.dart';
import '../../domain/models/goal_progress.dart';
import '../../../analytics/domain/models/chart_data_point.dart';
import '../add_measurement_screen.dart';
import '../create_goal_flow.dart';
import 'measurement_chart_widget.dart';

/// A dashboard widget presenting an active nutrition goal's full status,
/// 3-stat summary cards, animated glass progress bar, and full-span trajectory chart.
///
/// Used both directly in [NutritionHubScreen] (without action buttons) and in
/// [GoalDetailScreen] (with action buttons).
class ActiveGoalDashboardWidget extends StatelessWidget {
  final Goal? goal;
  final GoalProgress? progress;
  final List<ChartDataPoint> chartPoints;
  final VoidCallback? onRefresh;
  final VoidCallback? onHeaderTap;
  final bool bleedChartToEdges;
  final Widget? bottomActions;

  const ActiveGoalDashboardWidget({
    super.key,
    required this.goal,
    required this.progress,
    required this.chartPoints,
    this.onRefresh,
    this.onHeaderTap,
    this.bleedChartToEdges = false,
    this.bottomActions,
  });

  String _presetLabel(BuildContext context, GoalPreset preset) {
    final l10n = AppLocalizations.of(context)!;
    switch (preset) {
      case GoalPreset.loseWeight:
        return l10n.goalPresetLoseWeight;
      case GoalPreset.gainWeight:
        return l10n.goalPresetGainWeight;
      case GoalPreset.maintainWeight:
        return l10n.goalPresetMaintainWeight;
      case GoalPreset.recomposition:
        return l10n.goalPresetRecomposition;
      case GoalPreset.custom:
        return l10n.goalPresetCustom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();

    String formatWeight(double? val) {
      if (val == null) return '--';
      final disp = unitService.convertDisplayValue(val, UnitDimension.weight);
      final unit = unitService.unitString(UnitDimension.weight);
      return '${disp.toStringAsFixed(1)} $unit';
    }

    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    // Empty state when no goal exists
    final activeGoal = goal;
    if (activeGoal == null) {
      return SummaryCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.target,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingM),
              Text(
                l10n.noActiveGoalTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingXS),
              Text(
                l10n.noActiveGoalDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingL),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  label: l10n.createGoalTitle,
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const CreateGoalFlow(),
                      ),
                    );
                    if (result == true) onRefresh?.call();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isWaiting = progress?.state == GoalProgressState.waitingForBaseline;
    final isActive = activeGoal.status == GoalStatus.active;
    final isRetired = activeGoal.status == GoalStatus.retired;
    final statusMessage = switch (progress?.state) {
      GoalProgressState.targetMet => l10n.goalJourneyTargetReached,
      GoalProgressState.maintenanceStable => l10n.goalMaintenanceStable,
      GoalProgressState.maintenanceDrifting => l10n.goalMaintenanceDrifting,
      GoalProgressState.waitingForBaseline =>
        l10n.goalWaitingForBaselineCalloutTitle,
      _ => l10n.goalJourneyInProgress,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SummaryCard(
          margin: EdgeInsets.zero,
          onTap: onHeaderTap,
          child: Padding(
            padding: DesignConstants.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activeGoal.title.isNotEmpty
                            ? activeGoal.title
                            : _presetLabel(context, activeGoal.preset),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _GoalStatusPill(
                      label: isActive
                          ? l10n.goalStatusActive
                          : (isRetired
                              ? l10n.goalStatusRetired
                              : l10n.goalStatusSuperseded),
                      active: isActive,
                    ),
                    if (onHeaderTap != null) ...[
                      const SizedBox(width: DesignConstants.spacingXS),
                      Icon(
                        LucideIcons.chevron_right,
                        size: 18,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingM),
                Text(
                  statusMessage,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _JourneyValue(
                        label: l10n.goalCurrentHeader,
                        value: formatWeight(progress?.currentValue),
                        emphasized: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: DesignConstants.spacingS,
                        right: DesignConstants.spacingS,
                        bottom: 8,
                      ),
                      child: Icon(
                        LucideIcons.arrow_right,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                    Expanded(
                      child: _JourneyValue(
                        label: l10n.goalTargetHeader,
                        value: activeGoal.targetValue == null
                            ? (activeGoal.isMaintenanceOrRecomp
                                ? l10n.goalMaintainCorridor
                                : l10n.goalDirectionalOnly)
                            : formatWeight(activeGoal.targetValue),
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                if (progress != null && !isWaiting) ...[
                  const SizedBox(height: DesignConstants.spacingL),
                  GlassProgressBar(
                    label: l10n.goalProgressSectionTitle,
                    unit: unitService.unitString(UnitDimension.weight),
                    value: ((progress!.progressPercentage ??
                                (progress!.isInToleranceBand ? 1.0 : 0.0)) *
                            100)
                        .clamp(0.0, 100.0),
                    target: 100,
                    color: Colors.green,
                    borderRadius: DesignConstants.borderRadiusL,
                    customSubtitle: progress!.remainingDistance != null
                        ? l10n.goalRemainingDistanceLabel(
                            formatWeight(progress!.remainingDistance),
                          )
                        : statusMessage,
                  ),
                ],
                const Divider(height: DesignConstants.spacingXL),
                Wrap(
                  spacing: DesignConstants.spacingL,
                  runSpacing: DesignConstants.spacingS,
                  children: [
                    _JourneyMeta(
                      label: l10n.goalBaselineHeader,
                      value: formatWeight(progress?.baselineValue),
                    ),
                    _JourneyMeta(
                      label: l10n.goalTargetDateLabel,
                      value: activeGoal.targetDate == null
                          ? l10n.goalNoTargetDateShort
                          : dateFormat.format(activeGoal.targetDate!),
                    ),
                    if (progress?.trendRateKgPerWeek != null)
                      _JourneyMeta(
                        label: l10n.goalWeeklyRateLabel,
                        value:
                            '${progress!.trendRateKgPerWeek! >= 0 ? "+" : ""}${unitService.convertDisplayValue(progress!.trendRateKgPerWeek!, UnitDimension.weight).toStringAsFixed(2)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}',
                      ),
                  ],
                ),
                if (activeGoal.reason?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: DesignConstants.spacingM),
                  Text(
                    '“${activeGoal.reason!.trim()}”',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        // The first missing measurement is the only action shown in this state.
        if (isWaiting) ...[
          Container(
            padding: const EdgeInsets.all(DesignConstants.spacingM),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                DesignConstants.borderRadiusM,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goalWaitingForBaselineCalloutDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingM),
                AppButton.primary(
                  label: l10n.recordFirstMeasurementButton,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddMeasurementScreen(),
                      ),
                    );
                    onRefresh?.call();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
        ],

        // Visual Chart View
        if (chartPoints.isNotEmpty) ...[
          AppSectionHeader(
            title: l10n.goalWeightHistoryChartTitle,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Builder(
            builder: (context) {
              final startWeight = progress?.baselineValue ??
                  (chartPoints.isNotEmpty ? chartPoints.first.value : 75.0);
              final targetDate = activeGoal.targetDate ??
                  activeGoal.startDate.add(const Duration(days: 84));
              final domainEnd = targetDate.isAfter(DateTime.now())
                  ? targetDate
                  : DateTime.now().add(const Duration(days: 7));
              final targetWeight = activeGoal.targetValue ?? startWeight;

              final chart = SizedBox(
                height: 250,
                child: MeasurementChartWidget.fromData(
                  dataPoints: chartPoints,
                  axisMode: MeasurementChartAxisMode.day,
                  domainDateRange: DateTimeRange(
                    start: activeGoal.startDate,
                    end: domainEnd,
                  ),
                  trajectoryStart: ChartDataPoint(
                    date: activeGoal.startDate,
                    value: startWeight,
                  ),
                  trajectoryEnd: ChartDataPoint(
                    date: targetDate,
                    value: targetWeight,
                  ),
                  unit: unitService.unitString(UnitDimension.weight),
                  emptyStateLabel: l10n.emptyStateMeasurements,
                  edgeToEdge: true,
                ),
              );

              if (bleedChartToEdges) {
                return SizedBox(
                  height: 250,
                  child: OverflowBox(
                    maxWidth: MediaQuery.of(context).size.width,
                    minWidth: MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    child: chart,
                  ),
                );
              }

              return chart;
            },
          ),
          const SizedBox(height: DesignConstants.spacingL),
        ],

        if (bottomActions != null) ...[
          bottomActions!,
        ],
      ],
    );
  }
}

class _GoalStatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _GoalStatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? Colors.green : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color.withValues(alpha: active ? 1 : 0.7),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JourneyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  final bool alignEnd;

  const _JourneyValue({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXS),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: emphasized ? theme.colorScheme.primary : null,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyMeta extends StatelessWidget {
  final String label;
  final String value;

  const _JourneyMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
