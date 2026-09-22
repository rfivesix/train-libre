import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('schema 34 upgrades to the complete manual-plan schema', () async {
    final directory =
        await Directory.systemTemp.createTemp('schema_v35_plan_test_');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final file = File(p.join(directory.path, 'v34.sqlite'));

    var database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    await database.customStatement('PRAGMA foreign_keys = OFF');
    await database.customStatement('DROP TABLE training_plan_occurrences');
    await database.customStatement('DROP TABLE training_plan_activations');
    await database.customStatement('DROP TABLE training_plan_revisions');
    await database.customStatement('DROP TABLE training_plans');
    await database.customStatement('PRAGMA user_version = 34');
    await database.close();

    database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    final tables = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = tables.map((row) => row.read<String>('name')).toSet();
    expect(database.schemaVersion, 35);
    expect(
      names,
      containsAll([
        'training_plans',
        'training_plan_revisions',
        'training_plan_activations',
        'training_plan_occurrences',
      ]),
    );
    final indexes = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final indexNames = indexes.map((row) => row.read<String>('name')).toSet();
    expect(indexNames, contains('idx_training_plan_active'));
    expect(indexNames, contains('idx_training_occurrence_slot'));
    await database.close();
  });
}
