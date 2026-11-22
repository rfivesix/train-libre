import '../../statistics/domain/timeframe_block.dart';

import 'dart:async';

import 'statistics_hub_preferences.dart';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../statistics/data/statistics_hub_data_adapter.dart';
import '../../statistics/domain/body_nutrition_analytics_models.dart';
import '../../statistics/domain/hub_payload_models.dart';
import '../../pulse/data/pulse_repository.dart';
import '../../sleep/data/sleep_hub_summary_repository.dart';
import '../../sleep/platform/sleep_sync_service.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/unit_service.dart';
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

// Standalone widget imports
import 'widgets/analytics_card_base.dart';
import 'widgets/statistics_overview_card.dart';
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
    this._hubDataAdapter,
    this._stepsRepository,
    this._sleepSummaryRepository,
    this._pulseRepository,
    this.fetchHubAnalytics,
    this.importSleepIfDue,
    this.isSleepTrackingEnabled,
    this.targetStepsLoader,
    this.stepsProviderNameLoader,
    this.showAllData = false,
    this.initialBlockType = TimeframeBlock.week,
    this.initialAnchorDate,
    this.initialIsRolling = true,
  });

  final StatisticsHubDataAdapter? _hubDataAdapter;
  final StepsAggregationRepository? _stepsRepository;
  final SleepHubSummaryRepository? _sleepSummaryRepository;
  final PulseAnalysisRepository? _pulseRepository;
  final Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> Function(
    TimeframeBlock selectedBlockType,
    DateTime anchorDate,
    bool isRolling,
  )?
  fetchHubAnalytics;
  final Future<SleepSyncResult?> Function({
    int lookbackDays,
    Duration minInterval,
    bool force,
  })?
  importSleepIfDue;
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
  int _overviewRefreshToken = 0;
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
      stepsProviderNameLoader:
          widget.stepsProviderNameLoader ??
          () async {
            if (!mounted) return 'Lokale Daten';
            final l10n = AppLocalizations.of(context);
            if (l10n == null) return 'Lokale Daten';
            final stepsSyncService = StepsSyncService();
            final providerFilter = await stepsSyncService.getProviderFilter();
            final providerRaw = StepsSyncService.providerFilterToRaw(
              providerFilter,
            );
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
      initialBlockType: TimeframeBlock.week,
      initialAnchorDate: DateTime.now(),
      initialIsRolling: true,
    );
    unawaited(
      StatisticsHubPreferences.loadPinnedCards().then((cards) {
        if (mounted) setState(() => _pinnedCards = cards);
      }),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void refresh({bool force = false}) {
    _viewModel.loadHubAnalytics(force: force);
    setState(() => _overviewRefreshToken++);
  }

  void markDirty() {
    _viewModel.markDirty();
    setState(() => _overviewRefreshToken++);
  }

  Future<void> reloadPinnedCards() async {
    final cards = await StatisticsHubPreferences.loadPinnedCards();
    if (mounted) setState(() => _pinnedCards = cards);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatisticsHubViewModel>.value(
      value: _viewModel,
      child: _StatisticsHubScreenView(
        showAllData: widget.showAllData,
        pinnedCards: _pinnedCards,
        overviewRefreshToken: _overviewRefreshToken,
      ),
    );
  }
}

class _StatisticsHubScreenView extends StatelessWidget {
  const _StatisticsHubScreenView({
    required this.showAllData,
    required this.pinnedCards,
    this.overviewRefreshToken = 0,
  });

