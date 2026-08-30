// test/features/diary/data/sources/meal_entry_move_test.dart
//
// Moving a logged meal to another day. There is no day column in this schema:
// every diary query buckets rows by their own timestamp, and a meal's calories
// live in `nutrition_logs`, not in `meal_entries`. So the thing worth testing
// is not "the meal entry got a new timestamp" but "both affected days add up
// afterwards" — the old one down by the meal, the new one up by it.

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/diary/data/sources/diary_local_data_source.dart';
import 'package:train_libre/features/diary/domain/models/meal_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late DiaryLocalDataSource dataSource;

  // Fixed calendar days, so the test never straddles a real midnight.
  final oldDay = DateTime(2026, 3, 10);
  final newDay = DateTime(2026, 3, 12);

  setUp(() async {
    database = db.AppDatabase(NativeDatabase.memory());
    dataSource = DiaryLocalDataSource(database);
  });

  tearDown(() async {
    await database.close();
  });

  /// A product at 200 kcal / 100 g, so 150 g is an unambiguous 300 kcal.
  Future<int> insertProduct({
    required String barcode,
    required String name,
    int calories = 200,
  }) async {
    return database.into(database.products).insert(
          db.ProductsCompanion.insert(
            barcode: barcode,
            name: name,
            calories: calories,
            protein: 10,
            carbs: 20,
            fat: 5,
          ),
        );
  }

  /// Writes a meal at [consumedAt] with one 150 g item, and returns the meal id.
  Future<String> insertMealWithItem({
    required DateTime consumedAt,
    String barcode = '1001',
    Duration itemOffset = Duration.zero,
  }) async {
    final mealId = 'meal-${consumedAt.microsecondsSinceEpoch}';
    await dataSource.insertMealEntry(
      MealEntry(
        id: mealId,
        consumedAt: consumedAt,
        mealType: 'mealtypeLunch',
        title: 'Test meal',
        source: 'aiPhoto',
      ),
    );
    await database.into(database.nutritionLogs).insert(
          db.NutritionLogsCompanion.insert(
            legacyBarcode: drift.Value(barcode),
            consumedAt: consumedAt.add(itemOffset),
            amount: 150,
            mealType: const drift.Value('mealtypeLunch'),
            mealEntryId: drift.Value(mealId),
          ),
        );
    return mealId;
  }

  /// The kcal the diary attributes to [day].
  ///
  /// [getFoodCaloriesByDayForDateRange] takes literal bounds rather than a
  /// calendar day, so the end has to be spelled out the way the day queries
  /// elsewhere in the data source do.
  Future<double> kcalOn(DateTime day) async {
    final result = await dataSource.getFoodCaloriesByDayForDateRange(
      DateTime(day.year, day.month, day.day),
      DateTime(day.year, day.month, day.day, 23, 59, 59),
    );
    return result.caloriesByDay[DateTime(day.year, day.month, day.day)] ?? 0.0;
  }

  group('moveMealEntryTo — day switch', () {
    setUp(() async {
      await insertProduct(barcode: '1001', name: 'Reis');
    });

    test('meal entry leaves the old day and appears on the new one', () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      expect(
        await dataSource.watchMealEntriesForDate(oldDay).first,
        hasLength(1),
        reason: 'precondition: the meal starts out on the old day',
      );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));

      expect(await dataSource.watchMealEntriesForDate(oldDay).first, isEmpty);
      final onNewDay = await dataSource.watchMealEntriesForDate(newDay).first;
      expect(onNewDay, hasLength(1));
      expect(onNewDay.single.id, mealId);
      expect(onNewDay.single.consumedAt, DateTime(2026, 3, 12, 19, 0));
    });

    test(
        'the food entries move with it — a meal card is never left behind '
        'on one day with its calories on another', () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));

      expect(await dataSource.getEntriesForDate(oldDay), isEmpty);

      final entriesOnNewDay = await dataSource.getEntriesForDate(newDay);
      expect(entriesOnNewDay, hasLength(1));
      expect(entriesOnNewDay.single.timestamp, DateTime(2026, 3, 12, 19, 0));
    });

    test(
        'the daily calorie totals of both affected days are correct '
        'afterwards', () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      // A second, unrelated meal on the old day that must not be disturbed.
      await insertMealWithItem(consumedAt: DateTime(2026, 3, 10, 8, 0));

      expect(await kcalOn(oldDay), 600.0);
      expect(await kcalOn(newDay), 0.0);

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));

      expect(await kcalOn(oldDay), 300.0,
          reason: 'the old day loses exactly the moved meal, nothing else');
      expect(await kcalOn(newDay), 300.0,
          reason: 'and the new day gains exactly it');
    });

    test('a meal moved back to its original day restores both totals',
        () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));
      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 10, 12, 30));

      expect(await kcalOn(oldDay), 300.0);
      expect(await kcalOn(newDay), 0.0);
      expect(
          await dataSource.watchMealEntriesForDate(oldDay).first, hasLength(1));
      expect(await dataSource.watchMealEntriesForDate(newDay).first, isEmpty);
    });

    test(
        'only the meal\'s own items move — an unrelated log on the old day '
        'stays put', () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      // A standalone log with no meal entry behind it.
      await database.into(database.nutritionLogs).insert(
            db.NutritionLogsCompanion.insert(
              legacyBarcode: const drift.Value('1001'),
              consumedAt: DateTime(2026, 3, 10, 20, 0),
              amount: 100,
            ),
          );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));

      final remaining = await dataSource.getEntriesForDate(oldDay);
      expect(remaining, hasLength(1));
      expect(remaining.single.timestamp, DateTime(2026, 3, 10, 20, 0));
      expect(await kcalOn(oldDay), 200.0);
    });

    test('items keep their offset from the meal instead of being pinned to it',
        () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
        itemOffset: const Duration(minutes: 10),
      );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));

      final entries = await dataSource.getEntriesForDate(newDay);
      expect(entries.single.timestamp, DateTime(2026, 3, 12, 19, 10));
    });

    test('a move to 23:59 still lands inside its own day', () async {
      // The day queries end at 23:59:59, so a timestamp carrying seconds or
      // milliseconds here would fall out of the very day it was moved to.
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 23, 59));

      expect(
          await dataSource.watchMealEntriesForDate(newDay).first, hasLength(1));
      expect(await dataSource.getEntriesForDate(newDay), hasLength(1));
      expect(await kcalOn(newDay), 300.0);
    });

    test('a move to 00:00 lands inside its own day', () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 0, 0));

      expect(
          await dataSource.watchMealEntriesForDate(newDay).first, hasLength(1));
      expect(await kcalOn(newDay), 300.0);
    });

    test('changing only the time leaves the meal on the same day', () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 10, 14, 45));

      final onOldDay = await dataSource.watchMealEntriesForDate(oldDay).first;
      expect(onOldDay, hasLength(1));
      expect(onOldDay.single.consumedAt, DateTime(2026, 3, 10, 14, 45));
      expect(await kcalOn(oldDay), 300.0);
    });

    test('moving to the timestamp it already has changes nothing', () async {
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 10, 12, 30));

      expect(await kcalOn(oldDay), 300.0);
      final entries = await dataSource.getEntriesForDate(oldDay);
      expect(entries.single.timestamp, DateTime(2026, 3, 10, 12, 30));
    });

    test('an unknown meal id is a no-op rather than an error', () async {
      await insertMealWithItem(consumedAt: DateTime(2026, 3, 10, 12, 30));

      await dataSource.moveMealEntryTo('does-not-exist', newDay);

      expect(await kcalOn(oldDay), 300.0);
    });
  });

  group('moveMealEntryTo — rows hanging off the meal', () {
    test(
        'a linked fluid log moves too, so neither day\'s hydration total '
        'is left wrong', () async {
      await insertProduct(barcode: '2001', name: 'Saft');
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
        barcode: '2001',
      );

      final log = await (database.select(database.nutritionLogs)
            ..where((t) => t.mealEntryId.equals(mealId)))
          .getSingle();

      await database.into(database.fluidLogs).insert(
            db.FluidLogsCompanion.insert(
              consumedAt: DateTime(2026, 3, 10, 12, 30),
              amountMl: 250,
              name: 'Saft',
              linkedNutritionLogId: drift.Value(log.id),
            ),
          );

      expect(await dataSource.getFluidEntriesForDate(oldDay), hasLength(1));

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));

      expect(await dataSource.getFluidEntriesForDate(oldDay), isEmpty,
          reason: 'the old day must not keep charging the user for this drink');
      final movedFluid = await dataSource.getFluidEntriesForDate(newDay);
      expect(movedFluid, hasLength(1));
      expect(movedFluid.single.quantityInMl, 250);
      expect(movedFluid.single.timestamp, DateTime(2026, 3, 12, 19, 0));
    });

    test('an unlinked fluid log on the old day is left alone', () async {
      await insertProduct(barcode: '1001', name: 'Reis');
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      await database.into(database.fluidLogs).insert(
            db.FluidLogsCompanion.insert(
              consumedAt: DateTime(2026, 3, 10, 9, 0),
              amountMl: 500,
              name: 'Wasser',
            ),
          );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));

      final stillThere = await dataSource.getFluidEntriesForDate(oldDay);
      expect(stillThere, hasLength(1));
      expect(stillThere.single.quantityInMl, 500);
      expect(await dataSource.getFluidEntriesForDate(newDay), isEmpty);
    });

    test('a linked supplement log moves too', () async {
      await insertProduct(barcode: '3001', name: 'Kaffee');
      final mealId = await insertMealWithItem(
        consumedAt: DateTime(2026, 3, 10, 12, 30),
        barcode: '3001',
      );

      final log = await (database.select(database.nutritionLogs)
            ..where((t) => t.mealEntryId.equals(mealId)))
          .getSingle();

      final supplementId = 'supp-caffeine';
      await database.into(database.supplements).insert(
            db.SupplementsCompanion.insert(
              id: drift.Value(supplementId),
              name: 'Koffein',
              dose: 80,
              unit: 'mg',
              code: const drift.Value('caffeine'),
            ),
          );
      await database.into(database.supplementLogs).insert(
            db.SupplementLogsCompanion.insert(
              supplementId: supplementId,
              takenAt: DateTime(2026, 3, 10, 12, 30),
              amount: 80,
              sourceNutritionLogId: drift.Value(log.id),
            ),
          );

      await dataSource.moveMealEntryTo(mealId, DateTime(2026, 3, 12, 19, 0));

      final moved = await database.select(database.supplementLogs).getSingle();
      expect(moved.takenAt, DateTime(2026, 3, 12, 19, 0));
    });
  });
}
