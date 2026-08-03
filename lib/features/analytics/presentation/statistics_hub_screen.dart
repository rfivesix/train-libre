import '../../statistics/domain/timeframe_block.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import '../../statistics/data/statistics_hub_data_adapter.dart';
import '../../statistics/domain/body_nutrition_analytics_models.dart';
import '../../statistics/domain/hub_payload_models.dart';
import '../../pulse/data/pulse_repository.dart';
import '../../sleep/data/sleep_hub_summary_repository.dart';
import '../../sleep/presentation/sleep_navigation.dart';
import '../../sleep/platform/sleep_sync_service.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/bottom_content_spacer.dart';

import '../../../widgets/common/summary_card.dart';
import '../../steps/presentation/steps_module_screen.dart';
import 'body_nutrition_correlation_screen.dart';
import 'consistency_tracker_screen.dart';
import 'muscle_group_analytics_screen.dart';
import 'pr_dashboard_screen.dart';
import 'recovery_tracker_screen.dart';
import '../../profile/presentation/measurements_screen.dart';
import '../../steps/presentation/statistics_steps_card.dart';
import '../../steps/domain/steps_models.dart';
import '../../pulse/presentation/pulse_analysis_screen.dart';
import '../../../services/health/steps_sync_service.dart';
import 'statistics_hub_view_model.dart';
import '../../../util/timeframe_label_formatter.dart';

import '../../../widgets/common/empty_states/card_empty_state_overlay.dart';
// Standalone widget imports
import 'widgets/analytics_card_base.dart';
import 'widgets/body_metrics_section_card.dart';
import 'widgets/consistency_section_card.dart';
import 'widgets/muscle_volume_section_card.dart';
import 'widgets/performance_section_card.dart';
import 'widgets/pulse_section_card.dart';
import 'widgets/recovery_section_card.dart';
import 'widgets/sleep_section_card.dart';

class StatisticsHubScreen extends StatefulWidget {
  const StatisticsHubScreen({
    super.key,
    StatisticsHubDataAdapter? hubDataAdapter,
    StepsAggregationRepository? stepsRepository,
    SleepHubSummaryRepository? sleepSummaryRepository,
    PulseAnalysisRepository? pulseRepository,
    this.fetchHubAnalytics,
    this.importSleepIfDue,
    this.isSleepTrackingEnabled,
    this.targetStepsLoader,
    this.stepsProviderNameLoader,
  })  : _hubDataAdapter = hubDataAdapter,
        _stepsRepository = stepsRepository,
        _sleepSummaryRepository = sleepSummaryRepository,
        _pulseRepository = pulseRepository;

  final StatisticsHubDataAdapter? _hubDataAdapter;
  final StepsAggregationRepository? _stepsRepository;
  final SleepHubSummaryRepository? _sleepSummaryRepository;
  final PulseAnalysisRepository? _pulseRepository;
  final Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> Function(
    TimeframeBlock selectedBlockType,
    DateTime anchorDate,
    bool isRolling,
  )? fetchHubAnalytics;
  final Future<SleepSyncResult?> Function({
    int lookbackDays,
    Duration minInterval,
    bool force,
  })? importSleepIfDue;
  final Future<bool> Function()? isSleepTrackingEnabled;
  final Future<int> Function()? targetStepsLoader;
  final Future<String> Function()? stepsProviderNameLoader;

  @override
  State<StatisticsHubScreen> createState() => StatisticsHubScreenState();
}

class StatisticsHubScreenState extends State<StatisticsHubScreen> {
  late StatisticsHubViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StatisticsHubViewModel(
      hubDataAdapter: widget._hubDataAdapter,
      stepsRepository: widget._stepsRepository,
      sleepSummaryRepository: widget._sleepSummaryRepository,
      pulseRepository: widget._pulseRepository,
      fetchHubAnalytics: widget.fetchHubAnalytics,
      importSleepIfDue: widget.importSleepIfDue,
      isSleepTrackingEnabled: widget.isSleepTrackingEnabled,
      targetStepsLoader: widget.targetStepsLoader,
      stepsProviderNameLoader: widget.stepsProviderNameLoader ??
          () async {
            if (!mounted) return 'Lokale Daten';
            final l10n = AppLocalizations.of(context);
            if (l10n == null) return 'Lokale Daten';
            final stepsSyncService = StepsSyncService();
            final providerFilter = await stepsSyncService.getProviderFilter();
            final providerRaw =
                StepsSyncService.providerFilterToRaw(providerFilter);
            if (providerRaw == 'appleHealth') {
              return l10n.statisticsProviderAppleHealth;
            }
            if (providerRaw == 'healthConnect') {
              return l10n.statisticsProviderHealthConnect;
            }
            if (providerRaw == 'withings') {
              return l10n.statisticsProviderWithings;
            }
            if (providerRaw == 'garmin') return l10n.statisticsProviderGarmin;
            if (providerRaw == 'fitbit') return l10n.statisticsProviderFitbit;
            return l10n.statisticsProviderLocal;
          },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void refresh({bool force = false}) {
    _viewModel.loadHubAnalytics(force: force);
  }

  void markDirty() {
    _viewModel.markDirty();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatisticsHubViewModel>.value(
      value: _viewModel,
      child: const _StatisticsHubScreenView(),
    );
  }
}

class _StatisticsHubScreenView extends StatelessWidget {
  const _StatisticsHubScreenView();

