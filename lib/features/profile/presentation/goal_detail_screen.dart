// lib/features/profile/presentation/goal_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../domain/models/goal_model.dart';
import '../domain/models/goal_progress.dart';
import '../domain/repositories/goal_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../data/goal_repository_impl.dart';
import 'add_measurement_screen.dart';
import 'widgets/goal_adjustment_sheet.dart';
import 'widgets/measurement_chart_widget.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;
  final IGoalRepository? repository;

  const GoalDetailScreen({
    super.key,
    required this.goalId,
    this.repository,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late final IGoalRepository _goalRepository;
  IProfileRepository? _profileRepo;
  Future<Map<String, dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _goalRepository = widget.repository ?? GoalRepositoryImpl();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileRepo ??= context.read<IProfileRepository>();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchGoalDetailData();
    });
  }

  Future<Map<String, dynamic>> _fetchGoalDetailData() async {
    final goal = await _goalRepository.getGoalById(widget.goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    final progress = await _goalRepository.getGoalProgress(goal);

    // Fetch chart points for weight
    final profileRepo = _profileRepo;
    final startDate = goal.startDate.subtract(const Duration(days: 30));
    final endDate = DateTime.now().add(const Duration(days: 1));

    List<ChartDataPoint> chartPoints = [];
    if (profileRepo != null) {
      try {
        chartPoints = await profileRepo.getChartDataForTypeAndRange(
          'weight',
          DateTimeRange(start: startDate, end: endDate),
        );
      } catch (_) {
        chartPoints = [];
      }
    }

    return {
      'goal': goal,
      'progress': progress,
      'chartPoints': chartPoints,
    };
  }

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

  Future<void> _openAdjustmentSheet(Goal goal, GoalProgress? progress) async {
    final startWeight = progress?.currentValue ?? progress?.baselineValue ?? 75.0;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoalAdjustmentSheet(
        goal: goal,
        startWeightKg: startWeight,
        repository: _goalRepository,
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _retireGoal(Goal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.retireGoalDialogTitle),
        content: Text(l10n.retireGoalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.retireGoalConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _goalRepository.retireGoal(goal.id, reason: 'Nutzer hat Ziel beendet');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.goalRetiredSuccessSnack)),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _resumeGoal(Goal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resumeGoalDialogTitle),
        content: Text(l10n.resumeGoalDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.resumeGoalConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _goalRepository.resumeGoal(goal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.goalResumedSuccessSnack)),
        );
        _loadData();
      }
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

    return Scaffold(
      appBar: GlobalAppBar(
        title: l10n.goalDetailScreenTitle,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.error),
                  const SizedBox(height: 12),
                  AppButton.secondary(
                    label: l10n.retry,
                    onPressed: _loadData,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final goal = data['goal'] as Goal;
          final progress = data['progress'] as GoalProgress?;
          final chartPoints = data['chartPoints'] as List<ChartDataPoint>;

          final isWaiting =
              progress?.state == GoalProgressState.waitingForBaseline;
          final isActive = goal.status == GoalStatus.active;
          final isRetired = goal.status == GoalStatus.retired;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: DesignConstants.cardPadding,
              children: [
                // Header card with goal title, preset badge, status
                SummaryCard(
                  child: Padding(
                    padding: DesignConstants.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  DesignConstants.borderRadiusS,
                                ),
                              ),
                              child: Text(
                                _presetLabel(context, goal.preset),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
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
                          ],
                        ),
                        const SizedBox(height: DesignConstants.spacingM),
                        Text(
                          goal.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: DesignConstants.spacingS),
                        Text(
                          '${l10n.goalStartedOnLabel(dateFormat.format(goal.startDate))} • ${goal.isNutritionDriver ? l10n.goalDrivesNutritionBadge : l10n.goalDocumentationOnlyBadge}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),

                // Drei-Säulen-Übersicht: Start, Aktuell, Ziel
                Row(
                  children: [
                    // Start / Baseline
                    Expanded(
                      child: SummaryCard(
                        child: Padding(
                          padding: const EdgeInsets.all(DesignConstants.spacingM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.goalBaselineHeader,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: DesignConstants.spacingS),
                              Text(
                                isWaiting
                                    ? '--'
                                    : formatWeight(progress?.baselineValue),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                progress?.baselineDate != null
                                    ? dateFormat.format(progress!.baselineDate!)
                                    : l10n.goalWaitingForBaselineLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),

                    // Aktuell
                    Expanded(
                      child: SummaryCard(
                        child: Padding(
                          padding: const EdgeInsets.all(DesignConstants.spacingM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.goalCurrentHeader,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: DesignConstants.spacingS),
                              Text(
                                formatWeight(progress?.currentValue),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                progress?.deltaSinceStart != null
                                    ? '${progress!.deltaSinceStart! >= 0 ? "+" : ""}${unitService.convertDisplayValue(progress.deltaSinceStart!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}'
                                    : '--',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: (progress?.deltaSinceStart ?? 0) <= 0
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),

                    // Ziel
                    Expanded(
                      child: SummaryCard(
                        child: Padding(
                          padding: const EdgeInsets.all(DesignConstants.spacingM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.goalTargetHeader,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: DesignConstants.spacingS),
                              Text(
                                goal.targetValue != null
                                    ? formatWeight(goal.targetValue)
                                    : '± 1,0 kg',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goal.targetDate != null
                                    ? dateFormat.format(goal.targetDate!)
                                    : l10n.goalNoTargetDateShort,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingL),

                // Waiting for baseline callout if needed
                if (isWaiting) ...[
                  Container(
                    padding: const EdgeInsets.all(DesignConstants.spacingM),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(DesignConstants.borderRadiusM),
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
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
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
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // Trend & Remaining Distance Card
                if (progress != null && !isWaiting) ...[
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
                                l10n.goalProgressSectionTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (progress.trendRateKgPerWeek != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      DesignConstants.borderRadiusS,
                                    ),
                                  ),
                                  child: Text(
                                    '${progress.trendRateKgPerWeek! >= 0 ? "+" : ""}${unitService.convertDisplayValue(progress.trendRateKgPerWeek!, UnitDimension.weight).toStringAsFixed(2)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: DesignConstants.spacingM),
                          if (progress.progressPercentage != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.progressPercentage,
                                minHeight: 8,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: DesignConstants.spacingS),
                          ],
                          if (progress.remainingDistance != null)
                            Text(
                              l10n.goalRemainingDistanceLabel(
                                '${unitService.convertDisplayValue(progress.remainingDistance!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // Visual Chart View
                if (chartPoints.isNotEmpty) ...[
                  SummaryCard(
                    child: Padding(
                      padding: DesignConstants.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.goalWeightHistoryChartTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: DesignConstants.spacingM),
                          SizedBox(
                            height: 220,
                            child: MeasurementChartWidget.fromData(
                              dataPoints: chartPoints,
                              unit: unitService.unitString(UnitDimension.weight),
                              referenceLineValue: goal.targetValue != null
                                  ? unitService.convertDisplayValue(
                                      goal.targetValue!,
                                      UnitDimension.weight,
                                    )
                                  : null,
                              emptyStateLabel: l10n.emptyStateMeasurements,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // Motivation note if present
                if (goal.reason != null && goal.reason!.trim().isNotEmpty) ...[
                  SummaryCard(
                    child: Padding(
                      padding: DesignConstants.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.quote,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: DesignConstants.spacingS),
                              Text(
                                l10n.goalPersonalMotivationTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignConstants.spacingS),
                          Text(
                            goal.reason!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // Action Buttons
                if (isActive) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: l10n.adjustGoalTitle,
                          onPressed: () => _openAdjustmentSheet(goal, progress),
                        ),
                      ),
                      const SizedBox(width: DesignConstants.spacingM),
                      Expanded(
                        child: AppButton.secondary(
                          label: l10n.retireGoalButton,
                          onPressed: () => _retireGoal(goal),
                        ),
                      ),
                    ],
                  ),
                ] else if (isRetired) ...[
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: l10n.resumeGoalButton,
                      onPressed: () => _resumeGoal(goal),
                    ),
                  ),
                ],
                const BottomContentSpacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
