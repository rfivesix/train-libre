import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' as db;

/// Reproduces the state an installed build ended up in: `user_version` already
/// records the current schema, so no migration will ever run again, but a
/// column the code queries is missing. Every query touching that table then
/// throws and nothing can be logged at all.
Future<Set<String>> _columnsOf(db.AppDatabase database, String table) async {
  final rows = await database.customSelect('PRAGMA table_info($table);').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

/// Puts the database into that state: the index goes first because SQLite
/// refuses to drop a column another index still refers to.
Future<void> _dropMealEntryIdColumn(db.AppDatabase database) async {
  await database.customStatement(
      'DROP INDEX IF EXISTS idx_nutrition_logs_meal_entry_id;');
  await database.customStatement(
    'ALTER TABLE nutrition_logs DROP COLUMN meal_entry_id;',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDatabase.reconcileSchema', () {
    late db.AppDatabase database;

    setUp(() async {
      database = db.AppDatabase(NativeDatabase.memory());
      // Force the schema to exist before tampering with it.
      await database.customSelect('SELECT 1;').get();
    });

    tearDown(() async {
      await database.close();
    });

    test('does nothing when the schema already matches', () async {
      final repaired = await database.reconcileSchema();
      expect(repaired, isEmpty);
    });

    test('restores a column that a migration never applied', () async {
      await _dropMealEntryIdColumn(database);
      expect(
        await _columnsOf(database, 'nutrition_logs'),
        isNot(contains('meal_entry_id')),
      );

      final repaired = await database.reconcileSchema();

      expect(repaired, contains('nutrition_logs.meal_entry_id'));
      expect(
        await _columnsOf(database, 'nutrition_logs'),
        contains('meal_entry_id'),
      );
    });

    test('the repaired column makes the failing query work again', () async {
      await _dropMealEntryIdColumn(database);

      // The exact shape that failed on device: a join selecting every
      // nutrition_logs column, including the missing one.
      Future<void> runJoin() async {
        final query = database.select(database.fluidLogs).join([
          leftOuterJoin(
            database.nutritionLogs,
            database.nutritionLogs.id
                .equalsExp(database.fluidLogs.linkedNutritionLogId),
          ),
        ]);
        await query.get();
      }

      await expectLater(runJoin(), throwsA(isA<Exception>()));

      await database.reconcileSchema();
      await runJoin();
    });

    test('restores a table that was never created', () async {
      await database.customStatement('DROP TABLE meal_entries;');

      final repaired = await database.reconcileSchema();

      expect(repaired, contains('table meal_entries'));
      expect(await _columnsOf(database, 'meal_entries'), isNotEmpty);
    });

    test('is safe to run repeatedly', () async {
      await _dropMealEntryIdColumn(database);
      await database.reconcileSchema();
      expect(await database.reconcileSchema(), isEmpty);
    });
  });

  test('a damaged database heals itself on the next open', () async {
    // The whole point of hanging this off `beforeOpen`: the user should not
    // have to reinstall, they should just launch the app again.
    final dir = await Directory.systemTemp.createTemp('trainlibre_schema');
    final file = File('${dir.path}/app.sqlite');

    var database = db.AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1;').get();
    await _dropMealEntryIdColumn(database);
    await database.close();

    database = db.AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await database.close();
      await dir.delete(recursive: true);
    });

    // Opening is enough — this is the query that used to throw on device.
    final rows = await database.select(database.nutritionLogs).get();
    expect(rows, isEmpty);
    expect(
      await _columnsOf(database, 'nutrition_logs'),
      contains('meal_entry_id'),
    );
  });
}
