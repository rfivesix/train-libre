import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../domain/steps_models.dart';
import 'steps_period_summary.dart';

class StepsMonthChart extends StatelessWidget {
  const StepsMonthChart({
    super.key,
    required this.data,
    required this.anchorDate,
    required this.dailyGoal,
  });

  final MonthStepsAggregation? data;
  final DateTime anchorDate;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final weekdayFormat = DateFormat.E(locale);
    final dateFormat = DateFormat.yMMMMEEEEd(locale);
    final buckets = data?.dailyTotals ?? const [];
    final monthStart =
        data?.monthStart ?? DateTime(anchorDate.year, anchorDate.month);
    final daysInMonth = DateUtils.getDaysInMonth(
      monthStart.year,
      monthStart.month,
    );
    final leadingEmpty = monthStart.weekday - DateTime.monday;
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = DateTime(2024, 1, 1);
    final total = data?.totalSteps ?? 0;
    final byDay = {
      for (final bucket in buckets) bucket.start.day: bucket.steps,
    };
    final goalDays = buckets
        .where((bucket) => bucket.steps >= dailyGoal)
        .length;
    const cellSpacing = 6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepsPeriodSummary(
          total: total,
          firstMetric: ValueSummaryCard(
            value: numberFormat.format((total / daysInMonth).round()),
            label: l10n.stepsModuleAvgPerDay,
          ),
          secondMetric: ValueSummaryCard(
            value: '$goalDays/$daysInMonth',
            label: l10n.stepsModuleGoalDays,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingXL),
        Row(
          spacing: cellSpacing,
          children: [
            for (var index = 0; index < DateTime.daysPerWeek; index++)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      weekdayFormat.format(
                        DateUtils.addDaysToDate(monday, index),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingS),
        GridView.builder(
          itemCount: leadingEmpty + daysInMonth,
          primary: false,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DateTime.daysPerWeek,
            mainAxisSpacing: cellSpacing,
            crossAxisSpacing: cellSpacing,
            mainAxisExtent: 44,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty) return const SizedBox.shrink();

            final day = index - leadingEmpty + 1;
            final date = DateTime(monthStart.year, monthStart.month, day);
            final steps = byDay[day] ?? 0;
            final isToday = date == today;
            final isFuture = date.isAfter(today);
            final background = isFuture
                ? Colors.transparent
                : Color.lerp(
                    theme.cardColor,
                    colors.primary,
                    (steps / dailyGoal).clamp(0.0, 1.0),
                  )!;
            final foreground = switch ((isFuture, steps == 0)) {
              (true, _) => colors.onSurfaceVariant.withValues(alpha: 0.72),
              (false, true) => colors.onSurface,
              _ =>
                background.computeLuminance() > 0.179
                    ? Colors.black
                    : Colors.white,
            };

            final cell = DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(
                  DesignConstants.borderRadiusS,
                ),
                border: isToday
                    ? Border.all(color: colors.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  numberFormat.format(day),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            );
            if (isFuture) {
              return Semantics(
                label: dateFormat.format(date),
                excludeSemantics: true,
                child: cell,
              );
            }
            return Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message:
                  '${dateFormat.format(date)} · ${numberFormat.format(steps)}',
              child: cell,
            );
          },
        ),
      ],
    );
  }
}
