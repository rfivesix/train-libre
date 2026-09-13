import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../statistics/domain/analytics_state.dart';
import '../../statistics/domain/consistency_domain_service.dart';
import '../../statistics/domain/consistency_payload_models.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import 'widgets/analytics_chart_defaults.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/seamless_loading_overlay.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/common.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';
import '../../../util/timeframe_label_formatter.dart';
import '../../../widgets/common/platform_adaptive_pickers.dart'
    as adaptive_pickers;
import '../../statistics/domain/timeframe_block.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../services/telemetry/telemetry_service.dart';

enum _ConsistencyMetric { volume, duration, frequency }

class ConsistencyTrackerScreen extends StatefulWidget {
  const ConsistencyTrackerScreen({super.key});

  @override
  State<ConsistencyTrackerScreen> createState() =>
      _ConsistencyTrackerScreenState();
}

class _ConsistencyTrackerScreenState extends State<ConsistencyTrackerScreen> {
  static const int _calendarLookbackDays = 365;

  bool _isRolling = true;
  TimeframeBlock _activeBlock = TimeframeBlock.month;
  DateTime _anchorDate = DateTime.now();

  final List<TimeframeBlock> _validBlocks = const [
    TimeframeBlock.month,
    TimeframeBlock.threeMonths,
    TimeframeBlock.sixMonths,
    TimeframeBlock.year,
  ];

  List<String> _timeRanges(AppLocalizations l10n) => [
        l10n.filter1MonthShort,
        l10n.filter3MonthsShort,
        l10n.filter6MonthsShort,
        l10n.filter1YearShort,
      ];

