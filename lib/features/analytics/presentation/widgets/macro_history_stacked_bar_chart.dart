// lib/features/analytics/presentation/widgets/macro_history_stacked_bar_chart.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class _MacroHistoryStackedBarChartState
    extends State<MacroHistoryStackedBarChart> {
  // X position of the current touch (in the bar-row's local coordinate space)
  double? _touchX;
  // Whether the user is actively pressing (long-press/pan active)
  bool _isPressing = false;

  int _indexFromX(double x, double totalWidth) {
    if (widget.dailyIntakes.isEmpty || totalWidth <= 0) return -1;
    final barWidth = totalWidth / widget.dailyIntakes.length;
    final index = (x / barWidth).floor();
    return index.clamp(0, widget.dailyIntakes.length - 1);
  }

  void _handleDragStart(DragStartDetails details, double totalWidth) {
    final index = _indexFromX(details.localPosition.dx, totalWidth);
    if (index < 0) return;
    setState(() {
      _isPressing = true;
      _touchX = details.localPosition.dx;
    });
    widget.onDaySelected?.call(widget.dailyIntakes[index]);
  }

  void _handleDragUpdate(DragUpdateDetails details, double totalWidth) {
    if (!_isPressing) return;
    final index = _indexFromX(details.localPosition.dx, totalWidth);
    if (index < 0) return;
    setState(() => _touchX = details.localPosition.dx);
    final newDay = widget.dailyIntakes[index];
    if (widget.selectedDay == null ||
        newDay.date.day != widget.selectedDay!.date.day ||
        newDay.date.month != widget.selectedDay!.date.month) {
      widget.onDaySelected?.call(newDay);
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
    final macroColors = theme.extension<MacroColors>();

    final proteinColor = macroColors?.protein ?? Colors.red;
    final carbsColor = macroColors?.carbs ?? Colors.green.shade400;
    final fatColor = macroColors?.fat ?? Colors.purple.shade300;

    // Calculate maximum calories to scale chart
    int maxDailyKcal = 0;
    for (final day in widget.dailyIntakes) {
      if (day.calories > maxDailyKcal) {
        maxDailyKcal = day.calories;
      }
    }

    // Determine grid ceiling (multiples of 500, minimum 2000)
    final gridCeiling = max(2000, ((maxDailyKcal * 1.15) / 500).ceil() * 500);
    final midKcal = (gridCeiling / 2).round();

    final bool showDetails =
        widget.is7Days ?? (widget.dailyIntakes.length <= 7);

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
                    lineColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.08),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ),

              // Bars — wrapped in a LayoutBuilder so we know the exact pixel width
              Positioned(
                left: 0,
                right: 32,
                top: 8,
                bottom: 20,
                child: widget.dailyIntakes.isEmpty
                    ? Center(
                        child: Text(
                          'Keine Daten',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : LayoutBuilder(builder: (context, constraints) {
                        final barsWidth = constraints.maxWidth;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          // Long-press starts the scrub
                          onLongPressStart: (d) => _handleDragStart(
                            DragStartDetails(
                              globalPosition: d.globalPosition,
                              localPosition: d.localPosition,
                            ),
                            barsWidth,
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
                            );
                          },
                          onLongPressEnd: (_) => _handleDragEnd(),
                          onLongPressCancel: _handleDragEnd,
                          // Tap toggles a single day and stores touch X for the chip
                          onTapUp: (d) {
                            if (widget.onDaySelected == null) return;
                            final idx = _indexFromX(
                                d.localPosition.dx, barsWidth);
                            if (idx < 0) return;
                            final tapped = widget.dailyIntakes[idx];
                            final isSame = widget.selectedDay != null &&
                                widget.selectedDay!.date.day ==
                                    tapped.date.day &&
                                widget.selectedDay!.date.month ==
                                    tapped.date.month;
                            if (isSame) {
                              // Deselect: clear position and notify null
                              setState(() => _touchX = null);
                              widget.onDaySelected?.call(null);
                            } else {
                              // Select: store X so chip appears at correct position
                              setState(() => _touchX = d.localPosition.dx);
                              widget.onDaySelected?.call(tapped);
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(
                                widget.dailyIntakes.length, (index) {
                              final item = widget.dailyIntakes[index];
                              final isSelected = widget.selectedDay != null &&
                                  widget.selectedDay!.date.year ==
                                      item.date.year &&
                                  widget.selectedDay!.date.month ==
                                      item.date.month &&
                                  widget.selectedDay!.date.day == item.date.day;
                              final isOtherSelected =
                                  widget.selectedDay != null && !isSelected;

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: showDetails
                                        ? 3.0
                                        : (widget.dailyIntakes.length <= 31
                                            ? 1.5
                                            : 0.5),
                                  ),
                                  child: AnimatedOpacity(
                                    duration:
                                        const Duration(milliseconds: 120),
                                    opacity: isOtherSelected ? 0.35 : 1.0,
                                    child: _buildStackedBar(
                                      context,
                                      item: item,
                                      maxKcal: gridCeiling,
                                      proteinColor: proteinColor,
                                      carbsColor: carbsColor,
                                      fatColor: fatColor,
                                      showDetails: showDetails,
                                      isSelected: isSelected,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
              ),

              // Floating date chip — shown whenever a day is selected (tap or press-hold)
              if (_touchX != null && widget.selectedDay != null)
                _buildFloatingDateLabel(
                  context,
                  theme: theme,
                  touchX: _touchX!,
                  day: widget.selectedDay!,
                ),

              // Bottom X-Axis date labels
              Positioned(
                left: 0,
                right: 32,
                bottom: 0,
                child: _buildXAxisLabels(context, showDetails: showDetails),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Renders a small floating date chip positioned above the touched bar.
  Widget _buildFloatingDateLabel(
    BuildContext context, {
    required ThemeData theme,
    required double touchX,
    required DailyMacroIntake day,
  }) {
    final locale = Localizations.localeOf(context).toString();
    final label = widget.dailyIntakes.length <= 7
        ? DateFormat.MMMEd(locale).format(day.date)
        : DateFormat.MMMd(locale).format(day.date);

    const chipWidth = 80.0;
    const chipHeight = 20.0;
    // Keep chip away from the y-axis area on the right
    const safeRightPad = 32.0;

    // Clamp: touchX is in the bars' coordinate space (0 → width - 32 approx)
    // We don't know exact width here, so we allow negative left and let Flutter
    // clip it — but we do at least ensure it doesn't go below 0.
    final rawLeft = touchX - chipWidth / 2;
    final clampedLeft = rawLeft.clamp(0.0, double.infinity);
    // Avoid overlapping y-axis: push left if chip would overflow to the right.
    // We use a MediaQuery-based estimate; exact clamping done via IgnorePointer.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxLeft = screenWidth - safeRightPad - chipWidth;
    final finalLeft = clampedLeft.clamp(0.0, maxLeft);

    return Positioned(
      left: finalLeft,
      top: 10,
      child: IgnorePointer(
        child: Container(
          width: chipWidth,
          height: chipHeight,
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
              borderRadius: BorderRadius.circular(2),
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
                        borderRadius: BorderRadius.circular(showDetails ? 5 : 3),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      )
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    showDetails ? (isSelected ? 3.5 : 4) : 2,
                  ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 0.5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 0.5),
                          child: showDetails && item.carbsGrams >= 5
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${item.carbsGrams.round()}C',
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
          final raw = DateFormat.E(locale).format(d.date).replaceAll('.', '').trim();
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

    // For longer periods, show 4-5 evenly distributed dates
    final count = min(5, widget.dailyIntakes.length);
    final step = (widget.dailyIntakes.length - 1) / (count - 1);
    final labels = <Widget>[];

    for (int i = 0; i < count; i++) {
      final index = (i * step).round().clamp(0, widget.dailyIntakes.length - 1);
      final date = widget.dailyIntakes[index].date;
      final label = DateFormat.MMMd(locale).format(date);
      labels.add(
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels,
    );
  }
}

class _MacroGridPainter extends CustomPainter {
  final int gridCeiling;
  final Color lineColor;

  _MacroGridPainter({
    required this.gridCeiling,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double availableHeight = size.height - 20; // reserve space for x labels

    // Top line (ceiling)
    canvas.drawLine(const Offset(0, 8), Offset(size.width - 32, 8), paint);

    // Middle line (50%)
    final midY = 8 + (availableHeight - 8) / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width - 32, midY), paint);

    // Bottom line (0)
    canvas.drawLine(
        Offset(0, availableHeight), Offset(size.width - 32, availableHeight), paint);
  }

  @override
  bool shouldRepaint(covariant _MacroGridPainter oldDelegate) {
    return oldDelegate.gridCeiling != gridCeiling ||
        oldDelegate.lineColor != lineColor;
  }
}
