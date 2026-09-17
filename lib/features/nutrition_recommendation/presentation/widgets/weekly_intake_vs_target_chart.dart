// lib/features/nutrition_recommendation/presentation/widgets/weekly_intake_vs_target_chart.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../statistics/data/macro_analytics_data_adapter.dart';

/// Interactive chart displaying 7 daily actual intake bars side-by-side
/// with a distinct 8th target recommendation bar separated by a visual gap.
class WeeklyIntakeVsTargetChart extends StatelessWidget {
  final List<DailyMacroIntake> dailyIntakes;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final double chartHeight;

  const WeeklyIntakeVsTargetChart({
    super.key,
    required this.dailyIntakes,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    this.chartHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final macroColors = theme.extension<MacroColors>();

    final proteinColor = macroColors?.protein ?? Colors.red;
    final carbsColor = macroColors?.carbs ?? Colors.green.shade400;
    final fatColor = macroColors?.fat ?? Colors.purple.shade300;

    // Determine scale ceiling
    int maxKcal = targetCalories > 0 ? targetCalories : 2000;
    for (final day in dailyIntakes) {
      if (day.calories > maxKcal) {
        maxKcal = day.calories;
      }
    }
    final double ceiling = (maxKcal * 1.15).toDouble();

    // Ensure we have exactly 7 days
    final List<DailyMacroIntake> sevenDays = List.from(dailyIntakes);
    if (sevenDays.length > 7) {
      sevenDays.removeRange(0, sevenDays.length - 7);
    }

    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: 7 Days of Actual Intake
              Expanded(
                flex: 7,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(7, (index) {
                    final day = index < sevenDays.length ? sevenDays[index] : null;
                    final dayLabel = day != null
                        ? _formatWeekday(day.date, locale)
                        : '';
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: _buildColumn(
                          context,
                          calories: day?.calories ?? 0,
                          proteinGrams: day?.proteinGrams ?? 0,
                          fatGrams: day?.fatGrams ?? 0,
                          carbsGrams: day?.carbsGrams ?? 0,
                          bottomLabel: dayLabel,
                          ceiling: ceiling,
                          proteinColor: proteinColor,
                          carbsColor: carbsColor,
                          fatColor: fatColor,
                          isTarget: false,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Visual Divider / Spalt
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Center(
                  child: Container(
                    width: 1.5,
                    height: chartHeight - 28,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // Right: The 8th Bar (Recommendation Target)
              SizedBox(
                width: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _buildColumn(
                    context,
                    calories: targetCalories,
                    proteinGrams: targetProtein.toDouble(),
                    fatGrams: targetFat.toDouble(),
                    carbsGrams: targetCarbs.toDouble(),
                    bottomLabel: 'Ziel',
                    ceiling: ceiling,
                    proteinColor: proteinColor,
                    carbsColor: carbsColor,
                    fatColor: fatColor,
                    isTarget: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(
    BuildContext context, {
    required int calories,
    required double proteinGrams,
    required double fatGrams,
    required double carbsGrams,
    required String bottomLabel,
    required double ceiling,
    required Color proteinColor,
    required Color carbsColor,
    required Color fatColor,
    required bool isTarget,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final badgeColor = isTarget
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : (isDark
            ? Colors.blueGrey.shade800.withValues(alpha: 0.6)
            : Colors.blue.shade50);
    final badgeTextColor = isTarget
        ? theme.colorScheme.primary
        : (isDark ? Colors.lightBlueAccent.shade100 : Colors.blue.shade800);

    final ratio = ceiling > 0 ? (calories / ceiling).clamp(0.0, 1.0) : 0.0;

    final carbsKcal = max(0.0, carbsGrams * 4);
    final proteinKcal = max(0.0, proteinGrams * 4);
    final fatKcal = max(0.0, fatGrams * 9);
    final totalMacroKcal = carbsKcal + proteinKcal + fatKcal;

    final cFlex = totalMacroKcal > 0
        ? max(1, (carbsKcal / totalMacroKcal * 100).round())
        : 33;
    final fFlex = totalMacroKcal > 0
        ? max(1, (fatKcal / totalMacroKcal * 100).round())
        : 33;
    final pFlex = totalMacroKcal > 0
        ? max(1, (proteinKcal / totalMacroKcal * 100).round())
        : 34;

    return Column(
      children: [
        // Top Kcal Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(4),
            border: isTarget
                ? Border.all(color: theme.colorScheme.primary, width: 1.2)
                : null,
          ),
          child: Text(
            calories > 0 ? '$calories' : '--',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 9.5,
              color: badgeTextColor,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Middle: Stacked Bar Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barHeight = calories > 0
                  ? max(24.0, constraints.maxHeight * ratio)
                  : 4.0;

              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: isTarget
                        ? Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isTarget ? 4.5 : 6),
                    child: calories > 0
                        ? Column(
                            children: [
                              // Top: Protein
                              Expanded(
                                flex: pFlex,
                                child: Container(
                                  color: proteinColor,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${proteinGrams.round()}P',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ),
                              ),
                              // Middle: Fat
                              Expanded(
                                flex: fFlex,
                                child: Container(
                                  color: fatColor,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${fatGrams.round()}F',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ),
                              ),
                              // Bottom: Carbs
                              Expanded(
                                flex: cFlex,
                                child: Container(
                                  color: carbsColor,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${carbsGrams.round()}C',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.08),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Bottom Label (Weekday or "Ziel")
        Text(
          bottomLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isTarget ? FontWeight.bold : FontWeight.w600,
            fontSize: isTarget ? 10.5 : 10,
            color: isTarget
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  static String _formatWeekday(DateTime date, String locale) {
    final raw = DateFormat.E(locale).format(date);
    final clean = raw.replaceAll('.', '').trim();
    if (clean.length > 2) {
      return clean.substring(0, 2);
    }
    return clean;
  }
}