  bool _isLoading = true;
  TrainingStatsPayload _trainingStats = const TrainingStatsPayload(
    totalWorkouts: 0,
    thisWeekCount: 0,
    avgPerWeek: 0.0,
    streakWeeks: 0,
  );
  List<WeeklyConsistencyMetricPayload> _weeklyMetrics = const [];
  Map<DateTime, int> _timeframeWorkoutDayCounts = const {};
  Map<DateTime, int> _calendarWorkoutDayCounts = const {};
  _ConsistencyMetric _selectedMetric = _ConsistencyMetric.volume;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _timeframeLoadGeneration = 0;
  int _calendarLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(TelemetryService.instance
        .trackScreenView(screenName: ScreenName.consistencyTracker));
    _loadTimeframeData();
    _loadCalendarData();
  }

  Future<void> _loadTimeframeData() async {
    final generation = ++_timeframeLoadGeneration;
    setState(() => _isLoading = true);
    final bounds = _isRolling
        ? _activeBlock.getRollingBounds()
        : _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final untilDate = _isRolling ? DateTime.now() : bounds.end;

    final weeksBack = switch (_activeBlock) {
      TimeframeBlock.month => 4,
      TimeframeBlock.threeMonths => 13,
      TimeframeBlock.sixMonths => 26,
      TimeframeBlock.year => 52,
      _ => 4,
    };

    final daysBack =
        DateTime.now().difference(bounds.start).inDays.clamp(1, 3650);

    final stats = WorkoutLocalDataSource.instance.getTrainingStats();
    final weekly = WorkoutLocalDataSource.instance.getWeeklyConsistencyMetrics(
      weeksBack: weeksBack,
      untilDate: untilDate,
    );
    final dayCounts = WorkoutLocalDataSource.instance.getWorkoutDayCounts(
      daysBack: daysBack,
    );

    final results = await Future.wait([stats, weekly, dayCounts]);
    if (!mounted || generation != _timeframeLoadGeneration) return;

    setState(() {
      _trainingStats = TrainingStatsPayload.fromMap(
        results[0] as Map<String, dynamic>,
      );
      _weeklyMetrics = (results[1] as List<Map<String, dynamic>>)
          .map(WeeklyConsistencyMetricPayload.fromMap)
          .toList();
      _timeframeWorkoutDayCounts = results[2] as Map<DateTime, int>;
      _isLoading = false;
    });
  }

  Future<void> _loadCalendarData() async {
    final generation = ++_calendarLoadGeneration;
    final dayCounts = await WorkoutLocalDataSource.instance.getWorkoutDayCounts(
      daysBack: _calendarLookbackDays,
    );
    if (!mounted || generation != _calendarLoadGeneration) return;

    setState(() => _calendarWorkoutDayCounts = dayCounts);
  }

  int _computeMaxStreak(List<WeeklyConsistencyMetricPayload> weeklyMetrics) {
    int maxStreak = 0;
    int currentStreak = 0;
    for (final m in weeklyMetrics) {
      if (m.count > 0) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    return maxStreak;
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _dailyCount(DateTime day) =>
      _calendarWorkoutDayCounts[_normalize(day)] ?? 0;

  DateTime get _calendarFirstDay {
    final now = _normalize(DateTime.now());
    return now.subtract(const Duration(days: _calendarLookbackDays - 1));
  }

  DateTime get _calendarLastDay => _normalize(DateTime.now());

  double _metricValue(WeeklyConsistencyMetricPayload row) {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume => row.tonnage,
      _ConsistencyMetric.duration => row.durationMinutes,
      _ConsistencyMetric.frequency => row.count.toDouble(),
    };
  }

  String _metricUnit(AppLocalizations l10n) {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume =>
        context.read<UnitService>().suffixFor(UnitDimension.weight),
      _ConsistencyMetric.duration => 'min',
      _ConsistencyMetric.frequency => l10n.workoutsLabel,
    };
  }

  String _formatAxisValue(double value) {
    final roundedValue = value.round();
    if (_selectedMetric == _ConsistencyMetric.volume) {
      if (roundedValue >= 1000) {
        return '${(roundedValue / 1000).round()}k';
      }
      return '$roundedValue';
    }
    return '$roundedValue';
  }

  String _formatWeekRange(
    BuildContext context,
    WeeklyConsistencyMetricPayload row,
  ) {
    final format = DateFormat.Md(Localizations.localeOf(context).toString());
    final start = _normalize(row.weekStart);
    final end = start.add(const Duration(days: 6));
    return '${format.format(start)} – ${format.format(end)}';
  }

  double _chartBarWidth(int numberOfWeeks) {
    if (numberOfWeeks > 26) return 4;
    if (numberOfWeeks > 13) return 7;
    return 12;
  }

  double _chartInterval(List<WeeklyConsistencyMetricPayload> metrics) {
    final maxValue = metrics.fold<double>(
      0,
      (currentMax, metric) => math.max(currentMax, _metricValue(metric)),
    );
    if (maxValue <= 0) return 1;

    final roughInterval = maxValue / 5;
    final magnitude = math.pow(
      10,
      (math.log(roughInterval) / math.ln10).floor(),
    );
    final normalized = roughInterval / magnitude;
    final multiplier = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return (multiplier * magnitude).toDouble();
  }

  double _chartMaxY(
    List<WeeklyConsistencyMetricPayload> metrics,
    double interval,
  ) {
    final maxValue = metrics.fold<double>(
      0,
      (currentMax, metric) => math.max(currentMax, _metricValue(metric)),
    );
    return (maxValue / interval).ceil() * interval;
  }

  double get _yAxisReservedSize {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume => 36,
      _ConsistencyMetric.duration => 30,
      _ConsistencyMetric.frequency => 20,
    };
  }

  Widget _yAxisTick(BuildContext context, double value) {
    return SizedBox(
      width: _yAxisReservedSize,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          _formatAxisValue(value),
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }

  bool _shouldShowWeekLabel({required int index, required int total}) {
    if (total <= 6 || index == 0 || index == total - 1) return true;

    // Keep at most about six labels on compact phone charts. The individual
    // weekly values remain accessible through the bar tooltip.
    final interval = (total / 5).ceil();
    return index % interval == 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final hasNoData = _weeklyMetrics.isEmpty;
    final bounds = _isRolling
        ? _activeBlock.getRollingBounds()
        : _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final displayMetrics =
        hasNoData ? getMockWeeklyMetrics(bounds) : _weeklyMetrics;
    final displayStats = hasNoData ? getMockTrainingStats() : _trainingStats;

    final trainingDaysPerWeek = hasNoData
        ? 2.5
        : (_isRolling
            ? ConsistencyDomainService.computeTrainingDaysPerWeekLast4(
                workoutDayCounts: _timeframeWorkoutDayCounts,
              )
            : ((_timeframeWorkoutDayCounts.entries
                    .where((e) =>
                        (e.key.isAfter(bounds.start) ||
                            e.key.isAtSameMomentAs(bounds.start)) &&
                        (e.key.isBefore(bounds.end) ||
                            e.key.isAtSameMomentAs(bounds.end)) &&
                        e.value > 0)
                    .length) /
                (_weeklyMetrics.isEmpty
                    ? 1.0
                    : _weeklyMetrics.length.toDouble())));

    final rhythmDelta = hasNoData
        ? 0.5
        : ConsistencyDomainService.computeRhythmDelta(
            weeklyMetrics: _weeklyMetrics,
          );

    final rollingConsistency = hasNoData
        ? 80.0
        : ConsistencyDomainService.rollingConsistencyPercent(
            weeklyMetrics: _weeklyMetrics,
          );

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    Widget bodyContent = _buildBodyContent(
      context,
      displayStats,
      displayMetrics,
      trainingDaysPerWeek,
      rhythmDelta,
      rollingConsistency,
      _isRolling,
      l10n,
    );

    if (hasNoData) {
      bodyContent = ActiveGapOverlay(
        message: l10n.emptyStateActiveGapOverlay,
        background: Skeletonizer(
          enabled: true,
          child: IgnorePointer(child: bodyContent),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.consistencyTrackerTitle),
      body: SeamlessLoadingOverlay(
        isLoading: _isLoading,
        isEmpty: false, // Handle empty state at timeframe/content level
        extendBodyBehindAppBar: true,
        child: SingleChildScrollView(
          padding: DesignConstants.screenPadding.copyWith(
            top: DesignConstants.screenPadding.top + topPadding,
            bottom: DesignConstants.bottomContentSpacer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TimeRangeFilter(
                ranges: _timeRanges(l10n),
                selectedIndex: _validBlocks.indexOf(_activeBlock),
                onSelected: (index) {
                  setState(() {
                    _activeBlock = _validBlocks[index];
                    _isRolling = false;
                  });
                  _loadTimeframeData();
                },
                onPrevious: () {
                  setState(() {
                    final currentBounds =
                        _activeBlock.getBounds(DateTime.now(), DateTime(2020));
                    final myBounds =
                        _activeBlock.getBounds(_anchorDate, DateTime(2020));
                    final isOngoing = !_isRolling &&
                        myBounds.start.isAtSameMomentAs(currentBounds.start);

                    if (isOngoing) {
                      _isRolling = true;
                    } else if (_isRolling) {
                      _isRolling = false;
                      _anchorDate = _activeBlock.shift(DateTime.now(), -1);
                    } else {
                      _anchorDate = _activeBlock.shift(_anchorDate, -1);
                    }
                  });
                  _loadTimeframeData();
                },
                onNext: () {
                  setState(() {
                    if (_isRolling) {
                      _isRolling = false;
                      _anchorDate = DateTime.now();
                    } else {
                      final previousAnchor =
                          _activeBlock.shift(DateTime.now(), -1);
                      final previousBounds = _activeBlock.getBounds(
                          previousAnchor, DateTime(2020));
                      final myBounds =
                          _activeBlock.getBounds(_anchorDate, DateTime(2020));
                      final isPreviousToOngoing = !_isRolling &&
                          myBounds.start.isAtSameMomentAs(previousBounds.start);

                      if (isPreviousToOngoing) {
                        _isRolling = true;
                      } else {
                        _anchorDate = _activeBlock.shift(_anchorDate, 1);
                      }
                    }
                  });
                  _loadTimeframeData();
                },
                displayDate: _isRolling
                    ? TimeframeLabelFormatter.formatRolling(_activeBlock, l10n)
                    : TimeframeLabelFormatter.format(
                        _activeBlock, _anchorDate, l10n),
                onTapDateDisplay: () async {
                  final selected =
                      await adaptive_pickers.showAdaptiveTimeframePicker(
                    context: context,
                    activeBlock: _activeBlock,
                    initialAnchor: _anchorDate,
                    earliestAvailableDay: DateTime(2020),
                    initialIsRolling: _isRolling,
                  );
                  if (selected != null) {
                    setState(() {
                      _anchorDate = selected.anchorDate;
                      _isRolling = selected.isRolling;
                    });
                    _loadTimeframeData();
                  }
                },
                nextEnabled: _isRolling
                    ? true
                    : !_activeBlock
                        .getBounds(_anchorDate, DateTime(2020))
                        .start
                        .isAtSameMomentAs(_activeBlock
                            .getBounds(DateTime.now(), DateTime(2020))
                            .start),
              ),
              const SizedBox(height: DesignConstants.spacingM),
              bodyContent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendarLegend(AppLocalizations l10n) {
    Widget item(String count, double alpha) {
      return Tooltip(
        message: '$count ${l10n.workoutsLabel}',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: alpha),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(count, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        item('1', _calendarIntensityForCount(1)),
        const SizedBox(width: 8),
        item('2', _calendarIntensityForCount(2)),
        const SizedBox(width: 8),
        item('3+', _calendarIntensityForCount(3)),
      ],
    );
  }

  List<WeeklyConsistencyMetricPayload> getMockWeeklyMetrics(
      DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    final duration = end.difference(start);
    final weeks = (duration.inDays / 7).ceil().clamp(4, 52);

    return List.generate(weeks, (i) {
      final date = start.add(Duration(days: i * 7));
      return WeeklyConsistencyMetricPayload(
        weekStart: date,
        weekLabel: 'W${i + 1}',
        count: i % 3 + 1,
        durationMinutes: 45.0 + (i % 2) * 15.0,
        tonnage: 1500.0 + i * 200.0,
      );
    });
  }

  TrainingStatsPayload getMockTrainingStats() {
    return const TrainingStatsPayload(
      totalWorkouts: 24,
      thisWeekCount: 3,
      avgPerWeek: 2.5,
      streakWeeks: 4,
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    TrainingStatsPayload stats,
    List<WeeklyConsistencyMetricPayload> weeklyMetrics,
    double trainingDaysPerWeek,
    double rhythmDelta,
    double rollingConsistency,
    bool isRolling,
    AppLocalizations l10n,
  ) {
    // ⚡ Bolt Optimization: Single-pass loop for sum aggregation
    // Replaces `.map().fold()`, preventing intermediate Iterable allocation on every UI render.
    int timeframeTotalWorkouts = 0;
    if (weeklyMetrics.isNotEmpty) {
      for (final metric in weeklyMetrics) {
        timeframeTotalWorkouts += metric.count;
      }
    }
    final total = isRolling ? stats.totalWorkouts : timeframeTotalWorkouts;
    final thisWeek = isRolling ? stats.thisWeekCount : timeframeTotalWorkouts;
    final streak =
        isRolling ? stats.streakWeeks : _computeMaxStreak(weeklyMetrics);
    final avgPerWeek = isRolling
        ? stats.avgPerWeek
        : (weeklyMetrics.isEmpty
            ? 0.0
            : timeframeTotalWorkouts / weeklyMetrics.length.toDouble());

    final timeframeSubtitle = l10n.analyticsInTimeframe;
    final chartInterval = _chartInterval(weeklyMetrics);
    final chartMaxY = _chartMaxY(weeklyMetrics, chartInterval);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.analyticsKpisHeader),
        Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ValueSummaryCard(
                      label: isRolling
                          ? l10n.metricsWorkoutsWeek
                          : l10n.totalWorkoutsLabel,
                      value: '$thisWeek',
                      subtitle:
                          isRolling ? l10n.thisWeekLabel : timeframeSubtitle,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.streakLabel,
                      value: '$streak',
                      subtitle: isRolling ? l10n.weeksLabel : timeframeSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.analyticsRollingConsistency,
                      value: '${rollingConsistency.toStringAsFixed(0)}%',
                      subtitle: isRolling
                          ? l10n.analyticsWeeksAtLeast2Workouts
                          : timeframeSubtitle,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.analyticsTrainingDaysPerWeek,
                      value: trainingDaysPerWeek.toStringAsFixed(1),
                      subtitle: isRolling
                          ? l10n.analyticsLast4Weeks
                          : timeframeSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.avgPerWeekLabel,
                      value: avgPerWeek.toStringAsFixed(1),
                      subtitle: isRolling
                          ? l10n.workoutsPerWeekLabel
                          : timeframeSubtitle,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.analyticsRhythm,
                      value: ConsistencyDomainService.formatTrend(rhythmDelta),
                      subtitle: isRolling
                          ? l10n.analyticsVsPrior4Weeks
                          : timeframeSubtitle,
                      valueColor: rhythmDelta > 0
                          ? Theme.of(context).colorScheme.primary
                          : rhythmDelta < 0
                              ? Theme.of(context).colorScheme.error
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingM),
        AppSectionHeader(
          title: l10n.consistencyTrackerTitle,
        ),
        PlatformAdaptiveDropdownFormField<_ConsistencyMetric>(
          value: _selectedMetric,
          onChanged: (val) {
            if (val != null) setState(() => _selectedMetric = val);
          },
          items: [
            DropdownMenuItem(
              value: _ConsistencyMetric.volume,
              child: Text(l10n.metricsVolumeLifted),
            ),
            DropdownMenuItem(
              value: _ConsistencyMetric.duration,
              child: Text(l10n.durationLabel),
            ),
            DropdownMenuItem(
              value: _ConsistencyMetric.frequency,
              child: Text(l10n.workoutsPerWeekLabel),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingS),
        RepaintBoundary(
          child: SizedBox(
            height: 210,
            child: (weeklyMetrics.isEmpty ||
                    weeklyMetrics.every((m) => _metricValue(m) <= 0))
                ? AnalyticsChartDefaults.stateView(
                    context: context,
                    l10n: l10n,
                    status: AnalyticsStatus.empty,
                    emptyLabel: l10n.noWorkoutDataLabel,
                    height: 210,
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      minY: 0,
                      maxY: chartMaxY,
                      borderData: AnalyticsChartDefaults.noBorder,
                      gridData:
                          AnalyticsChartDefaults.themeAwareCompactGrid(context),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipBorderRadius: BorderRadius.circular(16),
                          tooltipMargin: 12,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          getTooltipColor: (_) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            return isDark
                                ? DesignConstants.summaryCardDarkMode
                                : DesignConstants.summaryCardSecondaryLightMode;
                          },
                          tooltipBorder: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.08),
                          ),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final i = group.x.toInt();
                            if (i < 0 || i >= weeklyMetrics.length) {
                              return null;
                            }
                            final row = weeklyMetrics[i];
                            return BarTooltipItem(
                              '${_formatWeekRange(context, row)}\n${rod.toY.round()} ${_metricUnit(l10n)}',
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.w600,
                                      ) ??
                                  TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            );
                          },
                        ),
                      ),
                      titlesData: AnalyticsChartDefaults.standardTitles(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: chartInterval,
                            reservedSize: _yAxisReservedSize,
                            getTitlesWidget: (value, meta) =>
                                _yAxisTick(context, value),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 ||
                                  i >= weeklyMetrics.length ||
                                  !_shouldShowWeekLabel(
                                    index: i,
                                    total: weeklyMetrics.length,
                                  )) {
                                return const SizedBox.shrink();
                              }
                              final label = weeklyMetrics[i].weekLabel;
                              return AnalyticsChartDefaults.tickLabel(
                                context,
                                label,
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: weeklyMetrics.asMap().entries.map((entry) {
                        final value = _metricValue(entry.value);
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              width: _chartBarWidth(weeklyMetrics.length),
                              borderRadius: BorderRadius.circular(4),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(
                                    alpha: _weeklyBarAlpha(
                                      index: entry.key,
                                      total: weeklyMetrics.length,
                                    ),
                                  ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'X: ${l10n.analyticsViewWeek.toLowerCase()} · ${_isRolling ? TimeframeLabelFormatter.formatRolling(_activeBlock, l10n) : TimeframeLabelFormatter.format(_activeBlock, _anchorDate, l10n)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        AppSectionHeader(
          title: l10n.trainingCalendarLabel,
          action: _calendarLegend(l10n),
        ),
        Text(
          l10n.analyticsCalendarExplainer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: DesignConstants.spacingS),
        SummaryCard(
          child: RepaintBoundary(
            child: TableCalendar<int>(
              firstDay: _calendarFirstDay,
              lastDay: _calendarLastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null && isSameDay(_selectedDay, day),
              eventLoader: (day) {
                final count = _dailyCount(day);
                if (count <= 0) return const [];
                return List<int>.filled(count, 1);
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold) ??
                    const TextStyle(fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle:
                    Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              ),
              calendarBuilders: CalendarBuilders<int>(
                defaultBuilder: (context, day, _) {
                  final count = _dailyCount(day);
                  if (count <= 0) return null;
                  final intensity = _calendarIntensityForCount(count);
                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: intensity),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
                markerBuilder: (context, day, events) {
                  final count = _dailyCount(day);
                  if (count <= 0) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 3,
                    child: Text(
                      count.toString(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        Text(
          _selectedDay == null
              ? l10n.analyticsSelectDayPrompt
              : l10n.analyticsSelectedDayWorkouts(
                  '${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year}',
                  _dailyCount(_selectedDay!),
                ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.analyticsTotalSessions,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$total',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  double _calendarIntensityForCount(int count) {
    return switch (count) {
      <= 0 => 0.0,
      1 => 0.35,
      2 => 0.65,
      _ => 1.0,
    };
  }

  double _weeklyBarAlpha({required int index, required int total}) {
    if (total <= 1) return 1.0;
    final fraction = index / (total - 1);
    return 0.45 + fraction * 0.55;
  }
}
