import 'dart:math' as math;

import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// A GitHub-style activity heatmap adapting its week columns and cell sizing
/// to [startDate]..[endDate], colored with the active theme's primary color.
class TrainingHeatmap extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, int> dayCounts;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDayTap;
  final bool showLabels;
  final double? maxCellSize;
  final AlignmentGeometry alignment;

  const TrainingHeatmap({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.dayCounts,
    this.onDayTap,
    this.selectedDay,
    this.showLabels = true,
    this.maxCellSize,
    this.alignment = Alignment.center,
  });

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Alpha intensity levels matching the training legend (0, 1, 2, 3+).
  static double alphaForCount(int count) {
    return switch (count) {
      <= 0 => 0.0,
      1 => 0.35,
      2 => 0.65,
      _ => 1.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final textDirection = Directionality.of(context);
    final rangeStart = _normalize(startDate);
    final rangeEnd = _normalize(endDate).isBefore(rangeStart)
        ? rangeStart
        : _normalize(endDate);

    // Align columns to Monday..Sunday weeks.
    final gridStart = rangeStart.subtract(
      Duration(days: rangeStart.weekday - 1),
    );
    final gridEnd = rangeEnd.add(Duration(days: 7 - rangeEnd.weekday));
    final totalDays = gridEnd.difference(gridStart).inDays + 1;
    final weekCount = math.max(1, totalDays ~/ 7);

    // 2024-01-01 is a Monday.
    final weekdayNames = [
      for (var row = 0; row < 7; row++)
        _shortWeekday(DateTime(2024, 1, 1 + row), locale),
    ];

    final labelStyle = (theme.textTheme.labelSmall ?? const TextStyle())
        .copyWith(
          fontSize: 10,
          height: 1.0,
          color: theme.colorScheme.onSurfaceVariant,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double labelGap = showLabels ? 6.0 : 0.0;
        final double weekdayColWidth = showLabels
            ? _maxLabelWidth(weekdayNames, labelStyle, textDirection)
            : 0.0;

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final availableGridWidth = math.max(
          48.0,
          availableWidth - weekdayColWidth - labelGap,
        );

        final double gap;
        final double defaultMaxCell;
        if (weekCount <= 8) {
          gap = showLabels ? 5.0 : 2.5;
          defaultMaxCell = 36.0;
        } else if (weekCount <= 16) {
          gap = showLabels ? 3.5 : 2.0;
          defaultMaxCell = 26.0;
        } else if (weekCount <= 30) {
          gap = showLabels ? 2.5 : 1.5;
          defaultMaxCell = 16.0;
        } else {
          gap = 1.2;
          defaultMaxCell = 12.0;
        }

        final effectiveMaxCell = maxCellSize ?? defaultMaxCell;
        final rawCell = (availableGridWidth - (weekCount - 1) * gap) / weekCount;
        final cellSize = rawCell.clamp(3.5, effectiveMaxCell);
        final gridWidth = weekCount * cellSize + (weekCount - 1) * gap;
        final gridHeight = 7 * cellSize + 6 * gap;
        final cellRadius = (cellSize * 0.24).clamp(1.5, 4.5);

        final rowPitch = cellSize + gap;
        final List<int> visibleWeekdayRows;
        if (!showLabels) {
          visibleWeekdayRows = const [];
        } else if (rowPitch >= 14.0) {
          visibleWeekdayRows = const [0, 1, 2, 3, 4, 5, 6];
        } else if (rowPitch >= 9.0) {
          visibleWeekdayRows = const [0, 2, 4, 6];
        } else {
          visibleWeekdayRows = const [0, 2, 4];
        }

        final monthLabels = showLabels
            ? _computeMonthLabels(
                gridStart: gridStart,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                weekCount: weekCount,
                cellSize: cellSize,
                gap: gap,
                gridWidth: gridWidth,
                locale: locale,
                style: labelStyle,
                textDirection: textDirection,
              )
            : const <({double x, String label})>[];

        final gridPaint = CustomPaint(
          size: Size(gridWidth, gridHeight),
          painter: _HeatmapGridPainter(
            gridStart: gridStart,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            weekCount: weekCount,
            cellSize: cellSize,
            gap: gap,
            cellRadius: cellRadius,
            dayCounts: dayCounts,
            selectedDay: selectedDay == null ? null : _normalize(selectedDay!),
            primaryColor: theme.colorScheme.primary,
            emptyColor: theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.08 : 0.07,
            ),
            selectionBorderColor: theme.colorScheme.onSurface,
          ),
        );

        final interactiveGrid = onDayTap == null
            ? gridPaint
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final step = cellSize + gap;
                  final col = (details.localPosition.dx / step)
                      .floor()
                      .clamp(0, weekCount - 1);
                  final row = (details.localPosition.dy / step)
                      .floor()
                      .clamp(0, 6);
                  final tapped = gridStart.add(Duration(days: col * 7 + row));
                  if (!tapped.isBefore(rangeStart) &&
                      !tapped.isAfter(rangeEnd)) {
                    onDayTap!(tapped);
                  }
                },
                child: gridPaint,
              );

        final content = SizedBox(
          width: weekdayColWidth + labelGap + gridWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabels) ...[
                // Month header row aligned above the first week of each month.
                Padding(
                  padding: EdgeInsets.only(left: weekdayColWidth + labelGap),
                  child: SizedBox(
                    width: gridWidth,
                    height: 15,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final m in monthLabels)
                          Positioned(
                            left: m.x,
                            top: 0,
                            child: Text(
                              m.label,
                              style: labelStyle,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLabels) ...[
                    SizedBox(
                      width: weekdayColWidth,
                      height: gridHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final row in visibleWeekdayRows)
                            Positioned(
                              right: 0,
                              top: (row * rowPitch + cellSize / 2 - 5).clamp(
                                0.0,
                                math.max(0.0, gridHeight - 10),
                              ),
                              child: Text(
                                weekdayNames[row],
                                style: labelStyle,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: labelGap),
                  ],
                  interactiveGrid,
                ],
              ),
            ],
          ),
        );

        final totalContentWidth = weekdayColWidth + labelGap + gridWidth;
        if (totalContentWidth > availableWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        }

        return Align(
          alignment: alignment,
          child: content,
        );
      },
    );
  }

  static String _shortWeekday(DateTime date, String locale) {
    final raw = DateFormat.E(locale).format(date);
    return raw.replaceAll('.', '');
  }

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

  static double _maxLabelWidth(
    List<String> labels,
    TextStyle style,
    TextDirection direction,
  ) {
    var maxW = 0.0;
    for (final label in labels) {
      final w = _measureTextWidth(label, style, direction);
      if (w > maxW) maxW = w;
    }
    return maxW.ceilToDouble();
  }

  static List<({double x, String label})> _computeMonthLabels({
    required DateTime gridStart,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required int weekCount,
    required double cellSize,
    required double gap,
    required double gridWidth,
    required String locale,
    required TextStyle style,
    required TextDirection textDirection,
  }) {
    final candidates = <({int col, double x, double width, String label})>[];
    int? lastMonth;

    for (var col = 0; col < weekCount; col++) {
      final weekMonday = gridStart.add(Duration(days: col * 7));
      DateTime? anchorDay;

      if (col == 0) {
        // First visible column: anchor to its first in-range day unless the
        // next month begins inside this very same week (Mon..Sun).
        for (var row = 0; row < 7; row++) {
          final d = weekMonday.add(Duration(days: row));
          if (d.isBefore(rangeStart) || d.isAfter(rangeEnd)) continue;
          anchorDay ??= d;
        }
      } else if (!weekMonday.isBefore(rangeStart) &&
          !weekMonday.isAfter(rangeEnd) &&
          weekMonday.day <= 7) {
        // Standard GitHub rule: place month label above the first full week
        // whose Monday belongs to that month.
        anchorDay = weekMonday;
      }

      if (anchorDay == null) continue;

      final monthKey = anchorDay.year * 12 + anchorDay.month;
      if (lastMonth != monthKey) {
        final x = col * (cellSize + gap);
        final label = DateFormat.MMM(
          locale,
        ).format(anchorDay).replaceAll('.', '');
        final width = _measureTextWidth(label, style, textDirection);
        if (x + width <= gridWidth + 4) {
          candidates.add((col: col, x: x, width: width, label: label));
        }
        lastMonth = monthKey;
      }
    }

    if (candidates.isEmpty) return const [];

    const minVisualGap = 6.0;
    // If col 0's partial-month label collides with the first full month label
    // right beside it, drop col 0 so the full month label takes precedence.
    if (candidates.length >= 2 &&
        candidates[0].col == 0 &&
        candidates[0].x + candidates[0].width + minVisualGap > candidates[1].x) {
      candidates.removeAt(0);
    }

    final result = <({double x, String label})>[];
    var lastEndX = -100.0;
    for (final c in candidates) {
      if (result.isEmpty || c.x >= lastEndX + minVisualGap) {
        result.add((x: c.x, label: c.label));
        lastEndX = c.x + c.width;
      }
    }
    return result;
  }
}

