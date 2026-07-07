import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../statistics/domain/analytics_state.dart';
import '../../statistics/domain/consistency_domain_service.dart';
import '../../statistics/domain/consistency_payload_models.dart';
import '../../statistics/domain/statistics_range_policy.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import 'widgets/analytics_chart_defaults.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/common.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';

enum _ConsistencyMetric { volume, duration, frequency }

class ConsistencyTrackerScreen extends StatefulWidget {
  const ConsistencyTrackerScreen({super.key});

  @override
  State<ConsistencyTrackerScreen> createState() =>
      _ConsistencyTrackerScreenState();
}

class _ConsistencyTrackerScreenState extends State<ConsistencyTrackerScreen> {
  static const int _weeklyWindowWeeks = 12;
  final _rangePolicy = StatisticsRangePolicyService.instance;
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
    final weeklyRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.consistencyWeeklyMetrics,
    );
    final calendarRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.consistencyCalendar,
    );

    final stats = WorkoutLocalDataSource.instance.getTrainingStats();
    final weekly = WorkoutLocalDataSource.instance.getWeeklyConsistencyMetrics(
      weeksBack: weeklyRange.effectiveWeeks ?? _weeklyWindowWeeks,
    );
    final dayCounts = WorkoutLocalDataSource.instance.getWorkoutDayCounts(
      daysBack: calendarRange.effectiveDays ?? 120,
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

    final thisWeek = _trainingStats.thisWeekCount;
    final avgPerWeek = _trainingStats.avgPerWeek;
    final streak = _trainingStats.streakWeeks;
    final total = _trainingStats.totalWorkouts;
    final trainingDaysPerWeek =
        ConsistencyDomainService.computeTrainingDaysPerWeekLast4(
      workoutDayCounts: _workoutDayCounts,
    );
    final rhythmDelta = ConsistencyDomainService.computeRhythmDelta(
      weeklyMetrics: _weeklyMetrics,
    );
    final rollingConsistency =
        ConsistencyDomainService.rollingConsistencyPercent(
      weeklyMetrics: _weeklyMetrics,
    );
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.consistencyTrackerTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.screenPadding.copyWith(
                top: DesignConstants.screenPadding.top + topPadding,
                bottom: DesignConstants.bottomContentSpacer,
              ),
              child: Column(
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
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ValueSummaryCard(
                                label: l10n.analyticsRollingConsistency,
                                value:
                                    '${rollingConsistency.toStringAsFixed(0)}%',
                                subtitle: l10n.analyticsWeeksAtLeast2Workouts,
                              ),
                            ),
                            const SizedBox(width: DesignConstants.spacingS),
                            Expanded(
                              child: ValueSummaryCard(
                                label: l10n.analyticsTrainingDaysPerWeek,
                                value:
                                    trainingDaysPerWeek.toStringAsFixed(1),
                                subtitle: l10n.analyticsLast4Weeks,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                                value: ConsistencyDomainService.formatTrend(
                                    rhythmDelta),
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
                        '$_weeklyWindowWeeks ${l10n.weeksLabel}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingXS),
                  RepaintBoundary(
                    child: SizedBox(
                      height: 210,
                      child: _weeklyMetrics.isEmpty
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
                                borderData:
                                    AnalyticsChartDefaults.noBorder,
                                gridData:
                                    AnalyticsChartDefaults.themeAwareCompactGrid(context),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    tooltipBorderRadius:
                                        BorderRadius.circular(16),
                                    tooltipMargin: 12,
                                    tooltipPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    getTooltipColor: (_) {
                                      final isDark =
                                          Theme.of(context).brightness ==
                                              Brightness.dark;
                                      return isDark
                                          ? const Color(0xFF2A2A2A)
                                          : Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withValues(alpha: 0.95);
                                    },
                                    tooltipBorder: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.08),
                                    ),
                                    getTooltipItem: (group, groupIndex,
                                        rod, rodIndex) {
                                      final i = group.x.toInt();
                                      if (i < 0 ||
                                          i >= _weeklyMetrics.length) {
                                        return null;
                                      }
                                      final row = _weeklyMetrics[i];
                                      return BarTooltipItem(
                                        '${row.weekLabel}\n${rod.toY.toStringAsFixed(1)} ${_metricUnit(l10n)}',
                                        Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ) ??
                                            TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData:
                                    AnalyticsChartDefaults.standardTitles(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) =>
                                          AnalyticsChartDefaults
                                              .tickLabel(
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
                                        if (i < 0 ||
                                            i >= _weeklyMetrics.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final label =
                                            _weeklyMetrics[i].weekLabel;
                                        return AnalyticsChartDefaults
                                            .tickLabel(
                                          context,
                                          label,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: _weeklyMetrics
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final value = _metricValue(
                                    entry.value,
                                  );
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: value,
                                        width: 12,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(
                                              alpha: _weeklyBarAlpha(
                                                index: entry.key,
                                                total:
                                                    _weeklyMetrics.length,
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
                    'X: ${l10n.analyticsViewWeek.toLowerCase()} · $_weeklyWindowWeeks ${l10n.weeksLabel}',
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
                        firstDay: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDay: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            _selectedDay != null &&
                            isSameDay(_selectedDay, day),
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
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold) ??
                              const TextStyle(
                                  fontWeight: FontWeight.bold),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle:
                              Theme.of(context).textTheme.bodySmall ??
                                  const TextStyle(),
                        ),
                        calendarBuilders: CalendarBuilders<int>(
                          defaultBuilder: (context, day, _) {
                            final count = _dailyCount(day);
                            if (count <= 0) return null;
                            final intensity = _calendarIntensityForCount(
                              count,
                            );
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
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall,
                              ),
                            );
                          },
                          markerBuilder: (context, day, events) {
                            final count = _dailyCount(day);
                            if (count <= 0) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              bottom: 3,
                              child: Text(
                                count.toString(),
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall,
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

  double _calendarIntensityForCount(int count) {
    return (0.18 + (count * 0.14)).clamp(0.18, 0.65);
  }

  double _weeklyBarAlpha({required int index, required int total}) {
    const minAlpha = 0.35;
    const maxAlpha = 1.0;
    if (total <= 0) return minAlpha;
    final ratio = (index + 1) / total;
    return (minAlpha + (ratio * (maxAlpha - minAlpha))).clamp(
      minAlpha,
      maxAlpha,
    );
  }
}
