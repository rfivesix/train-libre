import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';

/// Displays a workout's date and time range as matching [SummaryCard] pills,
/// placing the time card flush right on one line when space permits.
class WorkoutDateTimeChips extends StatelessWidget {
  final DateTime startTime;
  final DateTime? endTime;
  final VoidCallback? onDateTap;
  final VoidCallback? onTimeTap;

  const WorkoutDateTimeChips({
    super.key,
    required this.startTime,
    this.endTime,
    this.onDateTap,
    this.onTimeTap,
  });

  static double _measureTextWidth(
    String text,
    TextStyle style,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: direction,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final textDirection = Directionality.of(context);

    final dateText = DateFormat.yMMMEd(locale).format(startTime);
    final startStr = DateFormat.Hm(locale).format(startTime);
    final timeText = endTime != null
        ? '$startStr – ${DateFormat.Hm(locale).format(endTime!)}'
        : startStr;

    final baseStyle = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
    );
    final timeStyle = baseStyle.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final dateCard = _DateTimeSummaryCard(
      label: dateText,
      textStyle: baseStyle,
      onTap: onDateTap,
    );
    final timeCard = _DateTimeSummaryCard(
      label: timeText,
      textStyle: timeStyle,
      onTap: onTimeTap,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Horizontal card padding (spacingM * 2 = 32)
        const cardChromeWidth = DesignConstants.spacingM * 2;
        final dateWidth =
            _measureTextWidth(dateText, baseStyle, textDirection) +
            cardChromeWidth;
        final timeWidth =
            _measureTextWidth(timeText, timeStyle, textDirection) +
            cardChromeWidth;
        final fitsOneLine =
            dateWidth + DesignConstants.spacingS + timeWidth <=
            constraints.maxWidth;

        if (fitsOneLine) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: dateCard),
              const SizedBox(width: DesignConstants.spacingS),
              timeCard,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dateCard,
            const SizedBox(height: DesignConstants.spacingS),
            Align(alignment: Alignment.centerRight, child: timeCard),
          ],
        );
      },
    );
  }
}

class _DateTimeSummaryCard extends StatelessWidget {
  final String label;
  final TextStyle textStyle;
  final VoidCallback? onTap;

  const _DateTimeSummaryCard({
    required this.label,
    required this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingM,
        vertical: DesignConstants.spacingS + 2,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
  }
}
