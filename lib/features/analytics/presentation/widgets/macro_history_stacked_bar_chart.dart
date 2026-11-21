// lib/features/analytics/presentation/widgets/macro_history_stacked_bar_chart.dart

import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../statistics/data/macro_analytics_data_adapter.dart';

/// A stacked bar chart visualizing daily macronutrient distribution and total calories.
///
/// Each vertical bar's height is proportional to total calories.
/// Segments are stacked from bottom to top:
/// - Bottom: Carbohydrates (Green)
/// - Middle: Fat (Pink/Purple)
/// - Top: Protein (Red)
///
/// Supports press-and-hold / drag-to-scrub interaction: while the user's
/// finger is down, the hovered bar is highlighted and [onDaySelected] is
/// called continuously. A date label floats directly above the active bar
/// inside the chart without shifting the surrounding layout.
class MacroHistoryStackedBarChart extends StatefulWidget {
  final List<DailyMacroIntake> dailyIntakes;
  final DateTimeRange range;
  final double chartHeight;
  final bool? is7Days;
  final DailyMacroIntake? selectedDay;
  final ValueChanged<DailyMacroIntake?>? onDaySelected;

  const MacroHistoryStackedBarChart({
    super.key,
    required this.dailyIntakes,
    required this.range,
    this.chartHeight = 220,
    this.is7Days,
    this.selectedDay,
    this.onDaySelected,
  });

  @override
  State<MacroHistoryStackedBarChart> createState() =>
      _MacroHistoryStackedBarChartState();
}

class _MacroChartBar {
  final DateTime startDate;
  final DateTime endDate;
  final DailyMacroIntake intake;

  const _MacroChartBar({
    required this.startDate,
    required this.endDate,
    required this.intake,
  });

  bool get isAggregated =>
      startDate.year != endDate.year ||
      startDate.month != endDate.month ||
      startDate.day != endDate.day;

  bool containsDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }
}

