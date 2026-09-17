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
class MacroHistoryStackedBarChart extends StatelessWidget {
  final List<DailyMacroIntake> dailyIntakes;
  final DateTimeRange range;
  final double chartHeight;

  const MacroHistoryStackedBarChart({
    super.key,
    required this.dailyIntakes,
    required this.range,
    this.chartHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final macroColors = theme.extension<MacroColors>();

    final proteinColor = macroColors?.protein ?? Colors.red;
    final carbsColor = macroColors?.carbs ?? Colors.green.shade400;
    final fatColor = macroColors?.fat ?? Colors.purple.shade300;

    // Calculate maximum calories to scale chart
    int maxDailyKcal = 0;
    for (final day in dailyIntakes) {
      if (day.calories > maxDailyKcal) {
        maxDailyKcal = day.calories;
      }
    }

    // Determine grid ceiling (multiples of 1000, minimum 2000, e.g. 2000, 3000, 4000)
    final gridCeiling = max(2000, ((maxDailyKcal * 1.15) / 500).ceil() * 500);
    final midKcal = (gridCeiling / 2).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: chartHeight,
          child: Stack(
            children: [
              // Grid background lines & labels
              Positioned.fill(
                child: CustomPaint(
                  painter: _MacroGridPainter(
                    gridCeiling: gridCeiling,
                    lineColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
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
                top: (chartHeight - 24) / 2,
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

              // Bars
              Positioned(
                left: 0,
                right: 32,
                top: 8,
                bottom: 20,
                child: dailyIntakes.isEmpty
                    ? Center(
                        child: Text(
                          'Keine Daten',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(dailyIntakes.length, (index) {
                          final item = dailyIntakes[index];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: dailyIntakes.length <= 10
                                    ? 4.0
                                    : (dailyIntakes.length <= 31 ? 1.5 : 0.5),
                              ),
                              child: _buildStackedBar(
                                context,
                                item: item,
                                maxKcal: gridCeiling,
                                proteinColor: proteinColor,
                                carbsColor: carbsColor,
                                fatColor: fatColor,
                              ),
                            ),
                          );
                        }),
                      ),
              ),

              // Bottom X-Axis date labels
              Positioned(
                left: 0,
                right: 32,
                bottom: 0,
                child: _buildXAxisLabels(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStackedBar(
    BuildContext context, {
    required DailyMacroIntake item,
    required int maxKcal,
    required Color proteinColor,
    required Color carbsColor,
    required Color fatColor,
  }) {
    if (item.calories <= 0) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
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
        final barHeight = constraints.maxHeight * totalRatio;
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: barHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Column(
                verticalDirection: VerticalDirection.up,
                children: [
                  // Bottom: Carbs
                  Expanded(
                    flex: carbsFlex,
                    child: Container(color: carbsColor),
                  ),
                  // Middle: Fat
                  Expanded(
                    flex: fatFlex,
                    child: Container(color: fatColor),
                  ),
                  // Top: Protein
                  Expanded(
                    flex: proteinFlex,
                    child: Container(color: proteinColor),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildXAxisLabels(BuildContext context) {
    if (dailyIntakes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    // If 7 days, show each day abbreviation
    if (dailyIntakes.length <= 7) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dailyIntakes.map((d) {
          final label = DateFormat.E(locale).format(d.date);
          return Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          );
        }).toList(),
      );
    }

    // For longer periods, show 4-5 evenly distributed dates
    final count = min(5, dailyIntakes.length);
    final step = (dailyIntakes.length - 1) / (count - 1);
    final labels = <Widget>[];

    for (int i = 0; i < count; i++) {
      final index = (i * step).round().clamp(0, dailyIntakes.length - 1);
      final date = dailyIntakes[index].date;
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
