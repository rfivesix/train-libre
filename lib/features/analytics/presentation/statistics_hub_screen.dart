import '../../statistics/domain/timeframe_block.dart';
import 'dart:async';
import 'statistics_hub_preferences.dart';

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
import '../../sleep/platform/sleep_sync_service.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/card_morph_route.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../sleep/presentation/day/sleep_day_overview_page.dart';
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
import 'widgets/macro_section_card.dart';
import 'widgets/micronutrient_section_card.dart';
import 'widgets/recovery_section_card.dart';
import 'widgets/sleep_section_card.dart';
import 'widgets/water_section_card.dart';
import 'macro_statistics_screen.dart';

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
    this.showAllData = false,
    this.initialBlockType = TimeframeBlock.week,
    this.initialAnchorDate,
    this.initialIsRolling = true,
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
  final bool showAllData;
  final TimeframeBlock initialBlockType;
  final DateTime? initialAnchorDate;
  final bool initialIsRolling;

  @override
  State<StatisticsHubScreen> createState() => StatisticsHubScreenState();
}

class StatisticsHubScreenState extends State<StatisticsHubScreen> {
  late StatisticsHubViewModel _viewModel;
  List<StatisticsHubCardId> _pinnedCards =
      StatisticsHubPreferences.defaultPinnedCards;

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
      initialBlockType: widget.initialBlockType,
      initialAnchorDate: widget.initialAnchorDate,
      initialIsRolling: widget.initialIsRolling,
    );
    unawaited(StatisticsHubPreferences.loadPinnedCards().then((cards) {
      if (mounted) setState(() => _pinnedCards = cards);
    }));
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

  Future<void> reloadPinnedCards() async {
    final cards = await StatisticsHubPreferences.loadPinnedCards();
    if (mounted) setState(() => _pinnedCards = cards);
  }

  Widget buildPinnedTimeframeFilter(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        return _StatisticsHubScreenView(
          showAllData: widget.showAllData,
          pinnedCards: _pinnedCards,
        )._buildTimeframeFilter(
          context,
          _viewModel,
          l10n,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatisticsHubViewModel>.value(
      value: _viewModel,
      child: _StatisticsHubScreenView(
        showAllData: widget.showAllData,
        pinnedCards: _pinnedCards,
      ),
    );
  }
}

class _StatisticsHubScreenView extends StatelessWidget {
  const _StatisticsHubScreenView({
    required this.showAllData,
    required this.pinnedCards,
  });

  final bool showAllData;
  final List<StatisticsHubCardId> pinnedCards;

  static const _hubBlocks = [
    TimeframeBlock.week,
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
    TimeframeBlock.year,
    TimeframeBlock.maxBlock,
  ];

