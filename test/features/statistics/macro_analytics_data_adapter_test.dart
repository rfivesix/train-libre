import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/statistics/data/macro_analytics_data_adapter.dart';

void main() {
  group('DailyMacroIntake', () {
    test('instantiates with correct fields', () {
      final intake = DailyMacroIntake(
        date: DateTime(2026, 4, 1),
        calories: 2200,
        proteinGrams: 160.0,
        carbsGrams: 240.0,
        fatGrams: 60.0,
      );

      expect(intake.date, DateTime(2026, 4, 1));
      expect(intake.calories, 2200);
      expect(intake.proteinGrams, 160.0);
      expect(intake.carbsGrams, 240.0);
      expect(intake.fatGrams, 60.0);
    });
  });

  group('MacroPeriodSummary', () {
    test('empty factory creates zeroed summary', () {
      final range = DateTimeRange(
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 4, 7),
      );
      final empty = MacroPeriodSummary.empty(range);

      expect(empty.range, range);
      expect(empty.dailyIntakes, isEmpty);
      expect(empty.avgCalories, 0);
      expect(empty.avgProtein, 0.0);
      expect(empty.avgCarbs, 0.0);
      expect(empty.avgFat, 0.0);
      expect(empty.totalDays, 0);
      expect(empty.trackedDays, 0);
    });

    test('summary stores calculated values properly', () {
      final range = DateTimeRange(
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 4, 2),
      );
      final day1 = DailyMacroIntake(
        date: DateTime(2026, 4, 1),
        calories: 2000,
        proteinGrams: 150.0,
        carbsGrams: 200.0,
        fatGrams: 60.0,
      );
      final day2 = DailyMacroIntake(
        date: DateTime(2026, 4, 2),
        calories: 2400,
        proteinGrams: 170.0,
        carbsGrams: 260.0,
        fatGrams: 70.0,
      );

      final summary = MacroPeriodSummary(
        range: range,
        dailyIntakes: [day1, day2],
        avgCalories: 2200,
        avgProtein: 160.0,
        avgCarbs: 230.0,
        avgFat: 65.0,
        totalDays: 2,
        trackedDays: 2,
      );

      expect(summary.range, range);
      expect(summary.dailyIntakes.length, 2);
      expect(summary.avgCalories, 2200);
      expect(summary.avgProtein, 160.0);
      expect(summary.avgCarbs, 230.0);
      expect(summary.avgFat, 65.0);
      expect(summary.trackedDays, 2);
    });
  });

  group('MacroAnalyticsDataAdapter', () {
    test('normalizeDay strips time components', () {
      final dt = DateTime(2026, 4, 5, 14, 30, 45, 123);
      final normalized = MacroAnalyticsDataAdapter.normalizeDay(dt);

      expect(normalized.year, 2026);
      expect(normalized.month, 4);
      expect(normalized.day, 5);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
      expect(normalized.millisecond, 0);
    });

    test('instantiates with const constructor', () {
      const adapter = MacroAnalyticsDataAdapter();
      expect(adapter, isNotNull);
    });
  });
}
