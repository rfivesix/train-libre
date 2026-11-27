import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../domain/steps_models.dart';
import 'steps_bar_chart.dart';
import 'steps_period_summary.dart';

class StepsDayChart extends StatelessWidget {
  const StepsDayChart({super.key, required this.data, required this.dailyGoal});

  final DayStepsAggregation? data;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final timeFormat = DateFormat.Hm(locale);
    final buckets = data?.hourlyBuckets ?? const [];

    final activeHours = buckets.where((bucket) => bucket.steps > 0).length;
    StepsBucket? peak;
    for (final bucket in buckets) {
      if (bucket.steps > (peak?.steps ?? 0)) peak = bucket;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepsPeriodSummary(
          total: data?.totalSteps ?? 0,
          dailyGoal: dailyGoal,
          firstMetric: ValueSummaryCard(
            value: numberFormat.format(activeHours),
            label: l10n.stepsModuleActiveHours,
          ),
          secondMetric: ValueSummaryCard(
            value: peak == null
                ? '–'
                : '${timeFormat.format(peak.start)} · ${numberFormat.format(peak.steps)}',
            label: l10n.stepsModulePeakHour,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXL),
        Text(
          l10n.stepsModuleHourlyTimeline,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        StepsBarChart(buckets: buckets),
      ],
    );
  }
}
