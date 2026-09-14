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
import '../../../../widgets/common/value_summary_card.dart';
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
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreateGoalFlow(),
            ),
          );
          if (result == true) {
            onRefresh?.call();
          }
        },
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Row(
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
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.noActiveGoalTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.noActiveGoalDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      );
    }

    final isWaiting = progress?.state == GoalProgressState.waitingForBaseline;
    final isActive = activeGoal.status == GoalStatus.active;
    final isRetired = activeGoal.status == GoalStatus.retired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header card with goal title, status, metadata, and motivation
        SummaryCard(
          margin: EdgeInsets.zero,
          onTap: onHeaderTap,
          child: Padding(
            padding: DesignConstants.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        activeGoal.title.isNotEmpty
                            ? activeGoal.title
                            : _presetLabel(context, activeGoal.preset),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withValues(alpha: 0.15)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          DesignConstants.borderRadiusS,
                        ),
                      ),
                      child: Text(
                        isActive
                            ? l10n.goalStatusActive
                            : (isRetired
                                ? l10n.goalStatusRetired
                                : l10n.goalStatusSuperseded),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? Colors.green
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                const SizedBox(height: DesignConstants.spacingXS),
                Text(
                  '${l10n.goalStartedOnLabel(dateFormat.format(activeGoal.startDate))} • ${activeGoal.isNutritionDriver ? l10n.goalDrivesNutritionBadge : l10n.goalDocumentationOnlyBadge}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (activeGoal.reason != null &&
                    activeGoal.reason!.trim().isNotEmpty) ...[
                  const SizedBox(height: DesignConstants.spacingS),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.quote,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: DesignConstants.spacingS),
                      Expanded(
                        child: Text(
                          activeGoal.reason!.trim(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),

        // Drei-Säulen-Übersicht: Start, Aktuell, Ziel (ValueSummaryCards)
        Row(
          children: [
            // Start / Baseline
            Expanded(
              child: ValueSummaryCard(
                label: l10n.goalBaselineHeader,
                value: isWaiting ? '--' : formatWeight(progress?.baselineValue),
                subtitle: progress?.baselineDate != null
                    ? dateFormat.format(progress!.baselineDate!)
                    : l10n.goalWaitingForBaselineLabel,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingS),

            // Aktuell
            Expanded(
              child: ValueSummaryCard(
                label: l10n.goalCurrentHeader,
                value: formatWeight(progress?.currentValue),
                subtitle: progress?.deltaSinceStart != null
                    ? '${progress!.deltaSinceStart! >= 0 ? "+" : ""}${unitService.convertDisplayValue(progress!.deltaSinceStart!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}'
                    : null,
                valueColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingS),

            // Ziel
            Expanded(
              child: ValueSummaryCard(
                label: l10n.goalTargetHeader,
                value: activeGoal.targetValue != null
                    ? formatWeight(activeGoal.targetValue)
                    : (activeGoal.isMaintenanceOrRecomp
                        ? l10n.goalMaintainCorridor
                        : l10n.goalDirectionalOnly),
                subtitle: activeGoal.targetDate != null
                    ? dateFormat.format(activeGoal.targetDate!)
                    : l10n.goalNoTargetDateShort,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingS),

        // Waiting for baseline callout if needed
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
                Row(
                  children: [
                    Icon(
                      LucideIcons.scale,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Expanded(
                      child: Text(
                        l10n.goalWaitingForBaselineCalloutTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingS),
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

        // GlassProgressBar & Weekly Rate
        if (progress != null && !isWaiting) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassProgressBar(
                label: l10n.goalProgressSectionTitle,
                unit: unitService.unitString(UnitDimension.weight),
                value: ((progress!.progressPercentage ?? 0.0) * 100)
                    .clamp(0.0, 100.0),
                target: 100.0,
                color: Colors.green,
                borderRadius: DesignConstants.borderRadiusL,
                customSubtitle: progress!.remainingDistance != null &&
                        activeGoal.hasNumericTarget
                    ? l10n.goalRemainingDistanceLabel(
                        '${unitService.convertDisplayValue(progress!.remainingDistance!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}',
                      )
                    : (activeGoal.isMaintenanceOrRecomp
                        ? (progress!.isInToleranceBand == true
                            ? l10n.goalMaintenanceStable
                            : l10n.goalMaintenanceDrifting)
                        : '${((progress!.progressPercentage ?? 0.0) * 100).toStringAsFixed(0)}%'),
              ),
              if (progress!.trendRateKgPerWeek != null ||
                  progress!.progressPercentage != null) ...[
                const SizedBox(height: DesignConstants.spacingXS),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (progress!.progressPercentage != null)
                        Text(
                          '${(progress!.progressPercentage! * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (progress!.trendRateKgPerWeek != null)
                        Text(
                          '${progress!.trendRateKgPerWeek! >= 0 ? "+" : ""}${unitService.convertDisplayValue(progress!.trendRateKgPerWeek!, UnitDimension.weight).toStringAsFixed(2)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
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
