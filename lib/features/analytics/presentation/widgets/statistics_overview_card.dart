import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/database_helper.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../../util/design_constants.dart';
import '../../../statistics/data/macro_analytics_data_adapter.dart';
import '../../../workout/data/sources/workout_local_data_source.dart';

class StatisticsOverviewCard extends StatefulWidget {
  const StatisticsOverviewCard({super.key, required this.refreshToken});
  final int refreshToken;

  @override
  State<StatisticsOverviewCard> createState() => _StatisticsOverviewCardState();
}

class _StatisticsOverviewCardState extends State<StatisticsOverviewCard> {
  late Future<_Overview> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant StatisticsOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) _future = _load();
  }

  Future<_Overview> _load() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 29);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final range = DateTimeRange(start: start, end: end);
    final results = await Future.wait<Object>([
      WorkoutLocalDataSource.instance.getOverviewTotals(now),
      const MacroAnalyticsDataAdapter().fetchSummary(range: range),
      DatabaseHelper.instance.getChartDataForTypeAndRange('weight', range),
    ]);
    final workouts =
        results[0]
            as ({
              int workouts,
              int recentWorkouts,
              DateTime? firstWorkout,
              int sets,
              int seconds,
              double volume,
            });
    final nutrition = results[1] as MacroPeriodSummary;
    final weights = results[2] as List;
    weights.sort((a, b) => a.date.compareTo(b.date));
    return _Overview(
      workouts,
      nutrition,
      weights.length < 2
          ? null
          : (weights.last.value as double) - (weights.first.value as double),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final units = context.watch<UnitService>();
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    return FutureBuilder<_Overview>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        String weight(double value, {int digits = 0}) =>
            '${units.formatDisplayWeight(value, fractionDigits: digits)} ${units.suffixFor(UnitDimension.weight)}';
        final delta = data.weightChange;
        Widget row(Widget left, Widget right) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(child: right),
            ],
          ),
        );
        return Column(
          children: [
            row(
              ValueSummaryCard(
                label: l10n.statisticsOverviewWorkouts,
                value: number.format(data.workouts.workouts),
                subtitle: data.workouts.firstWorkout == null
                    ? null
                    : l10n.statisticsOverviewSince(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).toString(),
                        ).format(data.workouts.firstWorkout!),
                      ),
              ),
              ValueSummaryCard(
                label: l10n.statisticsOverviewWorkouts,
                value: number.format(data.workouts.recentWorkouts),
                subtitle: l10n.statisticsOverview30Days,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            row(
              ValueSummaryCard(
                label: l10n.statisticsOverviewVolume,
                value: weight(data.workouts.volume),
                subtitle:
                    '${number.format(data.workouts.sets)} ${l10n.statisticsOverviewSets} · ${NumberFormat.decimalPatternDigits(locale: Localizations.localeOf(context).toString(), decimalDigits: 1).format(data.workouts.seconds / 3600)} h',
              ),
              ValueSummaryCard(
                label: l10n.statisticsOverviewWeightChange,
                value: delta == null
                    ? '—'
                    : '${delta > 0 ? '+' : ''}${weight(delta, digits: 1)}',
                subtitle: l10n.statisticsOverview30Days,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            row(
              ValueSummaryCard(
                label: l10n.statisticsOverviewCalories,
                value: data.nutrition.trackedDays == 0
                    ? '—'
                    : '${number.format(data.nutrition.avgCalories)} kcal',
                subtitle: l10n.statisticsOverview30Days,
              ),
              ValueSummaryCard(
                label: l10n.statisticsOverviewProtein,
                value: data.nutrition.trackedDays == 0
                    ? '—'
                    : '${number.format(data.nutrition.avgProtein.round())} g',
                subtitle: l10n.statisticsOverview30Days,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Overview {
  const _Overview(this.workouts, this.nutrition, this.weightChange);
  final ({
    int workouts,
    int recentWorkouts,
    DateTime? firstWorkout,
    int sets,
    int seconds,
    double volume,
  })
  workouts;
  final MacroPeriodSummary nutrition;
  final double? weightChange;
}
