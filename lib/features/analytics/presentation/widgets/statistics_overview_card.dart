import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../data/database_helper.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../../util/design_constants.dart';
import '../../../statistics/data/macro_analytics_data_adapter.dart';
import '../../../statistics/domain/body_nutrition_analytics_engine.dart';
import '../../../statistics/domain/timeframe_block.dart';
import '../../../statistics/presentation/statistics_formatter.dart';
import '../../../workout/data/sources/workout_local_data_source.dart';
import '../../domain/models/chart_data_point.dart';

class StatisticsOverviewCard extends StatefulWidget {
  const StatisticsOverviewCard({super.key, required this.refreshToken});
  final int refreshToken;

  @override
  State<StatisticsOverviewCard> createState() => _StatisticsOverviewCardState();
}

class _StatisticsOverviewCardState extends State<StatisticsOverviewCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
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
    final bodyRange = TimeframeBlock.month.getRollingBounds();
    final results = await Future.wait<Object>([
      WorkoutLocalDataSource.instance.getOverviewTotals(now),
      const MacroAnalyticsDataAdapter().fetchSummary(range: range),
      DatabaseHelper.instance.getChartDataForTypeAndRange('weight', bodyRange),
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
    final weights = results[2] as List<ChartDataPoint>;
    return _Overview(
      workouts,
      nutrition,
      BodyNutritionAnalyticsEngine.computeWeightChangeKg(
        range: bodyRange,
        weightPoints: weights,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
        if (data == null) {
          return Skeletonizer(
            enabled: true,
            child: Column(
              children: [
                row(
                  ValueSummaryCard(
                    label: l10n.statisticsOverviewTotalWorkouts,
                    value: '42',
                    subtitle: l10n.statisticsOverview30Days,
                  ),
                  ValueSummaryCard(
                    label: l10n.statisticsOverviewWorkouts30d,
                    value: '12',
                    subtitle: l10n.statisticsOverview30Days,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                row(
                  ValueSummaryCard(
                    label: l10n.statisticsOverviewVolume,
                    value: '12.4 t',
                    subtitle: '240 ${l10n.statisticsOverviewSets} · 14.5 h',
                  ),
                  ValueSummaryCard(
                    label: l10n.statisticsOverviewWeightChange,
                    value: '-1.2 kg',
                    subtitle: l10n.statisticsOverview30Days,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                row(
                  ValueSummaryCard(
                    label: l10n.statisticsOverviewCalories,
                    value: '2,400 kcal',
                    subtitle: l10n.statisticsOverview30Days,
                  ),
                  ValueSummaryCard(
                    label: l10n.statisticsOverviewProtein,
                    value: '170 g',
                    subtitle: l10n.statisticsOverview30Days,
                  ),
                ),
              ],
            ),
          );
        }
        final locale = Localizations.localeOf(context).toString();
        String weight(double value, {int digits = 0}) {
          final display = units.convertDisplayValue(
            value,
            UnitDimension.weight,
          );
          if (units.isMetric && display.abs() >= 10000 && digits == 0) {
            final tons = NumberFormat.decimalPatternDigits(
              locale: locale,
              decimalDigits: 1,
            ).format(display / 1000);
            return '$tons t';
          }
          final formatted = digits == 0
              ? NumberFormat.decimalPattern(locale).format(display.round())
              : NumberFormat.decimalPatternDigits(
                  locale: locale,
                  decimalDigits: digits,
                ).format(display);
          return '$formatted ${units.suffixFor(UnitDimension.weight)}';
        }

        final delta = data.weightChange;
        return Column(
          children: [
            row(
              ValueSummaryCard(
                label: l10n.statisticsOverviewTotalWorkouts,
                value: number.format(data.workouts.workouts),
                subtitle: data.workouts.firstWorkout == null
                    ? null
                    : l10n.statisticsOverviewSince(
                        DateFormat.yMMMd(locale)
                            .format(data.workouts.firstWorkout!),
                      ),
              ),
              ValueSummaryCard(
                label: l10n.statisticsOverviewWorkouts30d,
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
                    : StatisticsPresentationFormatter.formatLocalizedWeightChange(
                        delta,
                        units,
                        locale: locale,
                      ),
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
