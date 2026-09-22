import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/data/drift_database.dart';

Future<Set<String>> _columns(AppDatabase database, String table) async {
  final rows = await database.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

Future<Set<String>> _tables(AppDatabase database) async {
  final rows = await database
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      )
      .get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('schema_v34_goal_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<File> currentFixture(String name) async {
    final file = File(p.join(tempDir.path, '$name.sqlite'));
    final database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    await database.close();
    return file;
  }

  Future<void> assertCurrentAndReopen(File file) async {
    var database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    expect(database.schemaVersion, 35);
    expect(
      await _tables(database),
      containsAll(['user_goals', 'goal_events', 'goal_reviews']),
    );
    expect(
      await _columns(database, 'user_goals'),
      containsAll([
        'tracking_mode',
        'baseline_measurement_id',
        'baseline_value_kg',
        'baseline_date',
      ]),
    );
    await database.close();

    database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    expect(await database.select(database.userGoals).get(), isA<List>());
    await database.close();
  }

  test('opens a real schema-31 fixture with no goal tables', () async {
    final file = await currentFixture('v31');
    final old = AppDatabase(NativeDatabase(file));
    await old.customStatement('PRAGMA foreign_keys = OFF');
    await old.customStatement('DROP TABLE goal_reviews');
    await old.customStatement('DROP TABLE goal_events');
    await old.customStatement('DROP TABLE user_goals');
    await old.customStatement('PRAGMA user_version = 31');
    await old.close();

    await assertCurrentAndReopen(file);
  });

  test('repairs a partially present schema-32 fixture before indexing',
      () async {
    final file = await currentFixture('v32_partial');
    final old = AppDatabase(NativeDatabase(file));
    await old.customStatement('PRAGMA foreign_keys = OFF');
    await old.customStatement('DROP TABLE goal_reviews');
    await old.customStatement('DROP TABLE goal_events');
    await old.customStatement('PRAGMA user_version = 32');
    await old.close();

    await assertCurrentAndReopen(file);
  });

  test('schema-33 backfills immutable baseline columns and reopens', () async {
    final file = await currentFixture('v33');
    final old = AppDatabase(NativeDatabase(file));
    final baselineDate = DateTime(2026, 1, 2);
    await old.into(old.measurements).insert(
          MeasurementsCompanion.insert(
            id: const Value('weight-v33'),
            type: 'weight',
            value: 79.5,
            unit: 'kg',
            date: baselineDate,
          ),
        );
    await old.into(old.userGoals).insert(
          UserGoalsCompanion.insert(
            id: const Value('goal-v33'),
            preset: 'loseWeight',
            title: 'Loss',
            startDate: baselineDate.add(const Duration(days: 1)),
          ),
        );
    await old.customStatement('PRAGMA foreign_keys = OFF');
    await old
        .customStatement('ALTER TABLE user_goals DROP COLUMN baseline_date');
    await old.customStatement(
        'ALTER TABLE user_goals DROP COLUMN baseline_value_kg');
    await old.customStatement(
        'ALTER TABLE user_goals DROP COLUMN baseline_measurement_id');
    await old
        .customStatement('ALTER TABLE user_goals DROP COLUMN tracking_mode');
    await old.customStatement('PRAGMA user_version = 33');
    await old.close();

    final migrated = AppDatabase(NativeDatabase(file));
    await migrated.customSelect('SELECT 1').get();
    final goal = await (migrated.select(migrated.userGoals)
          ..where((row) => row.id.equals('goal-v33')))
        .getSingle();
    expect(goal.trackingMode, 'weeklyRate');
    expect(goal.baselineMeasurementId, 'weight-v33');
    expect(goal.baselineValueKg, 79.5);
    expect(goal.baselineDate, baselineDate);
    await migrated.close();

    await assertCurrentAndReopen(file);
  });
}
