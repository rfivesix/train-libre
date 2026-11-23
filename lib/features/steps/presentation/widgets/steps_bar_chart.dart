import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';
import '../../domain/steps_models.dart';
import 'horizontal_guide_painter.dart';

/// Displays hourly counts, or daily counts with a goal reference line.
class StepsBarChart extends StatelessWidget {
  const StepsBarChart({super.key, required this.buckets, this.dailyGoal});

  final List<StepsBucket> buckets;
  final int? dailyGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final axisFormat = NumberFormat.compact(locale: locale);
    final goal = dailyGoal;
    final hourly = goal == null;
    final labelFormat = hourly
        ? DateFormat.Hm(locale)
        : DateFormat.EEEE(locale);
    final weekdayFormat = DateFormat.E(locale);
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final axisStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    final peak = buckets.fold(
      goal ?? 0,
      (peak, bucket) => math.max(peak, bucket.steps),
    );
    final scale = switch (peak) {
      >= 4000 => 2000,
      >= 1000 => 1000,
      >= 200 => 200,
      _ => 20,
    };
    final axisMax = (peak ~/ scale + 1) * scale;
    const plotHeight = 144.0;

    return Padding(
      padding: const EdgeInsets.only(top: DesignConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: plotHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FractionalTranslation(
                  translation: const Offset(0, -0.5),
                  child: Text(axisFormat.format(axisMax), style: axisStyle),
                ),
                const Spacer(),
                Text(axisFormat.format(axisMax ~/ 2), style: axisStyle),
                const Spacer(),
                FractionalTranslation(
                  translation: const Offset(0, 0.5),
                  child: Text(axisFormat.format(0), style: axisStyle),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignConstants.spacingS),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: plotHeight,
                  child: CustomPaint(
                    painter: HorizontalGuidePainter(
                      lineColor: colors.outlineVariant.withValues(alpha: 0.5),
                      goalColor: colors.primary,
                      goalRatio: goal == null ? null : goal / axisMax,
                    ),
                    child: Row(
                      children: [
                        for (final bucket in buckets)
                          Expanded(
                            child:
                                hourly ||
                                    !DateUtils.dateOnly(bucket.start)
                                        .isAfter(today)
                                ? Tooltip(
                                    triggerMode: TooltipTriggerMode.tap,
                                    message:
                                        '${labelFormat.format(bucket.start)} · ${numberFormat.format(bucket.steps)}',
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final barWidth = math.min(
                                          constraints.maxWidth *
                                              (hourly ? 0.55 : 0.65),
                                          hourly ? 8.0 : 36.0,
                                        );
                                        final hitGoal =
                                            goal != null &&
                                            bucket.steps >= goal;
                                        return Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            width: barWidth,
                                            height: math.max(
                                              bucket.steps /
                                                  axisMax *
                                                  plotHeight,
                                              bucket.steps > 0 ? 2.0 : 0.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: hourly || hitGoal
                                                  ? colors.primary
                                                  : Color.alphaBlend(
                                                      colors.primary.withValues(
                                                        alpha: 0.46,
                                                      ),
                                                      colors
                                                          .surfaceContainerHighest,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    hourly
                                                        ? 4
                                                        : DesignConstants
                                                              .borderRadiusS,
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingM),
                if (hourly)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final hour in const ['00', '06', '12', '18', '24'])
                        Text(hour, style: axisStyle),
                    ],
                  )
                else
                  Row(
                    children: [
                      for (final bucket in buckets)
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                weekdayFormat.format(bucket.start),
                                style: DateUtils.isSameDay(bucket.start, today)
                                    ? axisStyle?.copyWith(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.bold,
                                      )
                                    : axisStyle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