  List<String> _timeRanges(AppLocalizations l10n) => [
        l10n.filter7DaysShort,
        l10n.filter1MonthShort,
        l10n.filter3MonthsShort,
        l10n.filter6MonthsShort,
        l10n.filter1YearShort,
        l10n.filterMax,
      ];

  static const _hubBlocks = [
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
    TimeframeBlock.year,
    TimeframeBlock.maxBlock,
  ];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StatisticsHubViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final appBarHeight = MediaQuery.paddingOf(context).top; // + kToolbarHeight omitted: same as DiaryScreen/WorkoutHubScreen
    final finalPadding = EdgeInsets.only(
      top: appBarHeight + DesignConstants.cardPadding.top,
      left: 0,
      right: 0,
      bottom: DesignConstants.cardPadding.bottom,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: (viewModel.isActiveGap || viewModel.isSkeletonizing)
            ? const NeverScrollableScrollPhysics()
            : null,
        slivers: [
          SliverPadding(
            padding: finalPadding,
            sliver: (viewModel.isColdStart && !viewModel.isLoadingColdStart)
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: ColdStartEmptyState(
                      icon: LucideIcons.chart_spline,
                      title: l10n.statisticsColdStartTitle,
                      subtitle: l10n.statisticsColdStartSubtitle,
                      callToAction:
                          l10n.emptyStateDiaryColdStartCallToAction,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate([
                      TimeRangeFilter(
                            ranges: _timeRanges(l10n),
                            selectedIndex:
                                _hubBlocks.indexOf(viewModel.activeBlockType),
                            onSelected: (index) {
                              viewModel.activeBlockType = _hubBlocks[index];
                            },
                            onPrevious: viewModel.activeBlockType ==
                                    TimeframeBlock.maxBlock
                                ? null
                                : () => viewModel.shiftTimeframe(true),
                            onNext: viewModel.activeBlockType ==
                                    TimeframeBlock.maxBlock
                                ? null
                                : () => viewModel.shiftTimeframe(false),
                            displayDate: _unifiedRangeLabel(viewModel, l10n),
                            onTapDateDisplay: () async {
                              final selected = await adaptive_pickers
                                  .showAdaptiveTimeframePicker(
                                context: context,
                                activeBlock: viewModel.activeBlockType,
                                initialAnchor: viewModel.anchorDate,
                                initialIsRolling: viewModel.isRolling,
                                earliestAvailableDay: DateTime(2020),
                              );
                              if (selected != null) {
                                viewModel.setTimeframeSelection(selected);
                              }
                            },
                            nextEnabled: viewModel.activeBlockType !=
                                    TimeframeBlock.maxBlock &&
                                (viewModel.isRolling ||
                                    !viewModel.activeBlockType
                                        .getBounds(viewModel.anchorDate,
                                            DateTime(2020))
                                        .start
                                        .isAtSameMomentAs(viewModel
                                            .activeBlockType
                                            .getBounds(
                                                DateTime.now(), DateTime(2020))
                                            .start)),
                            showDateNavigation: viewModel.activeBlockType !=
                                TimeframeBlock.maxBlock,
                          ),
                          const SizedBox(height: DesignConstants.spacingL),
                          Builder(builder: (context) {
                            Widget contentColumn = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (viewModel.stepsTrackingEnabled) ...[
                                  AppSectionHeader(title: l10n.steps),
                                  RepaintBoundary(
                                    child: _buildStepsCard(
                                        context, viewModel, l10n),
                                  ),
                                  const SizedBox(
                                      height: DesignConstants.spacingL),
                                ],
                                AppSectionHeader(title: l10n.sectionRecovery),
                                RepaintBoundary(
                                  child: _buildRecoverySection(
                                      context, viewModel, l10n),
                                ),
                                if (viewModel.sleepTrackingEnabled) ...[
                                  const SizedBox(
                                      height: DesignConstants.spacingS),
                                  RepaintBoundary(
                                    child: _buildSleepSection(
                                        context, viewModel, l10n),
                                  ),
                                ],
                                if (viewModel.pulseTrackingEnabled) ...[
                                  const SizedBox(
                                      height: DesignConstants.spacingS),
                                  RepaintBoundary(
                                    child: _buildPulseSection(
                                        context, viewModel, l10n),
                                  ),
                                ],
                                const SizedBox(
                                    height: DesignConstants.spacingL),
                                AppSectionHeader(
                                    title: l10n.statisticsSectionBody),
                                RepaintBoundary(
                                  child: _buildBodyMetricsSection(
                                      context, viewModel, l10n),
                                ),
                                const SizedBox(
                                    height: DesignConstants.spacingS),
                                _buildMeasurementsShortcutCard(context, l10n),
                                const SizedBox(
                                    height: DesignConstants.spacingL),
                                AppSectionHeader(
                                    title: l10n.statisticsSectionTraining),
                                RepaintBoundary(
                                  child: _buildConsistencySection(
                                      context, viewModel, l10n),
                                ),
                                const SizedBox(
                                    height: DesignConstants.spacingS),
                                RepaintBoundary(
                                  child: _buildPerformanceSection(
                                      context, viewModel, l10n),
                                ),
                                const SizedBox(
                                    height: DesignConstants.spacingS),
                                RepaintBoundary(
                                  child: _buildMuscleVolumeSection(
                                      context, viewModel, l10n),
                                ),
                                const BottomContentSpacer(),
                              ],
                            );

                            Widget content = Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignConstants.cardPaddingInternal,
                              ),
                              child: contentColumn,
                            );

                            if (viewModel.isActiveGap || viewModel.isSkeletonizing) {
                              content = SizedBox(
                                height: MediaQuery.of(context).size.height -
                                    appBarHeight -
                                    140,
                                child: ClipRect(
                                  child: SingleChildScrollView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    child: content,
                                  ),
                                ),
                              );
                            }

                            content = Skeletonizer(
                              enabled:
                                  viewModel.isSkeletonizing || viewModel.isActiveGap,
                              child: content,
                            );

                            if (viewModel.isActiveGap) {
                              content = ActiveGapOverlay(
                                message: l10n.emptyStateActiveGapOverlay,
                                background: content,
                              );
                            }

                            return content;
                          }),
                        ]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.stepsState;