class _HeatmapGridPainter extends CustomPainter {
  final DateTime gridStart;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int weekCount;
  final double cellSize;
  final double gap;
  final double cellRadius;
  final Map<DateTime, int> dayCounts;
  final DateTime? selectedDay;
  final Color primaryColor;
  final Color emptyColor;
  final Color selectionBorderColor;

  _HeatmapGridPainter({
    required this.gridStart,
    required this.rangeStart,
    required this.rangeEnd,
    required this.weekCount,
    required this.cellSize,
    required this.gap,
    required this.cellRadius,
    required this.dayCounts,
    required this.selectedDay,
    required this.primaryColor,
    required this.emptyColor,
    required this.selectionBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final radius = Radius.circular(cellRadius);
    final step = cellSize + gap;

    for (var col = 0; col < weekCount; col++) {
      for (var row = 0; row < 7; row++) {
        final day = gridStart.add(Duration(days: col * 7 + row));
        if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) continue;

        final count = dayCounts[day] ?? 0;
        final alpha = TrainingHeatmap.alphaForCount(count);
        fillPaint.color = count <= 0
            ? emptyColor
            : primaryColor.withValues(alpha: alpha);

        final rect = Rect.fromLTWH(col * step, row * step, cellSize, cellSize);
        final rrect = RRect.fromRectAndRadius(rect, radius);
        canvas.drawRRect(rrect, fillPaint);

        if (selectedDay != null &&
            day.year == selectedDay!.year &&
            day.month == selectedDay!.month &&
            day.day == selectedDay!.day) {
          final strokePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cellSize >= 10 ? 1.5 : 1.0
            ..color = selectionBorderColor;
          canvas.drawRRect(rrect, strokePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapGridPainter oldDelegate) {
    return oldDelegate.gridStart != gridStart ||
        oldDelegate.rangeStart != rangeStart ||
        oldDelegate.rangeEnd != rangeEnd ||
        oldDelegate.weekCount != weekCount ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.gap != gap ||
        oldDelegate.dayCounts != dayCounts ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.selectionBorderColor != selectionBorderColor;
  }
}
