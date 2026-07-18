import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:fl_chart/fl_chart.dart';
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

enum _ConsistencyMetric { volume, duration, frequency }

class ConsistencyTrackerScreen extends StatefulWidget {
  const ConsistencyTrackerScreen({super.key});

  @override
  State<ConsistencyTrackerScreen> createState() =>
      _ConsistencyTrackerScreenState();
}

class _ConsistencyTrackerScreenState extends State<ConsistencyTrackerScreen> {
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
  Map<DateTime, int> _workoutDayCounts = const {};
  _ConsistencyMetric _selectedMetric = _ConsistencyMetric.volume;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final bounds = _isRolling
        ? _activeBlock.getRollingBounds()
        : _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final daysBack =
        DateTime.now().difference(bounds.start).inDays.clamp(1, 3650);
    final weeksBack = (daysBack / 7).ceil().clamp(1, 1000);

    final stats = WorkoutLocalDataSource.instance.getTrainingStats();
    final weekly = WorkoutLocalDataSource.instance.getWeeklyConsistencyMetrics(
      weeksBack: weeksBack,
    );
    final dayCounts = WorkoutLocalDataSource.instance.getWorkoutDayCounts(
      daysBack: daysBack,
    );

    final results = await Future.wait([stats, weekly, dayCounts]);
    if (!mounted) return;

    setState(() {
      _trainingStats = TrainingStatsPayload.fromMap(
        results[0] as Map<String, dynamic>,
      );
      _weeklyMetrics = (results[1] as List<Map<String, dynamic>>)
          .map(WeeklyConsistencyMetricPayload.fromMap)
          .toList();
      _workoutDayCounts = results[2] as Map<DateTime, int>;
      _isLoading = false;
    });
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _dailyCount(DateTime day) => _workoutDayCounts[_normalize(day)] ?? 0;

  double _metricValue(WeeklyConsistencyMetricPayload row) {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume => row.tonnage,
      _ConsistencyMetric.duration => row.durationMinutes,
      _ConsistencyMetric.frequency => row.count.toDouble(),
    };
  }

  String _metricName(AppLocalizations l10n) {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume => l10n.metricsVolumeLifted,
      _ConsistencyMetric.duration => l10n.durationLabel,
      _ConsistencyMetric.frequency => l10n.workoutsPerWeekLabel,
    };
  }

  String _metricUnit(AppLocalizations l10n) {
    return switch (_selectedMetric) {
      _ConsistencyMetric.volume =>
        context.read<UnitService>().suffixFor(UnitDimension.weight),
      _ConsistencyMetric.duration => 'min',
      _ConsistencyMetric.frequency => l10n.analyticsPerWeekAbbrev,
    };
  }

  String _formatAxisValue(double value) {
    if (_selectedMetric == _ConsistencyMetric.volume) {
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}k';
      }
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final hasNoData = _weeklyMetrics.isEmpty;
    final bounds = _isRolling
        ? _activeBlock.getRollingBounds()
        : _activeBlock.getBounds(_anchorDate, DateTime(2020));
    final displayMetrics = hasNoData ? getMockWeeklyMetrics(bounds) : _weeklyMetrics;
    final displayStats = hasNoData ? getMockTrainingStats() : _trainingStats;


    final trainingDaysPerWeek = hasNoData
        ? 2.5
        : ConsistencyDomainService.computeTrainingDaysPerWeekLast4(
            workoutDayCounts: _workoutDayCounts,
          );
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
      l10n,
    );

    if (hasNoData) {
      bodyContent = ActiveGapOverlay(
        message: "Keine Trainingskonsistenz für diesen Zeitraum",
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
                  _loadData();
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
                  _loadData();
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
                  _loadData();
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
                    _loadData();
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
    Widget item(String label, double alpha) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: alpha),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingXS),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        item('1 ${l10n.workoutsLabel}', _calendarIntensityForCount(1)),
        item('2 ${l10n.workoutsLabel}', _calendarIntensityForCount(2)),
        item('3+ ${l10n.workoutsLabel}', _calendarIntensityForCount(3)),
      ],
    );
  }

  List<WeeklyConsistencyMetricPayload> getMockWeeklyMetrics(DateTimeRange range) {
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
    AppLocalizations l10n,
  ) {
    final thisWeek = stats.thisWeekCount;
    final streak = stats.streakWeeks;
    final avgPerWeek = stats.avgPerWeek;
    final total = stats.totalWorkouts;

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
                      label: l10n.metricsWorkoutsWeek,
                      value: '$thisWeek',
                      subtitle: l10n.thisWeekLabel,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.streakLabel,
                      value: '$streak',
                      subtitle: l10n.weeksLabel,
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
                      subtitle: l10n.analyticsWeeksAtLeast2Workouts,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.analyticsTrainingDaysPerWeek,
                      value: trainingDaysPerWeek.toStringAsFixed(1),
                      subtitle: l10n.analyticsLast4Weeks,
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
                      subtitle: l10n.workoutsPerWeekLabel,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Expanded(
                    child: ValueSummaryCard(
                      label: l10n.analyticsRhythm,
                      value: ConsistencyDomainService.formatTrend(rhythmDelta),
                      subtitle: l10n.analyticsVsPrior4Weeks,
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
          title: '${_metricName(l10n)} · ${l10n.analyticsViewWeek}',
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
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${_metricName(l10n)} (${_metricUnit(l10n)})',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              _isRolling
                  ? TimeframeLabelFormatter.formatRolling(_activeBlock, l10n)
                  : TimeframeLabelFormatter.format(_activeBlock, _anchorDate, l10n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingXS),
        RepaintBoundary(
          child: SizedBox(
            height: 210,
            child: weeklyMetrics.isEmpty
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
                      borderData: AnalyticsChartDefaults.noBorder,
                      gridData: AnalyticsChartDefaults.themeAwareCompactGrid(context),
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
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            return isDark
                                ? const Color(0xFF2A2A2A)
                                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.95);
                          },
                          tooltipBorder: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final i = group.x.toInt();
                            if (i < 0 || i >= weeklyMetrics.length) {
                              return null;
                            }
                            final row = weeklyMetrics[i];
                            return BarTooltipItem(
                              '${row.weekLabel}\n${rod.toY.toStringAsFixed(1)} ${_metricUnit(l10n)}',
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ) ??
                                  TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            );
                          },
                        ),
                      ),
                      titlesData: AnalyticsChartDefaults.standardTitles(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) => AnalyticsChartDefaults.tickLabel(
                              context,
                              _formatAxisValue(value),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= weeklyMetrics.length) {
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
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                              color: Theme.of(context).colorScheme.primary.withValues(
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
        AppSectionHeader(title: l10n.trainingCalendarLabel),
        Text(
          l10n.analyticsCalendarExplainer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: DesignConstants.spacingS),
        _calendarLegend(l10n),
        const SizedBox(height: DesignConstants.spacingS),
        SummaryCard(
          child: RepaintBoundary(
            child: TableCalendar<int>(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay, day),
              eventLoader: (day) {
                final count = _dailyCount(day);
                if (count <= 0) return const [];
                return List<int>.filled(count, 1);
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              ),
              calendarBuilders: CalendarBuilders<int>(
                defaultBuilder: (context, day, _) {
                  final count = _dailyCount(day);
                  if (count <= 0) return null;
                  final intensity = _calendarIntensityForCount(count);
                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: intensity),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