    if (section.hasError && !section.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
          context,
          l10n,
          () => viewModel.loadHubAnalytics(),
          StatisticsHubSectionId.steps,
          l10n.steps);
    }
    final range = viewModel.stepsRange;
    final hasData =
        (range?.dailyTotals.any((bucket) => bucket.steps > 0) ?? false);
    final subtitleRange = _unifiedRangeLabel(viewModel, l10n);
    final stepsTitle = l10n.steps;

    final displayRange = hasData
        ? range!
        : RangeStepsAggregation(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
            dailyTotals: List.generate(7, (i) {
              return StepsBucket(
                start: DateTime.now().subtract(Duration(days: 7 - i)),
                steps: [6200, 8100, 7300, 5400, 9200, 10500, 8500][i],
              );
            }),
            totalSteps: 55200,
            averageDailySteps: 7885.0,
          );

    // In 7-day mode we show today's steps; in longer ranges we show total steps.
    final bool isSevenDays = viewModel.activeBlockType.index == 0;

    int currentSteps = 0;
    String stepsSubtitle = l10n.today;

    if (isSevenDays) {
      final todayBucket = displayRange.dailyTotals.lastWhere(
        (bucket) =>
            bucket.start.isBefore(DateTime.now().add(const Duration(days: 1))),
        orElse: () => displayRange.dailyTotals.last, // fallback
      );
      currentSteps = todayBucket.steps;
    } else {
      currentSteps = displayRange.totalSteps;
      stepsSubtitle = l10n.statisticsTotalSteps;
    }

