import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../data/repository/sleep_query_repository.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../../domain/sleep_enums.dart';
import '../details/sleep_data_unavailable_card.dart';
import '../sleep_navigation.dart';
import '../widgets/sleep_period_scope_layout.dart';

const _sleepOverviewSectionSpacing = DesignConstants.spacingM;

class SleepMonthOverviewPage extends StatefulWidget {
  const SleepMonthOverviewPage({
    super.key,
    required this.anchorDay,
    required this.repository,
  });

  final DateTime anchorDay;
  final SleepQueryRepository repository;

  @override
  State<SleepMonthOverviewPage> createState() => _SleepMonthOverviewPageState();
}

class _SleepMonthOverviewPageState extends State<SleepMonthOverviewPage> {
  late DateTime _anchorDay;
  late final SleepQueryRepository _repository;
  MonthSleepAggregation? _aggregation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _anchorDay = DateTime(
      widget.anchorDay.year,
      widget.anchorDay.month,
      widget.anchorDay.day,
    );
    _repository = widget.repository;
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SleepPeriodScopeLayout(
      appBarTitle: l10n.sleepSectionTitle,
      selectedScope: SleepPeriodScope.month,
      anchorDate: _anchorDay,
      onScopeChanged: _onScopeChanged,
      onShiftPeriod: _shiftPeriod,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonthSummaryCard(aggregation: _aggregation!),
                const SizedBox(height: _sleepOverviewSectionSpacing),
                MonthCalendarGrid(
                  aggregation: _aggregation!,
                  onTapDay: (day) =>
                      SleepNavigation.openDayForDate(context, day),
                ),
                if (_aggregation!.days.every((day) => day.score == null)) ...[
                  const SizedBox(height: _sleepOverviewSectionSpacing),
                  SleepDataUnavailableCard(
                    message: l10n.sleepMonthNoScoredNights,
                    margin: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _loadMonth() async {
    setState(() => _isLoading = true);
    try {
      final monthStart = DateTime(_anchorDay.year, _anchorDay.month, 1);
      final monthEnd = DateTime(_anchorDay.year, _anchorDay.month + 1, 0);
      final analyses = await _repository.getAnalysesInRange(
        fromInclusive: monthStart,
        toInclusive: monthEnd,
      );
      final aggregation = const SleepPeriodAggregationEngine().aggregateMonth(
        monthStart: monthStart,
        analyses: analyses,
      );
      if (!mounted) return;
      setState(() {
        _aggregation = aggregation;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('SleepMonthOverviewPage: failed to load month: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onScopeChanged(SleepPeriodScope scope) async {
    if (scope == SleepPeriodScope.day) {
      await SleepNavigation.openDayForDate(context, _anchorDay, replace: true);
      return;
    }
    if (scope == SleepPeriodScope.week) {
      await SleepNavigation.openWeekForDate(context, _anchorDay, replace: true);
      return;
    }
  }

  void _shiftPeriod(int direction) {
    setState(() {
      _anchorDay = DateTime(_anchorDay.year, _anchorDay.month + direction, 1);
    });
    _loadMonth();
  }
}

class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({super.key, required this.aggregation});

  final MonthSleepAggregation aggregation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String formatDuration(Duration? value) {
      if (value == null) return '--';
      final h = value.inHours;
      final m = value.inMinutes.remainder(60);
      return '${h}h ${m}m';
    }

    final mean = aggregation.meanScore == null
        ? '--'
        : aggregation.meanScore!.toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.cardPaddingInternal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ValueSummaryCard(
                  value: mean,
                  label: l10n.sleepMeanScoreLabel(''),
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: ValueSummaryCard(
                  value: formatDuration(aggregation.weekdayAverageDuration),
                  label: l10n.sleepWeekdayAvgDurationLabel(''),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Row(
            children: [
              Expanded(
                child: ValueSummaryCard(
                  value: formatDuration(aggregation.weekendAverageDuration),
                  label: l10n.sleepWeekendAvgDurationLabel(''),
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class MonthCalendarGrid extends StatelessWidget {
  const MonthCalendarGrid({
    super.key,
    required this.aggregation,
    required this.onTapDay,
  });

  final MonthSleepAggregation aggregation;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = aggregation.days;
    final firstWeekdayOffset = aggregation.monthStart.weekday - DateTime.monday;
    final padded = <SleepDayAggregate?>[
      for (var i = 0; i < firstWeekdayOffset; i++) null,
      ...days,
    ];
    final remainder = padded.length % 7;
    if (remainder != 0) {
      padded.addAll(List<SleepDayAggregate?>.filled(7 - remainder, null));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.cardPaddingInternal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sleepMonthDailyScoreStatesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: padded.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final day = padded[index];
              if (day == null) {
                return const SizedBox.shrink();
              }
              return InkWell(
                onTap: () => onTapDay(day.date),
                borderRadius: BorderRadius.circular(
                  DesignConstants.borderRadiusS,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _chipColor(context, day.sleepQuality),
                    borderRadius: BorderRadius.circular(
                      DesignConstants.borderRadiusS,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.date.day}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface,
                        ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _chipColor(BuildContext context, SleepQualityBucket quality) {
    final scheme = Theme.of(context).colorScheme;
    return switch (quality) {
      SleepQualityBucket.good => Colors.green.shade300,
      SleepQualityBucket.average => Colors.amber.shade300,
      SleepQualityBucket.poor => Theme.of(context).colorScheme.error,
      SleepQualityBucket.unavailable => scheme.surfaceContainerHighest,
    };
  }
}