class _MacroHistoryStackedBarChartState
    extends State<MacroHistoryStackedBarChart> {
  static const double _yAxisWidth = 32.0;

  // X position of the current touch (in the bar-row's local coordinate space)
  double? _touchX;
  // Whether the user is actively pressing (long-press/pan active)
  bool _isPressing = false;

  List<_MacroChartBar> _buildDisplayBars(double barsWidth) {
    final intakes = widget.dailyIntakes;
    if (intakes.isEmpty) return const [];

    final maxUnbucketed = max(7, (barsWidth / 3.5).floor().clamp(7, 100));
    if (intakes.length <= maxUnbucketed) {
      return [
        for (final day in intakes)
          _MacroChartBar(startDate: day.date, endDate: day.date, intake: day),
      ];
    }

    final targetBuckets = max(12, (barsWidth / 6.0).floor().clamp(12, 75));
    final step = max(2, (intakes.length / targetBuckets).ceil());
    final buckets = <_MacroChartBar>[];

    for (int i = 0; i < intakes.length; i += step) {
      final chunk = intakes.sublist(i, min(i + step, intakes.length));
      int cals = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;
      int tracked = 0;
      int targetSum = 0;
      int targetCount = 0;

      for (final day in chunk) {
        cals += day.calories;
        protein += day.proteinGrams;
        carbs += day.carbsGrams;
        fat += day.fatGrams;
        if (day.hasData) tracked++;
        if (day.targetCalories != null && day.targetCalories! > 0) {
          targetSum += day.targetCalories!;
          targetCount++;
        }
      }

      final divisor = tracked > 0 ? tracked : chunk.length;
      buckets.add(
        _MacroChartBar(
          startDate: chunk.first.date,
          endDate: chunk.last.date,
          intake: DailyMacroIntake(
            date: chunk.first.date,
            calories: (cals / divisor).round(),
            proteinGrams: protein / divisor,
            carbsGrams: carbs / divisor,
            fatGrams: fat / divisor,
            targetCalories: targetCount > 0 ? (targetSum / targetCount).round() : null,
          ),
        ),
      );
    }

    return buckets;
  }

  int _indexFromX(double x, double totalWidth, int barCount) {
    if (barCount <= 0 || totalWidth <= 0) return -1;
    final barWidth = totalWidth / barCount;
    final index = (x / barWidth).floor();
    return index.clamp(0, barCount - 1);
  }

  void _handleDragStart(
    DragStartDetails details,
    double totalWidth,
    List<_MacroChartBar> displayBars,
  ) {
    final index = _indexFromX(
      details.localPosition.dx,
      totalWidth,
      displayBars.length,
    );
    if (index < 0) return;
    setState(() {
      _isPressing = true;
      _touchX = details.localPosition.dx;
    });
    widget.onDaySelected?.call(displayBars[index].intake);
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    double totalWidth,
    List<_MacroChartBar> displayBars,
  ) {
    if (!_isPressing) return;
    final index = _indexFromX(
      details.localPosition.dx,
      totalWidth,
      displayBars.length,
    );
    if (index < 0) return;
    setState(() => _touchX = details.localPosition.dx);
    final newBar = displayBars[index];
    if (widget.selectedDay == null ||
        !newBar.containsDate(widget.selectedDay!.date)) {
      widget.onDaySelected?.call(newBar.intake);
    }
  }

  void _handleDragEnd() {
    setState(() {
      _isPressing = false;
      _touchX = null;
    });
    widget.onDaySelected?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final macroColors = theme.extension<MacroColors>();

    final proteinColor = macroColors?.protein ?? Colors.red;
    final carbsColor = macroColors?.carbs ?? Colors.green.shade400;
    final fatColor = macroColors?.fat ?? Colors.purple.shade300;

    final bool showDetails =
        widget.is7Days ?? (widget.dailyIntakes.length <= 7);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final barsWidth = max(1.0, totalWidth - _yAxisWidth);
        final displayBars = _buildDisplayBars(barsWidth);

        // Calculate maximum calories from rendered bars (and active targets) so bar heights and Y-axis match
        int maxBarKcal = 0;
        for (final bar in displayBars) {
          if (bar.intake.calories > maxBarKcal) {
            maxBarKcal = bar.intake.calories;
          }
          final target = bar.intake.targetCalories ?? 0;
          if (target > maxBarKcal) {
            maxBarKcal = target;
          }
        }

        // Determine grid ceiling (multiples of 500, minimum 2000)
        final gridCeiling = max(2000, ((maxBarKcal * 1.15) / 500).ceil() * 500);
        final midKcal = (gridCeiling / 2).round();

        final slotWidth = displayBars.isNotEmpty
            ? barsWidth / displayBars.length
            : barsWidth;
        final desiredHorizontalPad = showDetails
            ? 3.0
            : (displayBars.length <= 31 ? 1.5 : 0.5);
        final horizontalPad = min(desiredHorizontalPad, slotWidth * 0.2);
        final barWidth = max(1.0, slotWidth - horizontalPad * 2);

        _MacroChartBar? activeBar;
        if (_touchX != null && widget.selectedDay != null) {
          for (final bar in displayBars) {
            if (bar.containsDate(widget.selectedDay!.date)) {
              activeBar = bar;
              break;
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: widget.chartHeight,
              child: Stack(
                children: [
                  // Background Grid Lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MacroGridPainter(
                        gridCeiling: gridCeiling,
                        lineColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                  ),
                  // Y-Axis labels on the right
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      '$gridCeiling',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: (widget.chartHeight - 24) / 2,
                    child: Text(
                      '$midKcal',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 20,
                    child: Text(
                      '0',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ),

                  // Bars
                  Positioned(
                    left: 0,
                    right: _yAxisWidth,
                    top: 8,
                    bottom: 20,
                    child: displayBars.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noData,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            // Long-press starts the scrub
                            onLongPressStart: (d) => _handleDragStart(
                              DragStartDetails(
                                globalPosition: d.globalPosition,
                                localPosition: d.localPosition,
                              ),
                              barsWidth,
                              displayBars,
                            ),
                            onLongPressMoveUpdate: (d) {
                              if (!_isPressing) return;
                              _handleDragUpdate(
                                DragUpdateDetails(
                                  globalPosition: d.globalPosition,
                                  localPosition: d.localPosition,
                                  delta: Offset.zero,
                                ),
                                barsWidth,
                                displayBars,
                              );
                            },
                            onLongPressEnd: (_) => _handleDragEnd(),
                            onLongPressCancel: _handleDragEnd,
                            // Tap toggles a single bar and stores touch X for the chip
                            onTapUp: (d) {
                              if (widget.onDaySelected == null) return;
                              final idx = _indexFromX(
                                d.localPosition.dx,
                                barsWidth,
                                displayBars.length,
                              );
                              if (idx < 0) return;
                              final tapped = displayBars[idx];
                              final isSame =
                                  widget.selectedDay != null &&
                                  tapped.containsDate(widget.selectedDay!.date);
                              if (isSame) {
                                // Deselect: clear position and notify null
                                setState(() => _touchX = null);
                                widget.onDaySelected?.call(null);
                              } else {
                                // Select: store X so chip appears at correct position
                                setState(() => _touchX = d.localPosition.dx);
                                widget.onDaySelected?.call(tapped.intake);
                              }
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                displayBars.length,
                                (index) {
                                  final bar = displayBars[index];
                                  final isSelected =
                                      widget.selectedDay != null &&
                                      bar.containsDate(
                                        widget.selectedDay!.date,
                                      );
                                  final isOtherSelected =
                                      widget.selectedDay != null && !isSelected;

                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: horizontalPad,
                                      ),
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 120,
                                        ),
                                        opacity: isOtherSelected ? 0.35 : 1.0,
                                        child: _buildStackedBar(
                                          context,
                                          item: bar.intake,
                                          maxKcal: gridCeiling,
                                          barWidth: barWidth,
                                          proteinColor: proteinColor,
                                          carbsColor: carbsColor,
                                          fatColor: fatColor,
                                          showDetails: showDetails,
                                          isSelected: isSelected,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),

                  // Floating date chip — shown whenever a bar is selected (tap or press-hold)
                  if (_touchX != null && activeBar != null)
                    _buildFloatingDateLabel(
                      context,
                      theme: theme,
                      touchX: _touchX!,
                      barsWidth: barsWidth,
                      bar: activeBar,
                    ),

                  // Bottom X-Axis date labels
                  Positioned(
                    left: 0,
                    right: _yAxisWidth,
                    bottom: 0,
                    child: _buildXAxisLabels(context, showDetails: showDetails),
                  ),

                  // Dashed Calorie Target Line (follows historical targets per bar)
                  if (displayBars.any((b) => (b.intake.targetCalories ?? 0) > 0))
                    Positioned(
                      left: 0,
                      right: _yAxisWidth,
                      top: 8,
                      bottom: 20,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _MacroTargetLinePainter(
                            targets: displayBars
                                .map((b) => b.intake.targetCalories)
                                .toList(growable: false),
                            gridCeiling: gridCeiling,
                            lineColor: (macroColors?.calories ?? Colors.orange)
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Renders a small floating date chip positioned above the touched bar.
  Widget _buildFloatingDateLabel(
    BuildContext context, {
    required ThemeData theme,
    required double touchX,
    required double barsWidth,
    required _MacroChartBar bar,
  }) {
    final locale = Localizations.localeOf(context).toString();
    final String label;
    if (bar.isAggregated) {
      final fmt = bar.startDate.year != bar.endDate.year
          ? DateFormat.yMMMd(locale)
          : DateFormat.MMMd(locale);
      label = '${fmt.format(bar.startDate)} – ${fmt.format(bar.endDate)}';
    } else {
      label = widget.dailyIntakes.length <= 7
          ? DateFormat.MMMEd(locale).format(bar.startDate)
          : DateFormat.MMMd(locale).format(bar.startDate);
    }

    final double chipWidth = min(
      barsWidth,
      bar.isAggregated ? 140.0 : 80.0,
    );
    const chipHeight = 20.0;

    final maxLeft = max(0.0, barsWidth - chipWidth);
    final finalLeft = (touchX - chipWidth / 2).clamp(0.0, maxLeft);

    return Positioned(
      left: finalLeft,
      top: 10,
      child: IgnorePointer(
        child: Container(
          width: chipWidth,
          height: chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onInverseSurface,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStackedBar(
    BuildContext context, {
    required DailyMacroIntake item,
    required int maxKcal,
    required double barWidth,
    required Color proteinColor,
    required Color carbsColor,
    required Color fatColor,
    required bool showDetails,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    if (item.calories <= 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showDetails || isSelected) ...[
            Text(
              '--',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(min(2.0, barWidth / 2)),
            ),
          ),
        ],
      );
    }

    final totalRatio = (item.calories / maxKcal).clamp(0.02, 1.0);

    // Compute caloric split: Carbs = 4 kcal/g, Protein = 4 kcal/g, Fat = 9 kcal/g
    final carbsKcal = max(0.0, item.carbsGrams * 4);
    final proteinKcal = max(0.0, item.proteinGrams * 4);
    final fatKcal = max(0.0, item.fatGrams * 9);
    final totalMacroKcal = carbsKcal + proteinKcal + fatKcal;

    final carbsFlex = totalMacroKcal > 0
        ? max(1, (carbsKcal / totalMacroKcal * 100).round())
        : 33;
    final fatFlex = totalMacroKcal > 0
        ? max(1, (fatKcal / totalMacroKcal * 100).round())
        : 33;
    final proteinFlex = totalMacroKcal > 0
        ? max(1, (proteinKcal / totalMacroKcal * 100).round())
        : 34;

    final selectionBorderWidth = min(1.5, barWidth * 0.25);
    final barRadius = min(
      showDetails ? (isSelected ? 3.5 : 4.0) : 2.0,
      barWidth / 2,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final barHeight = max(
          showDetails ? 24.0 : 4.0,
          availableHeight * totalRatio,
        );

        return Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: barHeight,
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          min(showDetails ? 5.0 : 3.0, barWidth / 2),
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: selectionBorderWidth,
                        ),
                      )
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barRadius),
                  child: Column(
                    children: [
                      // Top: Protein
                      Expanded(
                        flex: proteinFlex,
                        child: Container(
                          color: proteinColor,
                          alignment: Alignment.center,
                          child: showDetails && item.proteinGrams >= 5
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${item.proteinGrams.round()}P',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Middle: Fat
                      Expanded(
                        flex: fatFlex,
                        child: Container(
                          color: fatColor,
                          alignment: Alignment.center,
                          padding: showDetails
                              ? const EdgeInsets.symmetric(horizontal: 0.5)
                              : EdgeInsets.zero,
                          child: showDetails && item.fatGrams >= 5
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${item.fatGrams.round()}F',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Bottom: Carbs
                      Expanded(
                        flex: carbsFlex,
                        child: Container(
                          color: carbsColor,
                          alignment: Alignment.center,
                          padding: showDetails
                              ? const EdgeInsets.symmetric(horizontal: 0.5)
                              : EdgeInsets.zero,
                          child: showDetails && item.carbsGrams >= 5
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${item.carbsGrams.round()}${_carbsShortLetter(context)}',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildXAxisLabels(BuildContext context, {required bool showDetails}) {
    if (widget.dailyIntakes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    // If 7 days, show each day abbreviation
    if (showDetails) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: widget.dailyIntakes.map((d) {
          final raw = DateFormat.E(locale)
              .format(d.date)
              .replaceAll('.', '')
              .trim();
          final label = raw.length > 2 ? raw.substring(0, 2) : raw;
          return Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          );
        }).toList(),
      );
    }

    final firstDate = widget.dailyIntakes.first.date;
    final lastDate = widget.dailyIntakes.last.date;
    final spansMultipleYears = lastDate.difference(firstDate).inDays > 366;
    final dateFmt = spansMultipleYears
        ? DateFormat.yMMM(locale)
        : DateFormat.MMMd(locale);

    // For longer periods, show 4-5 evenly distributed dates
    final maxLabels = spansMultipleYears ? 4 : 5;
    final count = min(maxLabels, widget.dailyIntakes.length);
    if (count == 1) {
      return Text(
        dateFmt.format(firstDate),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 10,
        ),
      );
    }

    final step = (widget.dailyIntakes.length - 1) / (count - 1);
    final labels = <Widget>[];

    for (int i = 0; i < count; i++) {
      final index = (i * step).round().clamp(0, widget.dailyIntakes.length - 1);
      final date = widget.dailyIntakes[index].date;
      final label = dateFmt.format(date);
      labels.add(
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 4,
              right: i == count - 1 ? 0 : 4,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels,
    );
  }
  String _carbsShortLetter(BuildContext context) =>
      switch (Localizations.localeOf(context).languageCode) {
        'de' || 'nl' => 'KH',
        'es' => 'HC',
        _ => 'C',
      };
}

class _MacroTargetLinePainter extends CustomPainter {
  final List<int?> targets;
  final int gridCeiling;
  final Color lineColor;

  const _MacroTargetLinePainter({
    required this.targets,
    required this.gridCeiling,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targets.isEmpty || gridCeiling <= 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final slotWidth = size.width / targets.length;
    final path = Path();
    bool hasCurrentSegment = false;
    double? lastY;

    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      if (target == null || target <= 0) {
        hasCurrentSegment = false;
        lastY = null;
        continue;
      }

      final ratio = (target / gridCeiling).clamp(0.0, 1.0);
      final y = size.height * (1.0 - ratio);
      final xStart = i * slotWidth;
      final xEnd = (i + 1) * slotWidth;

      if (!hasCurrentSegment) {
        path.moveTo(xStart, y);
        hasCurrentSegment = true;
      } else if (lastY != null && (lastY - y).abs() > 0.5) {
        path.lineTo(xStart, lastY);
        path.lineTo(xStart, y);
      }
      path.lineTo(xEnd, y);
      lastY = y;
    }

    const dashWidth = 5.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MacroTargetLinePainter oldDelegate) {
    if (oldDelegate.gridCeiling != gridCeiling ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.targets.length != targets.length) {
      return true;
    }
    for (var i = 0; i < targets.length; i++) {
      if (oldDelegate.targets[i] != targets[i]) return true;
    }
    return false;
  }
}

class _MacroGridPainter extends CustomPainter {
  final int gridCeiling;
  final Color lineColor;

  _MacroGridPainter({required this.gridCeiling, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double availableHeight =
        size.height - 20; // reserve space for x labels

    // Top line (ceiling)
    canvas.drawLine(const Offset(0, 8), Offset(size.width - 32, 8), paint);

    // Middle line (50%)
    final midY = 8 + (availableHeight - 8) / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width - 32, midY), paint);

    // Bottom line (0)
    canvas.drawLine(
      Offset(0, availableHeight),
      Offset(size.width - 32, availableHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MacroGridPainter oldDelegate) {
    return oldDelegate.gridCeiling != gridCeiling ||
        oldDelegate.lineColor != lineColor;
  }
}