  Widget _buildTimeframeFilter(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return TimeRangeFilter(
      ranges: [
        l10n.filter7DaysShort,
        l10n.filter1MonthShort,
        l10n.filter3MonthsShort,
        l10n.filter6MonthsShort,
        l10n.filter1YearShort,
        l10n.filterMax,
      ],
      selectedIndex: _hubBlocks.indexOf(viewModel.activeBlockType),
      onSelected: (index) => viewModel.activeBlockType = _hubBlocks[index],
      onPrevious: viewModel.activeBlockType == TimeframeBlock.maxBlock
          ? null
          : () => viewModel.shiftTimeframe(true),
      onNext: viewModel.activeBlockType == TimeframeBlock.maxBlock
          ? null
          : () => viewModel.shiftTimeframe(false),
      displayDate: _unifiedRangeLabel(viewModel, l10n),
      onTapDateDisplay: () async {
        final selected = await adaptive_pickers.showAdaptiveTimeframePicker(
          context: context,
          activeBlock: viewModel.activeBlockType,
          initialAnchor: viewModel.anchorDate,
          initialIsRolling: viewModel.isRolling,
          earliestAvailableDay: DateTime(2020),
        );
        if (selected != null) viewModel.setTimeframeSelection(selected);
      },
      nextEnabled: viewModel.activeBlockType != TimeframeBlock.maxBlock &&
          (viewModel.isRolling ||
              !viewModel.activeBlockType
                  .getBounds(viewModel.anchorDate, DateTime(2020))
                  .start
                  .isAtSameMomentAs(viewModel.activeBlockType
                      .getBounds(DateTime.now(), DateTime(2020))
                      .start)),
      showDateNavigation: viewModel.activeBlockType != TimeframeBlock.maxBlock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StatisticsHubViewModel>();
    final l10n = AppLocalizations.of(context)!;
    // The pinned app bar extension is already accounted for in
    // MediaQuery.paddingOf(context).top by the host Scaffold.
    final finalPadding = EdgeInsets.only(
      top: (showAllData
              ? MediaQuery.paddingOf(context).top + kToolbarHeight + 56
              : MediaQuery.paddingOf(context).top) +
          DesignConstants.cardPadding.top,
      left: 0,
      right: 0,
      bottom: DesignConstants.cardPadding.bottom,
    );

    return Scaffold(
      backgroundColor: showAllData
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.transparent,
      extendBodyBehindAppBar: showAllData,
      appBar: showAllData
          ? GlobalAppBar(
              title: l10n.statisticsAllDataTitle,
              bottom: _buildTimeframeFilter(context, viewModel, l10n),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: finalPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHubCards(context, viewModel, l10n),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryTitle(String id, AppLocalizations l10n) => switch (id) {
        'activity' => l10n.statisticsActivityCategory,
        'recovery' => l10n.sectionRecovery,
        'body' => l10n.statisticsSectionBody,
        'training' => l10n.statisticsSectionTraining,
        _ => l10n.nutrition,
      };

  Widget _buildHubCards(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final ids = showAllData ? StatisticsHubCardId.values : pinnedCards;
    final children = <Widget>[];

    if (showAllData) {
      for (final category in const [
        'activity',
        'recovery',
        'body',
        'training',
        'nutrition',
      ]) {
        final cards = ids.where((card) => card.categoryId == category).toList();
        if (cards.isEmpty) continue;
        children.add(AppSectionHeader(
          title: _categoryTitle(category, l10n),
          isFirst: children.isEmpty,
        ));
        for (final card in cards) {
          if (children.isNotEmpty) {
            children.add(const SizedBox(height: DesignConstants.spacingS));
          }
          children.add(RepaintBoundary(
              child: _buildHubCard(context, viewModel, l10n, card)));
        }
        children.add(const SizedBox(height: DesignConstants.spacingL));
      }
    } else {
      for (final card in ids) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: DesignConstants.spacingS));
        }
        children.add(RepaintBoundary(
            child: _buildHubCard(context, viewModel, l10n, card)));
      }
      if (pinnedCards.isEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(l10n.statisticsPinnedEmptyHint)),
        ));
      }
      children.add(const SizedBox(height: DesignConstants.spacingL));
      children.add(_buildAllDataShortcut(context, viewModel, l10n));
    }

    children.add(const BottomContentSpacer());
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.cardPaddingInternal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    if (viewModel.isSkeletonizing || viewModel.isActiveGap) {
      content = Skeletonizer(enabled: true, child: content);
    }
    return content;
  }

  Widget _buildHubCard(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
    StatisticsHubCardId card,
  ) {
    switch (card) {
      case StatisticsHubCardId.steps:
        return _buildStepsCard(context, viewModel, l10n);
      case StatisticsHubCardId.sleep:
        return _buildSleepSection(context, viewModel, l10n);
      case StatisticsHubCardId.pulse:
        return _buildPulseSection(context, viewModel, l10n);
      case StatisticsHubCardId.recoveryReadiness:
        final chipText = _unifiedRangeLabel(viewModel, l10n);
        return MorphSourceScope(
          builder: (context, setHidden) => Builder(
            builder: (cardContext) => RecoverySectionCard(
              state: viewModel.recoveryState,
              chipText: chipText,
              onRetry: () => viewModel.loadHubAnalytics(),
              onTap: () => Navigator.of(context).push(
                CardMorphRoute<void>(
                  sourceContext: cardContext,
                  sourceBuilder: (_) => RecoverySectionCard(
                    state: viewModel.recoveryState,
                    chipText: chipText,
                    onRetry: () {},
                    onTap: () {},
                  ),
                  onSourceVisibilityChanged: setHidden,
                  builder: (_) => const RecoveryTrackerScreen(),
                ),
              ),
            ),
          ),
        );
      case StatisticsHubCardId.bodyNutrition:
        return _buildBodyMetricsSection(context, viewModel, l10n);
      case StatisticsHubCardId.bodyMeasurements:
        return _buildMeasurementsShortcutCard(context, l10n);
      case StatisticsHubCardId.consistency:
        return _buildConsistencySection(context, viewModel, l10n);
      case StatisticsHubCardId.performance:
        return _buildPerformanceSection(context, viewModel, l10n);
      case StatisticsHubCardId.muscleGroups:
        return _buildMuscleVolumeSection(context, viewModel, l10n);
      case StatisticsHubCardId.macros:
        return _buildMacroSection(context, viewModel, l10n);
      case StatisticsHubCardId.water:
        return WaterSectionCard(
          block: viewModel.activeBlockType,
          anchor: viewModel.anchorDate,
          isRolling: viewModel.isRolling,
        );
      case StatisticsHubCardId.micronutrients:
        return MicronutrientSectionCard(
          block: viewModel.activeBlockType,
          anchor: viewModel.anchorDate,
          isRolling: viewModel.isRolling,
        );
    }
  }

  Widget _buildAllDataShortcut(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return SummaryCard(
      margin: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StatisticsHubScreen(
            showAllData: true,
            initialBlockType: viewModel.activeBlockType,
            initialAnchorDate: viewModel.anchorDate,
            initialIsRolling: viewModel.isRolling,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.spacingL),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.statisticsAllDataAction,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
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
                steps: showAllData
                    ? 0
                    : [6200, 8100, 7300, 5400, 9200, 10500, 8500][i],
              );
            }),
            totalSteps: showAllData ? 0 : 55200,
            averageDailySteps: showAllData ? 0 : 7885.0,
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

    Widget cardChild = MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => StatisticsStepsCard(
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => StatisticsStepsCard(
                  onTap: () {},
                  title: stepsTitle,
                  chipText: subtitleRange,
                  currentSteps: currentSteps,
                  currentStepsSubtitle: stepsSubtitle,
                  dailyTotals: displayRange.dailyTotals,
                  dailyGoal: viewModel.targetSteps,
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => const StepsModuleScreen(),
              ),
            );
          },
          title: stepsTitle,
          chipText: subtitleRange,
          currentSteps: currentSteps,
          currentStepsSubtitle: stepsSubtitle,
          dailyTotals: displayRange.dailyTotals,
          dailyGoal: viewModel.targetSteps,
        ),
      ),
    );

    if (!hasData && !showAllData) {
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

  Widget _buildSleepSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final card = MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => SleepSectionCard(
          state: viewModel.sleepState,
          rangeLabel: _unifiedRangeLabel(viewModel, l10n),
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => SleepSectionCard(
                  state: viewModel.sleepState,
                  rangeLabel: _unifiedRangeLabel(viewModel, l10n),
                  onRetry: () {},
                  onTap: () {},
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => SleepDayOverviewPage(
                  selectedDay: DateTime.now(),
                ),
              ),
            );
          },
        ),
      ),
    );
    // Only show overlay when tracking IS enabled but no data
    final hasData = viewModel.sleepState.data?.hasData ?? false;
    if (hasData || showAllData) return card;
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
    final card = MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => PulseSectionCard(
          state: viewModel.pulseState,
          fallbackRangeLabel: rangeLabel ?? '',
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => PulseSectionCard(
                  state: viewModel.pulseState,
                  fallbackRangeLabel: rangeLabel ?? '',
                  onRetry: () {},
                  onTap: () {},
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => const PulseAnalysisScreen(),
              ),
            );
          },
        ),
      ),
    );
    // Only show overlay when tracking IS enabled but no data
    final hasData = viewModel.pulseState.data?.hasData ?? false;
    if (hasData || showAllData) return card;
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
    final card = MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => ConsistencySectionCard(
          state: viewModel.consistencyState,
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => ConsistencySectionCard(
                  state: viewModel.consistencyState,
                  onRetry: () {},
                  onTap: () {},
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => const ConsistencyTrackerScreen(),
              ),
            );
          },
        ),
      ),
    );
    final totalWorkouts =
        viewModel.consistencyState.data?.trainingStats.totalWorkouts ?? 0;
    if (totalWorkouts > 0 || showAllData) return card;
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
    final card = MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => PerformanceSectionCard(
          state: viewModel.performanceState,
          chipText: _unifiedRangeLabel(viewModel, l10n),
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => PerformanceSectionCard(
                  state: viewModel.performanceState,
                  chipText: _unifiedRangeLabel(viewModel, l10n),
                  onRetry: () {},
                  onTap: () {},
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => const PRDashboardScreen(),
              ),
            );
          },
        ),
      ),
    );
    final hasRecords =
        (viewModel.performanceState.data?.recentPrs.isNotEmpty ?? false) ||
            (viewModel.performanceState.data?.notableImprovements.isNotEmpty ??
                false);
    if (hasRecords || showAllData) return card;
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
    final card = MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => MuscleVolumeSectionCard(
          state: viewModel.volumeMusclesState,
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => MuscleVolumeSectionCard(
                  state: viewModel.volumeMusclesState,
                  onRetry: () {},
                  onTap: () {},
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => const MuscleGroupAnalyticsScreen(),
              ),
            );
          },
        ),
      ),
    );
    final hasVolumeData =
        viewModel.volumeMusclesState.data?.weeklyVolume.isNotEmpty ?? false;
    if (hasVolumeData || showAllData) return card;
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
    final card = MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => BodyMetricsSectionCard(
          state: viewModel.bodyNutritionState,
          rangeLabel: _unifiedRangeLabel(viewModel, l10n),
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => BodyMetricsSectionCard(
                  state: viewModel.bodyNutritionState,
                  rangeLabel: _unifiedRangeLabel(viewModel, l10n),
                  onRetry: () {},
                  onTap: () {},
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => BodyNutritionCorrelationScreen(
                  initialBlock: viewModel.activeBlockType,
                  initialAnchorDate: viewModel.anchorDate,
                  initialIsRolling: viewModel.isRolling,
                ),
              ),
            );
          },
        ),
      ),
    );
    final bodyNutrition = viewModel.bodyNutritionState.data;
    final hasBodyData = bodyNutrition?.hasAnyData ?? false;
    if (hasBodyData || showAllData) return card;
    return CardEmptyStateOverlay(
      isEmpty: true,
      message: l10n.emptyStateActiveGapOverlay,
      child: card,
    );
  }

  Widget _buildMacroSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final rangeLabel = _unifiedRangeLabel(viewModel, l10n);
    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => MacroSectionCard(
          activeBlockType: viewModel.activeBlockType,
          anchorDate: viewModel.anchorDate,
          isRolling: viewModel.isRolling,
          rangeLabel: rangeLabel,
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => MacroSectionCard(
                  activeBlockType: viewModel.activeBlockType,
                  anchorDate: viewModel.anchorDate,
                  isRolling: viewModel.isRolling,
                  rangeLabel: rangeLabel,
                  onTap: () {},
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => MacroStatisticsScreen(
                  initialBlock: viewModel.activeBlockType,
                  initialAnchorDate: viewModel.anchorDate,
                  initialIsRolling: viewModel.isRolling,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMeasurementsShortcutCard(
      BuildContext context, AppLocalizations l10n) {
    Widget buildShortcutContent() => Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          child: Row(
            children: [
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
        );

    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => SummaryCard(
          key: const Key('statistics_measurements_link_card'),
          margin: EdgeInsets.zero,
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) =>
                    SummaryCard(child: buildShortcutContent()),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => const MeasurementsScreen(),
              ),
            );
          },
          child: buildShortcutContent(),
        ),
      ),
    );
  }
}
