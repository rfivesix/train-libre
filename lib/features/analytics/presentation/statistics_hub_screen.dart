import '../../statistics/domain/timeframe_block.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

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
import '../../pulse/presentation/pulse_analysis_screen.dart';
import '../../../services/health/steps_sync_service.dart';
import 'statistics_hub_view_model.dart';
import '../../../util/timeframe_label_formatter.dart';

// Standalone widget imports
import 'widgets/analytics_card_base.dart';
import 'widgets/body_metrics_section_card.dart';
import 'widgets/consistency_section_card.dart';
import 'widgets/muscle_volume_section_card.dart';
import 'widgets/performance_section_card.dart';
import 'widgets/pulse_section_card.dart';
import 'widgets/recovery_section_card.dart';
import 'widgets/sleep_section_card.dart';

class StatisticsHubScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatisticsHubViewModel>(
      create: (context) => StatisticsHubViewModel(
        hubDataAdapter: _hubDataAdapter,
        stepsRepository: _stepsRepository,
        sleepSummaryRepository: _sleepSummaryRepository,
        pulseRepository: _pulseRepository,
        fetchHubAnalytics: fetchHubAnalytics,
        importSleepIfDue: importSleepIfDue,
        isSleepTrackingEnabled: isSleepTrackingEnabled,
        targetStepsLoader: targetStepsLoader,
        stepsProviderNameLoader: stepsProviderNameLoader ??
            () async {
              final l10n = AppLocalizations.of(context)!;
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
      ),
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
    final appBarHeight = MediaQuery.of(context).padding.top;
    final finalPadding = DesignConstants.cardPadding.copyWith(
      top: DesignConstants.cardPadding.top + appBarHeight + 16,
      left: 0,
      right: 0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: finalPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TimeRangeFilter(
                  ranges: _timeRanges(l10n),
                  selectedIndex: _hubBlocks.indexOf(viewModel.activeBlockType),
                  onSelected: (index) {
                    viewModel.activeBlockType = _hubBlocks[index];
                  },
                  onPrevious:
                      viewModel.activeBlockType == TimeframeBlock.maxBlock
                          ? null
                          : () => viewModel.shiftTimeframe(true),
                  onNext: viewModel.activeBlockType == TimeframeBlock.maxBlock
                      ? null
                      : () => viewModel.shiftTimeframe(false),
                  displayDate: _unifiedRangeLabel(viewModel, l10n),
                  onTapDateDisplay: () async {
                    final selected =
                        await adaptive_pickers.showAdaptiveTimeframePicker(
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
                              .getBounds(viewModel.anchorDate, DateTime(2020))
                              .start
                              .isAtSameMomentAs(viewModel.activeBlockType
                                  .getBounds(DateTime.now(), DateTime(2020))
                                  .start)),
                  showDateNavigation:
                      viewModel.activeBlockType != TimeframeBlock.maxBlock,
                ),
                const SizedBox(height: DesignConstants.spacingL),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.cardPaddingInternal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (viewModel.stepsTrackingEnabled) ...[
                        AppSectionHeader(title: l10n.steps),
                        RepaintBoundary(
                          child: _buildStepsCard(context, viewModel, l10n),
                        ),
                        const SizedBox(height: DesignConstants.spacingL),
                      ],
                      AppSectionHeader(title: l10n.sectionRecovery),
                      RepaintBoundary(
                        child: _buildRecoverySection(context, viewModel, l10n),
                      ),
                      if (viewModel.sleepTrackingEnabled) ...[
                        const SizedBox(height: DesignConstants.spacingS),
                        RepaintBoundary(
                          child: _buildSleepSection(context, viewModel, l10n),
                        ),
                      ],
                      if (viewModel.pulseTrackingEnabled) ...[
                        const SizedBox(height: DesignConstants.spacingS),
                        RepaintBoundary(
                          child: _buildPulseSection(context, viewModel, l10n),
                        ),
                      ],
                      const SizedBox(height: DesignConstants.spacingL),
                      AppSectionHeader(title: l10n.statisticsSectionTraining),
                      RepaintBoundary(
                        child:
                            _buildConsistencySection(context, viewModel, l10n),
                      ),
                      const SizedBox(height: DesignConstants.spacingS),
                      RepaintBoundary(
                        child:
                            _buildPerformanceSection(context, viewModel, l10n),
                      ),
                      const SizedBox(height: DesignConstants.spacingS),
                      RepaintBoundary(
                        child:
                            _buildMuscleVolumeSection(context, viewModel, l10n),
                      ),
                      const SizedBox(height: DesignConstants.spacingL),
                      AppSectionHeader(title: l10n.statisticsSectionBody),
                      RepaintBoundary(
                        child:
                            _buildBodyMetricsSection(context, viewModel, l10n),
                      ),
                      const SizedBox(height: DesignConstants.spacingS),
                      _buildMeasurementsShortcutCard(context, l10n),
                      const BottomContentSpacer(),
                    ],
                  ),
                ),
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
    if (section.isLoading && !section.hasData) {
      return AnalyticsCardBase.buildSectionLoadingCard(
          context, l10n, StatisticsHubSectionId.steps, l10n.steps);
    }
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
    final noDataText = !viewModel.stepsTrackingEnabled
        ? l10n.statisticsEnableStepTrackingHint
        : l10n.statisticsNoStepDataYet;

    // Fallback info if tracking disabled or no data
    if (!viewModel.stepsTrackingEnabled || !hasData) {
      return AnalyticsCardBase.decorateSectionCard(
        context,
        state: section,
        child: SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StepsModuleScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(DesignConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnalyticsCardBase.buildHeaderWithChevron(
                  context,
                  label: stepsTitle,
                  chipText: subtitleRange,
                ),
                const SizedBox(height: DesignConstants.spacingS),
                Text(
                  noDataText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // In 7-day mode we show today's steps; in longer ranges we show total steps.
    final bool isSevenDays = viewModel.activeBlockType.index == 0;

    int currentSteps = 0;
    String stepsSubtitle = l10n.today;

    if (isSevenDays) {
      final todayBucket = range!.dailyTotals.lastWhere(
        (bucket) =>
            bucket.start.isBefore(DateTime.now().add(const Duration(days: 1))),
        orElse: () => range.dailyTotals.last, // fallback
      );
      currentSteps = todayBucket.steps;
    } else {
      currentSteps = range!.totalSteps;
      stepsSubtitle = l10n.statisticsTotalSteps;
    }

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: section,
      child: StatisticsStepsCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StepsModuleScreen()),
          );
        },
        title: stepsTitle,
        chipText: subtitleRange,
        currentSteps: currentSteps,
        currentStepsSubtitle: stepsSubtitle,
        dailyTotals: range.dailyTotals,
        dailyGoal: viewModel.targetSteps,
      ),
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
    return RecoverySectionCard(
      state: viewModel.recoveryState,
      chipText: null, // As requested, no pill for Recovery
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecoveryTrackerScreen()),
        );
      },
    );
  }

  Widget _buildSleepSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return SleepSectionCard(
      state: viewModel.sleepState,
      rangeLabel: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () => SleepNavigation.openDay(context),
    );
  }

  Widget _buildPulseSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final rangeLabel = _unifiedRangeLabel(viewModel, l10n);
    return PulseSectionCard(
      state: viewModel.pulseState,
      fallbackRangeLabel: rangeLabel ?? '',
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PulseAnalysisScreen()),
        );
      },
    );
  }

  Widget _buildConsistencySection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return ConsistencySectionCard(
      state: viewModel.consistencyState,
      chipText: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConsistencyTrackerScreen()),
        );
      },
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return PerformanceSectionCard(
      state: viewModel.performanceState,
      chipText: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PRDashboardScreen()),
        );
      },
    );
  }

  Widget _buildMuscleVolumeSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return MuscleVolumeSectionCard(
      state: viewModel.volumeMusclesState,
      rangeLabel: _unifiedRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MuscleGroupAnalyticsScreen()),
        );
      },
    );
  }

  Widget _buildBodyMetricsSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return BodyMetricsSectionCard(
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
