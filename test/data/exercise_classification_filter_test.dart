@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/exercise_catalog/domain/exercise_locale_chain.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

/// Filtering by what the catalog says a movement *is*.
///
/// Mechanic, sides and difficulty are annotated on 877 of the catalog's 909
/// exercises and were imported into Drift from the day schema v2 landed, but
/// nothing read them. These are the queries that changed that.
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
    ExerciseLocaleChain.invalidate();
    await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
      File(kFixturePath).absolute.path,
    );
    ExerciseLocaleChain.invalidate();
    source = WorkoutLocalDataSource.forTesting(db);
  });

  tearDownAll(() async {
    await db.close();
    ExerciseLocaleChain.invalidate();
  });

  group('what the filter offers', () {
    test('each axis offers only values that occur on live exercises', () async {
      final axes = await source.getClassificationAxes();
      expect(axes.difficulties, isNotEmpty);
      expect(axes.mechanics, isNotEmpty);

      for (final entry in [
        (column: 'difficulty', values: axes.difficulties),
        (column: 'mechanic', values: axes.mechanics),
        (column: 'laterality', values: axes.lateralities),
      ]) {
        for (final value in entry.values) {
          final row = await db.customSelect(
            'SELECT COUNT(*) AS c FROM exercises e '
            "WHERE e.${entry.column} = ? "
            "AND (e.status IS NULL OR e.status = 'active')",
            variables: [Variable.withString(value)],
          ).getSingle();
          expect(row.read<int>('c'), greaterThan(0),
              reason: '${entry.column}=$value is a chip that selects nothing');
        }
      }
    });

    test('difficulty comes back in vocabulary order, not alphabetical',
        () async {
      // Alphabetically "advanced" sorts first, which reads as a mistake in a
      // menu whose whole point is that it is a ladder.
      final axes = await source.getClassificationAxes();
      const order = ['beginner', 'intermediate', 'advanced'];
      final ranks = axes.difficulties.map(order.indexOf).toList();
      expect(ranks, everyElement(greaterThanOrEqualTo(0)),
          reason: 'unexpected difficulty value: ${axes.difficulties}');
      expect(ranks, equals(ranks.toList()..sort()));
    });

    test('no axis offers a value twice', () async {
      final axes = await source.getClassificationAxes();
      for (final values in [
        axes.difficulties,
        axes.mechanics,
        axes.lateralities
      ]) {
        expect(values.toSet().length, values.length);
      }
    });
  });

  group('filtering', () {
    test('a mechanic filter returns only that mechanic', () async {
      final all = await source.searchExercises();
      final filtered = await source.searchExercises(mechanics: ['isolation']);

      expect(filtered, isNotEmpty);
      expect(filtered.length, lessThan(all.length));
      for (final exercise in filtered) {
        expect(exercise.mechanic, 'isolation', reason: exercise.uuid);
      }
    });

    test('a difficulty filter returns only that difficulty', () async {
      final filtered = await source.searchExercises(difficulties: ['beginner']);
      expect(filtered, isNotEmpty);
      for (final exercise in filtered) {
        expect(exercise.difficulty, 'beginner', reason: exercise.uuid);
      }
    });

    test('two values in one axis widen, values across axes narrow', () async {
      final beginner = await source.searchExercises(difficulties: ['beginner']);
      final intermediate =
          await source.searchExercises(difficulties: ['intermediate']);
      final both = await source
          .searchExercises(difficulties: ['beginner', 'intermediate']);
      expect(both.length, beginner.length + intermediate.length);

      final beginnerCompound = await source.searchExercises(
        difficulties: ['beginner'],
        mechanics: ['compound'],
      );
      expect(beginnerCompound.length, lessThanOrEqualTo(beginner.length));
      for (final exercise in beginnerCompound) {
        expect(exercise.difficulty, 'beginner');
        expect(exercise.mechanic, 'compound');
      }
    });

    test('unclassified exercises drop out of an axis filter', () async {
      // `IN` never matches NULL, and the fixture carries rows with no
      // classification at all. Hiding them is the honest answer — the app
      // does not know how hard they are — but it has to be deliberate.
      final unclassified = await db
          .customSelect('SELECT COUNT(*) AS c FROM exercises '
              'WHERE difficulty IS NULL')
          .getSingle();
      expect(unclassified.read<int>('c'), greaterThan(0),
          reason: 'fixture no longer covers the unclassified case');

      final filtered = await source.searchExercises(
        difficulties: ['beginner', 'intermediate', 'advanced'],
      );
      for (final exercise in filtered) {
        expect(exercise.difficulty, isNotNull);
      }
    });

    test('the axes combine with equipment, tags and the search text', () async {
      // Where a mis-ordered placeholder in the generated SQL would show up:
      // the axis values bind last, after the query tokens and the two EXISTS
      // subqueries.
      final tags = await source.getUsageTags();
      final equipment = await source.getPrimaryEquipment('en');

      final combined = await source.searchExercises(
        query: 'press',
        equipmentIds: [equipment.first.id],
        usageTags: [tags.first],
        mechanics: ['compound'],
        lateralities: ['bilateral'],
      );

      for (final exercise in combined) {
        expect(exercise.mechanic, 'compound');
        expect(exercise.laterality, 'bilateral');
        expect(exercise.allNames.any((n) => n.toLowerCase().contains('press')),
            isTrue);
      }
    });

    test('an empty axis list changes nothing', () async {
      final unfiltered = await source.searchExercises();
      final explicitlyEmpty = await source.searchExercises(
        difficulties: const [],
        mechanics: const [],
        lateralities: const [],
      );
      expect(explicitlyEmpty.length, unfiltered.length);
    });
  });

  group('the annotation reaches the model', () {
    test('search rows carry mechanic, sides and difficulty', () async {
      final results = await source.searchExercises(mechanics: ['compound']);
      expect(results, isNotEmpty);
      // The list path maps a raw query row by hand, so it is the one that
      // silently drops a column when a field is added to the model.
      expect(results.where((e) => e.difficulty != null), isNotEmpty);
      expect(results.where((e) => e.laterality != null), isNotEmpty);
    });

    test('the two display-only axes travel with the rest', () async {
      // Nothing filters or computes on movement pattern or force vector — the
      // detail screen is their only reader — but they ride the same two
      // mappers, which is where a newly added field silently gets dropped.
      final results = await source.searchExercises();
      expect(results.where((e) => e.movementPattern != null), isNotEmpty);
      expect(results.where((e) => e.forceVector != null), isNotEmpty);

      final loaded = await source.getExerciseByUuid(
        results.firstWhere((e) => e.movementPattern != null).uuid!,
      );
      expect(loaded!.movementPattern, isNotNull);
    });

    test('the single-exercise path carries them too', () async {
      final fromSearch =
          (await source.searchExercises(mechanics: ['isolation'])).first;
      final loaded = await source.getExerciseByUuid(fromSearch.uuid!);
      expect(loaded, isNotNull);
      expect(loaded!.mechanic, fromSearch.mechanic);
      expect(loaded.laterality, fromSearch.laterality);
      expect(loaded.difficulty, fromSearch.difficulty);
    });
  });
}
