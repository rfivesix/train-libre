import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/diary/domain/models/fluid_entry.dart';
import 'package:train_libre/features/diary/domain/models/macro_entry.dart'
    as diary;
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

    test('trimmedToFirstTracked removes leading empty days', () {
      final range = DateTimeRange(
        start: DateTime(2020, 1, 1),
        end: DateTime(2026, 6, 2),
      );
      final summary = MacroPeriodSummary(
        range: range,
        dailyIntakes: [
          DailyMacroIntake(
            date: DateTime(2020, 1, 1),
            calories: 0,
            proteinGrams: 0,
            carbsGrams: 0,
            fatGrams: 0,
          ),
          DailyMacroIntake(
            date: DateTime(2026, 5, 31),
            calories: 0,
            proteinGrams: 0,
            carbsGrams: 0,
            fatGrams: 0,
          ),
          DailyMacroIntake(
            date: DateTime(2026, 6, 1),
            calories: 2500,
            proteinGrams: 160,
            carbsGrams: 260,
            fatGrams: 80,
          ),
          DailyMacroIntake(
            date: DateTime(2026, 6, 2),
            calories: 0,
            proteinGrams: 0,
            carbsGrams: 0,
            fatGrams: 0,
          ),
        ],
        avgCalories: 2500,
        avgProtein: 160,
        avgCarbs: 260,
        avgFat: 80,
        totalDays: 4,
        trackedDays: 1,
      );

      final trimmed = summary.trimmedToFirstTracked();
      expect(trimmed.dailyIntakes.length, 2);
      expect(trimmed.dailyIntakes.first.date, DateTime(2026, 6, 1));
      expect(trimmed.range.start, DateTime(2026, 6, 1));
      expect(trimmed.range.end, DateTime(2026, 6, 2));
      expect(trimmed.totalDays, 2);
      expect(trimmed.trackedDays, 1);
      expect(trimmed.avgCalories, 2500);
    });

    test('trimmedToFirstTracked returns empty when no tracked days exist', () {
      final range = DateTimeRange(
        start: DateTime(2020, 1, 1),
        end: DateTime(2026, 6, 2),
      );
      final summary = MacroPeriodSummary(
        range: range,
        dailyIntakes: [
          DailyMacroIntake(
            date: DateTime(2020, 1, 1),
            calories: 0,
            proteinGrams: 0,
            carbsGrams: 0,
            fatGrams: 0,
          ),
        ],
        avgCalories: 0,
        avgProtein: 0,
        avgCarbs: 0,
        avgFat: 0,
        totalDays: 1,
        trackedDays: 0,
      );

      final trimmed = summary.trimmedToFirstTracked();
      expect(trimmed.dailyIntakes, isEmpty);
      expect(trimmed.totalDays, 0);
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

    test(
      'an incomplete day keeps its date slot and can be counted again',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final helper = DatabaseHelper.forTesting(db);
        final adapter = MacroAnalyticsDataAdapter(databaseHelper: helper);
        final partialDay = DateTime(2026, 9, 12);
        final completeDay = DateTime(2026, 9, 13);
        final range = DateTimeRange(start: partialDay, end: completeDay);
        for (final (date, calories, protein) in [
          (partialDay, 420.0, 24.0),
          (completeDay, 2020.0, 130.0),
        ]) {
          await helper.insertMacroEntry(
            diary.MacroEntry(
              id: 'meal-${date.day}',
              timestamp: DateTime(date.year, date.month, date.day, 12),
              mealType: 'mealtypeBreakfast',
              calories: calories,
              protein: protein,
              carbs: 0,
              fat: 0,
              calculatedNutrient: 'calories',
            ),
          );
        }

        await helper.setIncompleteNutritionDay(partialDay, true);
        final filtered = await adapter.fetchSummary(range: range);
        expect(filtered.avgCalories, 2020);
        expect(filtered.avgProtein, 130);
        expect(filtered.trackedDays, 1);
        expect(filtered.incompleteDays, 1);
        expect(filtered.dailyIntakes.first.date, partialDay);
        expect(filtered.dailyIntakes.first.isIncomplete, isTrue);
        expect(filtered.dailyIntakes.first.hasData, isFalse);
        expect(filtered.trimmedToFirstTracked().range.start, partialDay);
        expect(
          (await helper.diaryLocalDataSource.getMacroEntriesForDate(partialDay))
              .single
              .calories,
          420,
        );

        await helper.setIncompleteNutritionDay(partialDay, false);
        final restored = await adapter.fetchSummary(range: range);
        expect(restored.trackedDays, 2);
        expect(restored.incompleteDays, 0);
        expect(restored.avgCalories, 1220);
        expect(restored.avgProtein, 77);
      },
    );

    test('fetchSummary treats FluidEntry.kcal as total calories without duplicate scaling', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dbHelper = DatabaseHelper.forTesting(db);
      final adapter = MacroAnalyticsDataAdapter(databaseHelper: dbHelper);

      final date = DateTime(2026, 9, 12, 12, 0);

      // Insert a fluid entry with 4850 ml, 78 total kcal, and 0.5g carbs/100ml
      await dbHelper.insertFluidEntry(
        FluidEntry(
          timestamp: date,
          quantityInMl: 4850,
          name: 'Electrolyte Drink',
          kcal: 78,
          carbsPer100ml: 0.5,
          sugarPer100ml: 0.5,
        ),
      );

      final summary = await adapter.fetchSummary(
        range: DateTimeRange(
          start: DateTime(2026, 9, 12),
          end: DateTime(2026, 9, 12),
        ),
      );

      expect(summary.dailyIntakes.length, 1);
      final intake = summary.dailyIntakes.first;

      // Calories should be exactly 78, NOT 78 * 48.5 = 3783!
      expect(intake.calories, 78);
      // Carbs should be 0.5 * 48.5 = 24.25g
      expect(intake.carbsGrams, closeTo(24.25, 0.01));
      expect(intake.proteinGrams, 0.0);
      expect(intake.fatGrams, 0.0);

      await db.close();
    });
  });
}