  final bool showAllData;
  final List<StatisticsHubCardId> pinnedCards;
  final int overviewRefreshToken;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StatisticsHubViewModel>();
    final l10n = AppLocalizations.of(context)!;
    // The pinned app bar extension is already accounted for in
    // MediaQuery.paddingOf(context).top by the host Scaffold.
    final finalPadding = EdgeInsets.only(
      top:
          (showAllData
              ? MediaQuery.paddingOf(context).top + kToolbarHeight
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
          ? GlobalAppBar(title: l10n.statisticsAllDataTitle)
          : null,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: finalPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!showAllData)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.cardPaddingInternal,
                    ),
                    child: StatisticsOverviewCard(
                      refreshToken: overviewRefreshToken,
                    ),
                  ),
                if (!showAllData)
                  const SizedBox(height: DesignConstants.spacingS),
                ..._buildHubCards(context, viewModel, l10n),
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

  List<Widget> _buildHubCards(
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
        children.add(
          AppSectionHeader(
            title: _categoryTitle(category, l10n),
            isFirst: children.isEmpty,
          ),
        );
        for (final card in cards) {
          if (children.isNotEmpty) {
            children.add(const SizedBox(height: DesignConstants.spacingS));
          }
          children.add(
            RepaintBoundary(
              child: _buildHubCard(context, viewModel, l10n, card),
            ),
          );
        }
        children.add(const SizedBox(height: DesignConstants.spacingL));
      }
    } else {
      for (final card in ids) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: DesignConstants.spacingS));
        }
        children.add(
          RepaintBoundary(child: _buildHubCard(context, viewModel, l10n, card)),
        );
      }
      if (pinnedCards.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.statisticsPinnedEmptyHint)),
          ),
        );
      }
      children.add(const SizedBox(height: DesignConstants.spacingL));
      children.add(_buildAllDataShortcut(context, viewModel, l10n));
    }

    children.add(const BottomContentSpacer());
    return children
        .map(
          (child) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.cardPaddingInternal,
            ),
            child: child,
          ),
        )
        .toList();
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
        final String? chipText = null;
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
        return _buildMeasurementsShortcutCard(context, viewModel, l10n);
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
          block: TimeframeBlock.week,
          anchor: DateTime.now(),
          isRolling: true,
        );
      case StatisticsHubCardId.micronutrients:
        return MicronutrientSectionCard(
          block: TimeframeBlock.week,
          anchor: DateTime.now(),
          isRolling: true,
        );
    }
  }

  Widget _emptyCard(
    BuildContext context,
    String title,
    String message,
    Widget Function() destination, {
    String? chipText,
  }) {
    final theme = Theme.of(context);
    return SummaryCard(
      margin: EdgeInsets.zero,
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => destination())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsCardBase.buildHeaderWithChevron(
            context,
            label: title,
            chipText: chipText,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDataShortcut(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return SummaryCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
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
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            AnalyticsCardBase.buildDrillDownHint(context),
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
        l10n.steps,
      );
    }
    final range = viewModel.stepsRange;
    final hasData =
        (range?.dailyTotals.any((bucket) => bucket.steps > 0) ?? false);
    final subtitleRange = _unifiedRangeLabel(viewModel, l10n);
    final stepsTitle = l10n.steps;

    if (!hasData && !section.isLoading && !section.hasError) {
      return AnalyticsCardBase.decorateSectionCard(
        context,
        state: section,
        child: _emptyCard(
          context,
          l10n.steps,
          l10n.statisticsEmptySteps,
          () => const StepsModuleScreen(initialScope: StepsScope.week),
          chipText: subtitleRange,
        ),
      );
    }

    final displayRange = range ??
        RangeStepsAggregation(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
          dailyTotals: const [],
          totalSteps: 0,
          averageDailySteps: 0.0,
        );

    // In 7-day mode we show today's steps; in longer ranges we show total steps.
    final bool isSevenDays = viewModel.activeBlockType == TimeframeBlock.week;

    int currentSteps = 0;
    String stepsSubtitle = l10n.today;

    if (isSevenDays && displayRange.dailyTotals.isNotEmpty) {
      final todayBucket = displayRange.dailyTotals.lastWhere(
        (bucket) =>
            bucket.start.isBefore(DateTime.now().add(const Duration(days: 1))),
        orElse: () => displayRange.dailyTotals.last,
      );
      currentSteps = todayBucket.steps;
    } else {
      currentSteps = displayRange.totalSteps;
      stepsSubtitle = l10n.statisticsTotalSteps;
    }

    final Widget cardChild = MorphSourceScope(
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
                builder: (_) => const StepsModuleScreen(
                  initialScope: StepsScope.week,
                ),
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

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: section,
      child: cardChild,
    );
  }

  String _unifiedRangeLabel(
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) => TimeframeLabelFormatter.formatRolling(TimeframeBlock.week, l10n);

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
                builder: (_) =>
                    SleepDayOverviewPage(selectedDay: DateTime.now()),
              ),
            );
          },
        ),
      ),
    );
    // Only show overlay when tracking IS enabled but no data
    final hasData = viewModel.sleepState.data?.hasData ?? false;
    if (hasData) return card;
    if (viewModel.sleepState.isLoading ||
        viewModel.sleepState.hasError ||
        !viewModel.sleepState.hasData) {
      return card;
    }
    return _emptyCard(
      context,
      l10n.sleepHubScoreLabel,
      l10n.statisticsEmptySleep,
      () => SleepDayOverviewPage(selectedDay: DateTime.now()),
      chipText: _unifiedRangeLabel(viewModel, l10n),
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
          fallbackRangeLabel: rangeLabel,
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => PulseSectionCard(
                  state: viewModel.pulseState,
                  fallbackRangeLabel: rangeLabel,
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
    if (hasData) return card;
    if (viewModel.pulseState.isLoading ||
        viewModel.pulseState.hasError ||
        !viewModel.pulseState.hasData) {
      return card;
    }
    return _emptyCard(
      context,
      l10n.pulseTitle,
      l10n.statisticsEmptyPulse,
      () => const PulseAnalysisScreen(),
      chipText: rangeLabel,
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
    if (totalWorkouts > 0) return card;
    if (viewModel.consistencyState.isLoading ||
        viewModel.consistencyState.hasError ||
        !viewModel.consistencyState.hasData) {
      return card;
    }
    return _emptyCard(
      context,
      l10n.consistencyTrackerTitle,
      l10n.statisticsEmptyTraining,
      () => const ConsistencyTrackerScreen(),
      chipText: l10n.analyticsLastWeeks(6),
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
          chipText: l10n.statisticsOverview30Days,
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => PerformanceSectionCard(
                  state: viewModel.performanceState,
                  chipText: l10n.statisticsOverview30Days,
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
        viewModel.performanceState.data?.notableImprovements.isNotEmpty ??
        false;
    if (hasRecords) return card;
    if (viewModel.performanceState.isLoading ||
        viewModel.performanceState.hasError ||
        !viewModel.performanceState.hasData) {
      return card;
    }
    return _emptyCard(
      context,
      l10n.analyticsNewBestPerformances,
      l10n.statisticsEmptyRecords,
      () => const PRDashboardScreen(),
      chipText: l10n.statisticsOverview30Days,
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
                builder: (_) => const MuscleGroupAnalyticsScreen(
                  initialBlock: TimeframeBlock.threeMonths,
                ),
              ),
            );
          },
        ),
      ),
    );
    final hasVolumeData =
        (viewModel.volumeMusclesState.data?.muscleAnalytics['muscles'] as List?)
            ?.isNotEmpty ??
        false;
    if (hasVolumeData) return card;
    if (viewModel.volumeMusclesState.isLoading ||
        viewModel.volumeMusclesState.hasError ||
        !viewModel.volumeMusclesState.hasData) {
      return card;
    }
    return _emptyCard(
      context,
      l10n.analyticsMuscleGroups,
      l10n.statisticsEmptyMuscles,
      () => const MuscleGroupAnalyticsScreen(
        initialBlock: TimeframeBlock.threeMonths,
      ),
      chipText: l10n.analyticsLastWeeks(8),
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
          rangeLabel: l10n.statisticsOverview30Days,
          onRetry: () => viewModel.loadHubAnalytics(),
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => BodyMetricsSectionCard(
                  state: viewModel.bodyNutritionState,
                  rangeLabel: l10n.statisticsOverview30Days,
                  onRetry: () {},
                  onTap: () {},
                ),
                onSourceVisibilityChanged: setHidden,
                builder: (_) => BodyNutritionCorrelationScreen(
                  initialBlock: TimeframeBlock.month,
                  initialAnchorDate: viewModel.anchorDate,
                  initialIsRolling: true,
                ),
              ),
            );
          },
        ),
      ),
    );
    final bodyNutrition = viewModel.bodyNutritionState.data;
    final hasBodyData = bodyNutrition?.hasAnyData ?? false;
    if (hasBodyData) return card;
    if (viewModel.bodyNutritionState.isLoading ||
        viewModel.bodyNutritionState.hasError ||
        !viewModel.bodyNutritionState.hasData) {
      return card;
    }
    return _emptyCard(
      context,
      l10n.sectionBodyNutrition,
      l10n.statisticsEmptyBody,
      () => BodyNutritionCorrelationScreen(
        initialBlock: TimeframeBlock.month,
        initialAnchorDate: DateTime.now(),
        initialIsRolling: true,
      ),
      chipText: l10n.statisticsOverview30Days,
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
          refreshToken: overviewRefreshToken,
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
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final unitService = context.watch<UnitService>();
    final weightKg = viewModel.bodyNutrition?.currentWeightKg;
    final changeKg = viewModel.bodyNutrition?.weightChangeKg;
    final weightUnit = unitService.suffixFor(UnitDimension.weight);
    final weightText = weightKg == null
        ? null
        : '${unitService.convertDisplayValue(weightKg, UnitDimension.weight).toStringAsFixed(1)} $weightUnit';
    final changeText = changeKg == null
        ? null
        : '${changeKg >= 0 ? '+' : '-'}${unitService.convertDisplayValue(changeKg.abs(), UnitDimension.weight).toStringAsFixed(1)} $weightUnit (${l10n.statisticsOverview30Days})';

    Widget buildShortcutContent() => Padding(
      padding: const EdgeInsets.all(DesignConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsCardBase.buildHeaderWithChevron(
            context,
            label: l10n.body_measurements,
            chipText: weightText != null ? l10n.statisticsOverview30Days : null,
          ),
          if (weightText != null) ...[
            const SizedBox(height: DesignConstants.spacingXS),
            Text(
              weightText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              changeText ?? l10n.all_measurements_no_cap,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ] else ...[
            const SizedBox(height: DesignConstants.spacingXS),
            Text(
              l10n.all_measurements_no_cap,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );

    return MorphSourceScope(
      builder: (context, setHidden) => Builder(
        builder: (cardCtx) => SummaryCard(
          key: const Key('statistics_measurements_link_card'),
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          onTap: () {
            Navigator.of(context).push(
              CardMorphRoute(
                sourceContext: cardCtx,
                sourceBuilder: (_) => SummaryCard(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  child: buildShortcutContent(),
                ),
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
