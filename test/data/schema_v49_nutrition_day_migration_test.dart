import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'upgrading from v48 keeps logged food and persists calendar marks',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'nutrition_days_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/db.sqlite');
      final date = DateTime(2026, 10, 24, 8);

      final previous = AppDatabase(NativeDatabase(file));
      try {
        await previous
            .into(previous.nutritionLogs)
            .insert(
              NutritionLogsCompanion.insert(consumedAt: date, amount: 100),
            );
        await previous.customStatement('DROP TABLE incomplete_nutrition_days');
        await previous.customStatement('PRAGMA user_version = 48');
      } finally {
        await previous.close();
      }

      final migrated = AppDatabase(NativeDatabase(file));
      final helper = DatabaseHelper.forTesting(migrated);
      final status = StreamIterator(helper.watchIncompleteNutritionDay(date));
      try {
        expect(await helper.getIncompleteNutritionDays(date, date), isEmpty);
        expect(await helper.getEntriesForDate(date), hasLength(1));
        expect(await status.moveNext(), isTrue);
        expect(status.current, isFalse);
        await helper.setIncompleteNutritionDay(date, true);
        expect(await status.moveNext(), isTrue);
        expect(status.current, isTrue);
        await helper.setIncompleteNutritionDay(
          DateTime.utc(2026, 10, 24),
          true,
        );
        expect(await helper.getIncompleteNutritionDays(date, date), {
          DateTime(2026, 10, 24),
        });
      } finally {
        await status.cancel();
        await migrated.close();
      }

      final reopened = AppDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      final reopenedHelper = DatabaseHelper.forTesting(reopened);
      expect(
        await reopenedHelper.watchIncompleteNutritionDay(date).first,
        isTrue,
      );
      expect(
        await reopenedHelper
            .watchIncompleteNutritionDay(DateTime(2026, 10, 25))
            .first,
        isFalse,
      );
      await reopenedHelper.setIncompleteNutritionDay(date, false);
      expect(
        await reopenedHelper.watchIncompleteNutritionDay(date).first,
        isFalse,
      );
      expect(await reopenedHelper.getEntriesForDate(date), hasLength(1));
    },
  );
}
