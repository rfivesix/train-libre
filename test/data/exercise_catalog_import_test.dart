@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';

/// Drives the real importer against a real catalog file.
///
/// The point of going through `BasisDataManager` rather than reimplementing
/// the mapping here is that a reimplementation agrees with itself by
/// construction and proves nothing about the code that ships.
///
/// Runs against the 39-row fixture by default. Point TRAIN_LIBRE_CATALOG_DB at
/// a full build to import all 909:
///
///     TRAIN_LIBRE_CATALOG_DB=~/Projekte/OpenExerciseDB/artifacts/train_libre_training.db \
///         flutter test test/data/exercise_catalog_import_test.dart
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

String get sourcePath {
  final raw = Platform.environment['TRAIN_LIBRE_CATALOG_DB'];
  if (raw == null || raw.trim().isEmpty) {
    return File(kFixturePath).absolute.path;
  }
  final expanded = raw.startsWith('~')
      ? raw.replaceFirst('~', Platform.environment['HOME'] ?? '~')
      : raw;
  return File(expanded).absolute.path;
}

bool get usingFullCatalog =>
    (Platform.environment['TRAIN_LIBRE_CATALOG_DB'] ?? '').trim().isNotEmpty;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;
  late sqflite.Database source;

  setUpAll(() async {
    // Real SQLite on both sides: the importer opens its source through
    // sqflite and writes through Drift.
    sqflite.databaseFactory = databaseFactoryFfi;
    source = await databaseFactoryFfi.openDatabase(
      sourcePath,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );

    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();

    await BasisDataManager.instance
        .importExerciseCatalogFromFileForTesting(sourcePath);
  });

  tearDownAll(() async {
    await source.close();
    await db.close();
  });

  Future<int> sourceCount(String table, [String? where]) async {
    final rows = await source.rawQuery(
      'SELECT COUNT(*) AS c FROM $table${where == null ? '' : ' WHERE $where'}',
    );
    return sqflite.Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> importedCount(String table) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
    return row.read<int>('c');
  }

  group('import completeness', () {
    test('every exercise arrives', () async {
      expect(await importedCount('exercises'), await sourceCount('exercises'));
    });

    test('every translation arrives, in every language', () async {
      expect(
        await importedCount('exercise_translations'),
        await sourceCount('exercise_translations'),
      );

      // The catalog ships 22 languages. The importer has always copied them
      // all; only the read path was ever hard-wired to de/en.
      final languages = await db
          .customSelect(
            'SELECT COUNT(DISTINCT language_code) AS c FROM exercise_translations',
          )
          .getSingle();
      expect(languages.read<int>('c'), greaterThan(5));
    });

    test('every side table arrives', () async {
      for (final table in [
        'muscles',
        'muscle_translations',
        'equipment',
        'equipment_translations',
        'exercise_muscles',
        'exercise_equipment',
        'exercise_tags',
        'exercise_aliases',
      ]) {
        expect(await importedCount(table), await sourceCount(table),
            reason: 'row count mismatch for $table');
      }

      // `languages` is renamed on the way in, to keep it apart from the app's
      // own smaller set of UI locales.
      expect(
        await importedCount('catalog_languages'),
        await sourceCount('languages'),
      );
    });
  });

  group('classification lands on the exercise row', () {
    test('modality, tracking type and load mode are populated', () async {
      for (final column in [
        'modality',
        'tracking_type',
        'load_mode',
        'primary_equipment',
        'mechanic',
        'movement_pattern',
        'laterality',
      ]) {
        final expected = await sourceCount('exercises', '$column IS NOT NULL');
        final actual = await db
            .customSelect(
                'SELECT COUNT(*) AS c FROM exercises WHERE $column IS NOT NULL')
            .getSingle();
        expect(actual.read<int>('c'), expected, reason: 'lost $column');
      }
    });

    test('status and merged_into survive the trip', () async {
      final merged = await db
          .customSelect(
            "SELECT id, merged_into FROM exercises WHERE status = 'merged'",
          )
          .get();
      expect(merged, isNotEmpty);
      for (final row in merged) {
        expect(row.read<String?>('merged_into'), isNotNull);
      }

      expect(
        await db
            .customSelect(
                "SELECT COUNT(*) AS c FROM exercises WHERE status = 'deprecated'")
            .getSingle()
            .then((r) => r.read<int>('c')),
        await sourceCount('exercises', "status = 'deprecated'"),
      );
    });

    test('supports_added_weight is a boolean, not a stray zero', () async {
      final expected =
          await sourceCount('exercises', 'supports_added_weight = 1');
      final actual = await db
          .customSelect(
            'SELECT COUNT(*) AS c FROM exercises WHERE supports_added_weight = 1',
          )
          .getSingle();
      expect(actual.read<int>('c'), expected);
    });

    test('contribution stays unset rather than becoming zero', () async {
      // The catalog ships this deliberately empty. A 0.0 here would be a
      // weight of nothing, which is a different claim from no weight at all.
      final nulls = await db
          .customSelect(
            'SELECT COUNT(*) AS c FROM exercise_muscles WHERE contribution IS NULL',
          )
          .getSingle();
      expect(nulls.read<int>('c'), await importedCount('exercise_muscles'));
    });
  });

  group('v1 compatibility columns keep being written', () {
    test('category and legacy muscles are still there after a v2 import',
        () async {
      final rows = await db
          .customSelect(
            "SELECT COUNT(*) AS c FROM exercises "
            "WHERE status = 'active' AND category_name IS NOT NULL "
            "AND category_name != ''",
          )
          .getSingle();
      expect(rows.read<int>('c'),
          await sourceCount('exercises', "status = 'active'"));
    });
  });

  group('the vocabulary is replaced, not merged', () {
    test('a retired muscle does not survive a second import', () async {
      await db.into(db.muscles).insert(
            MusclesCompanion.insert(
              id: 'retired_muscle',
              level: 'muscle',
              groupId: 'chest',
            ),
          );
      expect(
        await db
            .customSelect(
                "SELECT COUNT(*) AS c FROM muscles WHERE id = 'retired_muscle'")
            .getSingle()
            .then((r) => r.read<int>('c')),
        1,
      );

      await BasisDataManager.instance
          .importExerciseCatalogFromFileForTesting(sourcePath);

      expect(
        await db
            .customSelect(
                "SELECT COUNT(*) AS c FROM muscles WHERE id = 'retired_muscle'")
            .getSingle()
            .then((r) => r.read<int>('c')),
        0,
        reason: 'the vocabulary is a closed set owned by the data repo',
      );
      expect(await importedCount('muscles'), await sourceCount('muscles'));
    });

    test('a user exercise survives the same import', () async {
      // The other half of the policy: nothing keyed by an exercise id is ever
      // removed, because those ids are a contract with the workout logs.
      await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
              id: const Value('user-made-up-id'),
              isCustom: const Value(true),
              source: const Value('user'),
            ),
          );

      await BasisDataManager.instance
          .importExerciseCatalogFromFileForTesting(sourcePath);

      final survivor = await db
          .customSelect(
            "SELECT COUNT(*) AS c FROM exercises WHERE id = 'user-made-up-id'",
          )
          .getSingle();
      expect(survivor.read<int>('c'), 1);
    });
  });

  group('importing is idempotent', () {
    test('a second run changes no row counts', () async {
      final before = <String, int>{
        for (final table in [
          'exercises',
          'exercise_translations',
          'exercise_muscles',
          'exercise_equipment',
          'exercise_tags',
          'exercise_aliases',
          'muscles',
          'catalog_languages',
        ])
          table: await importedCount(table),
      };

      await BasisDataManager.instance
          .importExerciseCatalogFromFileForTesting(sourcePath);

      for (final entry in before.entries) {
        expect(await importedCount(entry.key), entry.value,
            reason: 'second import changed ${entry.key}');
      }
    });
  });

  group('scale', () {
    test('a full build imports every one of its exercises', () async {
      expect(await importedCount('exercises'), greaterThan(900));
      expect(await importedCount('exercise_muscles'), greaterThan(3000));
      expect(await importedCount('exercise_translations'), greaterThan(5000));
    },
        skip: usingFullCatalog
            ? null
            : 'set TRAIN_LIBRE_CATALOG_DB to import the whole catalog');
  });
}
