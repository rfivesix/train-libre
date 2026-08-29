// test/features/diary/domain/meal_reschedule_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/domain/meal_reschedule.dart';
import 'package:train_libre/features/diary/domain/models/food_entry.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/features/diary/domain/models/meal_entry.dart';
import 'package:train_libre/features/diary/domain/models/tracked_food_item.dart';

void main() {
  MealEntry mealAt(DateTime consumedAt) => MealEntry(
        id: 'meal-1',
        consumedAt: consumedAt,
        mealType: 'mealtypeLunch',
        title: 'Test meal',
        source: 'aiPhoto',
      );

  TrackedFoodItem itemAt(DateTime timestamp, {int? id}) => TrackedFoodItem(
        item: FoodItem(
          barcode: '1001',
          name: 'Reis',
          calories: 200,
          protein: 10,
          carbs: 20,
          fat: 5,
        ),
        entry: FoodEntry(
          id: id,
          barcode: '1001',
          timestamp: timestamp,
          quantityInGrams: 150,
          mealType: 'mealtypeLunch',
          mealEntryId: 'meal-1',
        ),
      );

  group('rescheduleMeal', () {
    test('moves the meal and its items to the new day', () {
      final result = rescheduleMeal(
        entry: mealAt(DateTime(2026, 3, 10, 12, 30)),
        items: [itemAt(DateTime(2026, 3, 10, 12, 30))],
        newConsumedAt: DateTime(2026, 3, 12, 19, 0),
      );

      expect(result.entry.consumedAt, DateTime(2026, 3, 12, 19, 0));
      expect(result.items.single.entry.timestamp, DateTime(2026, 3, 12, 19, 0));
    });

    test('items keep their offset from the meal, matching what the database '
        'writes', () {
      final result = rescheduleMeal(
        entry: mealAt(DateTime(2026, 3, 10, 12, 30)),
        items: [
          itemAt(DateTime(2026, 3, 10, 12, 30)),
          itemAt(DateTime(2026, 3, 10, 12, 40)),
        ],
        newConsumedAt: DateTime(2026, 3, 12, 19, 0),
      );

      expect(result.items[0].entry.timestamp, DateTime(2026, 3, 12, 19, 0));
      expect(result.items[1].entry.timestamp, DateTime(2026, 3, 12, 19, 10));
    });

    test('moving backwards in time works the same way', () {
      final result = rescheduleMeal(
        entry: mealAt(DateTime(2026, 3, 12, 19, 0)),
        items: [itemAt(DateTime(2026, 3, 12, 19, 0))],
        newConsumedAt: DateTime(2026, 3, 10, 8, 15),
      );

      expect(result.entry.consumedAt, DateTime(2026, 3, 10, 8, 15));
      expect(result.items.single.entry.timestamp, DateTime(2026, 3, 10, 8, 15));
    });

    test('leaves everything except the timestamps alone', () {
      final result = rescheduleMeal(
        entry: mealAt(DateTime(2026, 3, 10, 12, 30)),
        items: [itemAt(DateTime(2026, 3, 10, 12, 30), id: 7)],
        newConsumedAt: DateTime(2026, 3, 12, 19, 0),
      );

      expect(result.entry.id, 'meal-1');
      expect(result.entry.mealType, 'mealtypeLunch');
      expect(result.entry.title, 'Test meal');

      final movedItem = result.items.single.entry;
      expect(movedItem.id, 7, reason: 'the row identity must survive the move');
      expect(movedItem.mealEntryId, 'meal-1');
      expect(movedItem.quantityInGrams, 150);
      expect(result.items.single.item.name, 'Reis');
    });

    test('an unchanged timestamp is a no-op', () {
      final result = rescheduleMeal(
        entry: mealAt(DateTime(2026, 3, 10, 12, 30)),
        items: [itemAt(DateTime(2026, 3, 10, 12, 30))],
        newConsumedAt: DateTime(2026, 3, 10, 12, 30),
      );

      expect(result.entry.consumedAt, DateTime(2026, 3, 10, 12, 30));
      expect(result.items.single.entry.timestamp, DateTime(2026, 3, 10, 12, 30));
    });

    test('a meal with no items is handled', () {
      final result = rescheduleMeal(
        entry: mealAt(DateTime(2026, 3, 10, 12, 30)),
        items: const [],
        newConsumedAt: DateTime(2026, 3, 12, 19, 0),
      );

      expect(result.entry.consumedAt, DateTime(2026, 3, 12, 19, 0));
      expect(result.items, isEmpty);
    });
  });
}
