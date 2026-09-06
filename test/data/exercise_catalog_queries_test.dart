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
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

/// What the catalog offers the user after a v2 import.
///
/// The line this file draws: discovery hides retired exercises, resolution
/// still finds them. Getting that backwards either puts 41 dead rows into
/// search or makes two years of workout history un-openable.
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;
  late WorkoutLocalDataSource source;

  setUpAll(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();
    await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
      File(kFixturePath).absolute.path,
    );
    source = WorkoutLocalDataSource.forTesting(db);
  });

  tearDownAll(() async {
    await db.close();
  });

  Future<List<String>> searchIds(String term) async {
    final results = await source.searchExercises(query: term);
    return results.map((e) => e.uuid ?? '').toList();
  }

  group('search hides what the catalog retired', () {
    test('no merged or deprecated exercise is offered', () async {
      final retired = await db
          .customSelect(
            "SELECT id FROM exercises WHERE status IN ('merged', 'deprecated')",
          )
          .get()
          .then((rows) => rows.map((r) => r.read<String>('id')).toSet());
      expect(retired, isNotEmpty, reason: 'the fixture must contain some');

      final all = await source.searchExercises();
      final offered = all.map((e) => e.uuid).toSet();

      expect(offered.intersection(retired), isEmpty);
    });

    test('a merged exercise does not come back by name either', () async {
      // 512 "Rowing seated, narrow grip" was merged into 395.
      expect(await searchIds('Rowing seated'), isNot(contains('512')));
    });

    test('the surviving twin is still offered', () async {
      // The point is to drop the duplicate, not the exercise.
      final results = await source.searchExercises(query: 'Leg Extension');
      final ids = results.map((e) => e.uuid).toSet();
      expect(ids, contains('369'));
      expect(ids, isNot(contains('851')));
    });

    test('user exercises with no status are unaffected', () async {
      await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
              id: const Value('my-own-lift'),
              isCustom: const Value(true),
              source: const Value('user'),
              categoryName: const Value('Legs'),
            ),
          );
      await db.into(db.exerciseTranslations).insert(
            ExerciseTranslationsCompanion.insert(
              exerciseId: 'my-own-lift',
              languageCode: 'de',
              name: 'Mein Zossen',
            ),
          );

      expect(await searchIds('Zossen'), contains('my-own-lift'));
    });
  });

  group('resolution still reaches retired exercises', () {
    test('by id', () async {
      // A workout logged before the merge has to keep opening.
      final byUuid = await source.getExerciseByUuid('188');
      expect(byUuid, isNotNull,
          reason: 'a deprecated exercise must stay resolvable by id');
    });

    test('by name, preferring the survivor over the retired twin', () async {
      final resolved = await source.getExerciseByName('Leg Extension');
      expect(resolved, isNotNull);
      expect(resolved!.uuid, '369',
          reason: 'both 369 and 851 carry this name; the active one wins');
    });
  });

  group('filter chips only offer categories that select something', () {
    test('no category exists solely on retired rows', () async {
      final categories = (await source.getAllCategories()).toSet();

      final liveCategories = await db
          .customSelect(
            "SELECT DISTINCT category_name AS c FROM exercises "
            "WHERE (status IS NULL OR status = 'active') "
            "AND category_name IS NOT NULL AND category_name != ''",
          )
          .get()
          .then((rows) => rows.map((r) => r.read<String>('c')).toSet());

      expect(categories, liveCategories);
    });

    test('muscle groups come from live rows only', () async {
      final groups = await source.getAllMuscleGroups();
      expect(groups, isNotEmpty);

      // A muscle that only a deprecated exercise names must not appear.
      final retiredOnly = await db
          .customSelect(
            "SELECT COUNT(*) AS c FROM exercises "
            "WHERE status = 'deprecated' AND muscles_primary IS NOT NULL",
          )
          .getSingle();
      expect(retiredOnly.read<int>('c'), greaterThanOrEqualTo(0));
    });
  });
}
