import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../domain/steps_models.dart';
import 'steps_bar_chart.dart';
import 'steps_period_summary.dart';

class StepsWeekChart extends StatelessWidget {
  const StepsWeekChart({
    super.key,
    required this.data,
    required this.dailyGoal,
  });

  final WeekStepsAggregation? data;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final buckets = data?.dailyTotals ?? const [];
    final goalDays = buckets
        .where((bucket) => bucket.steps >= dailyGoal)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepsPeriodSummary(
          total: data?.totalSteps ?? 0,
          firstMetric: ValueSummaryCard(
            value: numberFormat.format(data?.averageDailySteps.round() ?? 0),
            label: l10n.stepsModuleAvgPerDay,
          ),
          secondMetric: ValueSummaryCard(
            value: '$goalDays/${DateTime.daysPerWeek}',
            label: l10n.stepsModuleGoalDays,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXL),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            '${l10n.goalTargetLabel} · ${numberFormat.format(dailyGoal)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        StepsBarChart(buckets: buckets, dailyGoal: dailyGoal),
      ],
    );
  }
}
