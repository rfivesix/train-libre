// lib/features/profile/presentation/goal_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/glass_progress_bar.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/value_summary_card.dart';
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

    // Fetch chart points for weight from goal start date up to now
    final profileRepo = _profileRepo;
    final startDate = goal.startDate.subtract(const Duration(days: 1));
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

    // Ensure baseline is included at goal start date if missing
    final baseline = progress?.baselineValue;
    if (baseline != null) {
      if (chartPoints.isEmpty) {
        chartPoints = [
          ChartDataPoint(
            date: goal.startDate,
            value: baseline,
          ),
        ];
      } else if (chartPoints.first.date.isAfter(goal.startDate)) {
        chartPoints.insert(
          0,
          ChartDataPoint(
            date: goal.startDate,
            value: baseline,
          ),
        );
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
              padding: const EdgeInsets.symmetric(
                vertical: DesignConstants.spacingM,
              ),
              children: [
                // Header card with goal title, status, metadata, and motivation
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.screenPaddingHorizontal,
                  ),
                  child: SummaryCard(
                    margin: EdgeInsets.zero,
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
                                  goal.title.isNotEmpty
                                      ? goal.title
                                      : _presetLabel(context, goal.preset),
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
                            ],
                          ),
                          const SizedBox(height: DesignConstants.spacingXS),
                          Text(
                            '${l10n.goalStartedOnLabel(dateFormat.format(goal.startDate))} • ${goal.isNutritionDriver ? l10n.goalDrivesNutritionBadge : l10n.goalDocumentationOnlyBadge}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          if (goal.reason != null &&
                              goal.reason!.trim().isNotEmpty) ...[
                            const SizedBox(height: DesignConstants.spacingS),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.quote,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(
                                  width: DesignConstants.spacingS,
                                ),
                                Expanded(
                                  child: Text(
                                    goal.reason!.trim(),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
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
                ),
                const SizedBox(height: DesignConstants.spacingS),

                // Drei-Säulen-Übersicht: Start, Aktuell, Ziel (ValueSummaryCards)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.screenPaddingHorizontal,
                  ),
                  child: Row(
                    children: [
                      // Start / Baseline
                      Expanded(
                        child: ValueSummaryCard(
                          label: l10n.goalBaselineHeader,
                          value: isWaiting
                              ? '--'
                              : formatWeight(progress?.baselineValue),
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
                              ? '${progress!.deltaSinceStart! >= 0 ? "+" : ""}${unitService.convertDisplayValue(progress.deltaSinceStart!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}'
                              : null,
                          valueColor: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: DesignConstants.spacingS),

                      // Ziel
                      Expanded(
                        child: ValueSummaryCard(
                          label: l10n.goalTargetHeader,
                          value: goal.targetValue != null
                              ? formatWeight(goal.targetValue)
                              : (goal.isMaintenanceOrRecomp
                                  ? l10n.goalMaintainCorridor
                                  : l10n.goalDirectionalOnly),
                          subtitle: goal.targetDate != null
                              ? dateFormat.format(goal.targetDate!)
                              : l10n.goalNoTargetDateShort,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),

                // Waiting for baseline callout if needed
                if (isWaiting) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.screenPaddingHorizontal,
                    ),
                    child: Container(
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
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // GlassProgressBar & Weekly Rate
                if (progress != null && !isWaiting) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.screenPaddingHorizontal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassProgressBar(
                          label: l10n.goalProgressSectionTitle,
                          unit: unitService.unitString(UnitDimension.weight),
                          value: ((progress.progressPercentage ?? 0.0) * 100)
                              .clamp(0.0, 100.0),
                          target: 100.0,
                          color: Colors.green,
                          borderRadius: DesignConstants.borderRadiusL,
                          customSubtitle: progress.remainingDistance != null &&
                                  goal.hasNumericTarget
                              ? l10n.goalRemainingDistanceLabel(
                                  '${unitService.convertDisplayValue(progress.remainingDistance!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.unitString(UnitDimension.weight)}',
                                )
                              : (goal.isMaintenanceOrRecomp
                                  ? (progress.isInToleranceBand == true
                                      ? l10n.goalMaintenanceStable
                                      : l10n.goalMaintenanceDrifting)
                                  : '${((progress.progressPercentage ?? 0.0) * 100).toStringAsFixed(0)}%'),
                        ),
                        if (progress.trendRateKgPerWeek != null ||
                            progress.progressPercentage != null) ...[
                          const SizedBox(height: DesignConstants.spacingXS),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (progress.progressPercentage != null)
                                  Text(
                                    '${(progress.progressPercentage! * 100).toStringAsFixed(0)}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                if (progress.trendRateKgPerWeek != null)
                                  Text(
                                    '${progress.trendRateKgPerWeek! >= 0 ? "+" : ""}${unitService.convertDisplayValue(progress.trendRateKgPerWeek!, UnitDimension.weight).toStringAsFixed(2)} ${unitService.unitString(UnitDimension.weight)}/${l10n.weekShort}',
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
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // Visual Chart View (Full-Width, edge-to-edge)
                if (chartPoints.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.screenPaddingHorizontal,
                    ),
                    child: AppSectionHeader(
                      title: l10n.goalWeightHistoryChartTitle,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Builder(
                    builder: (context) {
                      final startWeight = progress?.baselineValue ??
                          (chartPoints.isNotEmpty
                              ? chartPoints.first.value
                              : 75.0);
                      final targetDate = goal.targetDate ??
                          goal.startDate.add(const Duration(days: 84));
                      final domainEnd = targetDate.isAfter(DateTime.now())
                          ? targetDate
                          : DateTime.now().add(const Duration(days: 7));
                      final targetWeight = goal.targetValue ?? startWeight;

                      return SizedBox(
                        height: 250,
                        child: MeasurementChartWidget.fromData(
                          dataPoints: chartPoints,
                          axisMode: MeasurementChartAxisMode.day,
                          domainDateRange: DateTimeRange(
                            start: goal.startDate,
                            end: domainEnd,
                          ),
                          trajectoryStart: ChartDataPoint(
                            date: goal.startDate,
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
                    },
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                ],

                // Action Buttons
                if (isActive) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.screenPaddingHorizontal,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            label: l10n.adjustGoalTitle,
                            onPressed: () =>
                                _openAdjustmentSheet(goal, progress),
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
                  ),
                ] else if (isRetired) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.screenPaddingHorizontal,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        label: l10n.resumeGoalButton,
                        onPressed: () => _resumeGoal(goal),
                      ),
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