    Widget cardChild = StatisticsStepsCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StepsModuleScreen()),
        );
      },
      title: stepsTitle,
      chipText: subtitleRange,
      currentSteps: currentSteps,
      currentStepsSubtitle: stepsSubtitle,
      dailyTotals: displayRange.dailyTotals,
      dailyGoal: viewModel.targetSteps,
    );

    if (!hasData) {
      cardChild = CardEmptyStateOverlay(
        isEmpty: true,
        message: l10n.emptyStateActiveGapOverlay,
        child: cardChild,
      );
    }

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: section,
      child: cardChild,
    );
  }

  String? _unifiedRangeLabel(
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    if (viewModel.activeBlockType == TimeframeBlock.maxBlock) {
      return l10n.filterMax;
    }
    if (viewModel.isRolling) {
      return TimeframeLabelFormatter.formatRolling(
          viewModel.activeBlockType, l10n);
    }
    return TimeframeLabelFormatter.format(
      viewModel.activeBlockType,
      viewModel.anchorDate,
      l10n,
    );
  }

  Widget _buildRecoverySection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final card = RecoverySectionCard(
      state: viewModel.recoveryState,
      chipText: null, // As requested, no pill for Recovery
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecoveryTrackerScreen()),
        );
      },
    );
    final hasData = viewModel.recoveryState.data?.hasData ?? false;
    if (hasData) return card;
    return CardEmptyStateOverlay(
      isEmpty: true,
      message: l10n.emptyStateActiveGapOverlay,
      child: card,
    );
  }

  Widget _buildSleepSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final card = SleepSectionCard(
      state: viewModel.sleepState,
      rangeLabel: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () => SleepNavigation.openDay(context),
    );
    // Only show overlay when tracking IS enabled but no data
    final hasData = viewModel.sleepState.data?.hasData ?? false;
    if (hasData) return card;
    return CardEmptyStateOverlay(
      isEmpty: true,
      message: l10n.emptyStateActiveGapOverlay,
      child: card,
    );
  }

  Widget _buildPulseSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final rangeLabel = _unifiedRangeLabel(viewModel, l10n);
    final card = PulseSectionCard(
      state: viewModel.pulseState,
      fallbackRangeLabel: rangeLabel ?? '',
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PulseAnalysisScreen()),
        );
      },
    );
    // Only show overlay when tracking IS enabled but no data
    final hasData = viewModel.pulseState.data?.hasData ?? false;
    if (hasData) return card;
    return CardEmptyStateOverlay(
      isEmpty: true,
      message: l10n.emptyStateActiveGapOverlay,
      child: card,
    );
  }

  Widget _buildConsistencySection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final card = ConsistencySectionCard(
      state: viewModel.consistencyState,
      chipText: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConsistencyTrackerScreen()),
        );
      },
    );
    final totalWorkouts =
        viewModel.consistencyState.data?.trainingStats.totalWorkouts ?? 0;
    if (totalWorkouts > 0) return card;
    return CardEmptyStateOverlay(
      isEmpty: true,
      message: l10n.emptyStateActiveGapOverlay,
      child: card,
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final card = PerformanceSectionCard(
      state: viewModel.performanceState,
      chipText: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PRDashboardScreen()),
        );
      },
    );
    final hasRecords =
        (viewModel.performanceState.data?.recentPrs.isNotEmpty ?? false) ||
        (viewModel.performanceState.data?.notableImprovements.isNotEmpty ?? false);
    if (hasRecords) return card;
    return CardEmptyStateOverlay(
      isEmpty: true,
      message: l10n.emptyStateActiveGapOverlay,
      child: card,
    );
  }

  Widget _buildMuscleVolumeSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final card = MuscleVolumeSectionCard(
      state: viewModel.volumeMusclesState,
      rangeLabel: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MuscleGroupAnalyticsScreen()),
        );
      },
    );
    final hasVolumeData =
        viewModel.volumeMusclesState.data?.weeklyVolume.isNotEmpty ?? false;
    if (hasVolumeData) return card;
    return CardEmptyStateOverlay(
      isEmpty: true,
      message: l10n.emptyStateActiveGapOverlay,
      child: card,
    );
  }

  Widget _buildBodyMetricsSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final card = BodyMetricsSectionCard(
      state: viewModel.bodyNutritionState,
      rangeLabel: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BodyNutritionCorrelationScreen(
              initialRangeIndex: viewModel.activeBlockType.index,
            ),
          ),
        );
      },
    );
    final bodyNutrition = viewModel.bodyNutritionState.data;
    final hasBodyData = bodyNutrition?.hasAnyData ?? false;
    if (hasBodyData) return card;
    return CardEmptyStateOverlay(
      isEmpty: true,
      message: l10n.emptyStateActiveGapOverlay,
      child: card,
    );
  }

  Widget _buildMeasurementsShortcutCard(
      BuildContext context, AppLocalizations l10n) {
    return SummaryCard(
      key: const Key('statistics_measurements_link_card'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MeasurementsScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingL),
        child: Row(
          children: [
            Icon(
              LucideIcons.ruler,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.body_measurements,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.all_measurements_no_cap,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevron_right),
          ],
        ),
      ),
    );
  }
}
