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
import 'package:train_libre/features/exercise_catalog/domain/exercise_alias_migration.dart';

/// The only path in this migration that rewrites user data.
///
/// Real alias rows from a real build back these tests: 512 → 395 (a plain
/// merge) and 1793 → 1778, 1800 → 1778 (two ids collapsing into one, which is
/// where a routine ends up holding the same exercise twice).
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;

  /// A routine holding [exerciseIds], returning the routine_exercises uuids.
  Future<List<String>> seedRoutine(
    String routineId,
    List<String> exerciseIds,
  ) async {
    await db.into(db.routines).insert(
          RoutinesCompanion.insert(id: Value(routineId), name: routineId),
        );
    final ids = <String>[];
    for (var i = 0; i < exerciseIds.length; i++) {
      final uuid = '$routineId-slot-$i';
      await db.into(db.routineExercises).insert(
            RoutineExercisesCompanion.insert(
              id: Value(uuid),
              routineId: routineId,
              exerciseId: exerciseIds[i],
              orderIndex: i,
            ),
          );
      ids.add(uuid);
    }
    return ids;
  }

  Future<void> seedSetTemplate(String routineExerciseId) async {
    await db.into(db.routineSetTemplates).insert(
          RoutineSetTemplatesCompanion.insert(
            routineExerciseId: routineExerciseId,
            targetReps: const Value('8-12'),
            targetWeight: const Value(60),
          ),
        );
  }

  Future<void> seedSetLog(String exerciseId, String snapshotName) async {
    await db.into(db.workoutLogs).insert(
          WorkoutLogsCompanion.insert(
            id: Value('log-for-$exerciseId'),
            startTime: DateTime(2026, 8, 1),
          ),
        );
    await db.into(db.setLogs).insert(
          SetLogsCompanion.insert(
            workoutLogId: 'log-for-$exerciseId',
            exerciseId: Value(exerciseId),
            exerciseNameSnapshot: Value(snapshotName),
            weight: const Value(60),
            reps: const Value(10),
          ),
        );
  }

  Future<List<String>> exerciseIdsIn(String routineId) async {
    final rows = await db.customSelect(
      'SELECT exercise_id FROM routine_exercises WHERE routine_id = ? '
      'ORDER BY order_index',
      variables: [Variable.withString(routineId)],
    ).get();
    return rows.map((r) => r.read<String>('exercise_id')).toList();
  }

  Future<int> countWhere(String sql) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $sql').getSingle();
    return row.read<int>('c');
  }

  setUp(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();

    await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
      File(kFixturePath).absolute.path,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('preconditions', () {
    test('the fixture really carries the alias rows these tests rely on',
        () async {
      final rows = await db
          .customSelect(
            "SELECT old_id, new_id FROM exercise_aliases "
            "WHERE old_id IN ('512', '1793', '1800')",
          )
          .get();
      final map = {
        for (final row in rows)
          row.read<String>('old_id'): row.read<String>('new_id'),
      };
      expect(map['512'], '395');
      expect(map['1793'], '1778');
      expect(map['1800'], '1778');
    });
  });

  group('rewriting user data', () {
    test('routine entries and set logs move to the surviving exercise',
        () async {
      await seedRoutine('r1', ['512']);
      await seedSetLog('512', 'Rowing seated, narrow grip');

      final result = await const ExerciseAliasMigration().run(db);

      expect(await exerciseIdsIn('r1'), ['395']);
      expect(
        await countWhere("set_logs WHERE exercise_id = '395'"),
        1,
      );
      expect(await countWhere("set_logs WHERE exercise_id = '512'"), 0);
      expect(result.routineExercisesRewritten, 1);
      expect(result.setLogsRewritten, 1);
    });

    test('the name snapshot is left alone', () async {
      // It records what the user picked at the time. An alias may move the
      // pointer; it may not rewrite history.
      await seedSetLog('512', 'Rowing seated, narrow grip');

      await const ExerciseAliasMigration().run(db);

      final row = await db
          .customSelect(
            "SELECT exercise_name_snapshot AS s FROM set_logs "
            "WHERE exercise_id = '395'",
          )
          .getSingle();
      expect(row.read<String>('s'), 'Rowing seated, narrow grip');
    });

    test('a user override follows its base exercise', () async {
      await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
              id: const Value('my-own-row'),
              isCustom: const Value(true),
              source: const Value('user'),
              replacesExerciseId: const Value('512'),
            ),
          );

      final result = await const ExerciseAliasMigration().run(db);

      final row = await db
          .customSelect(
            "SELECT replaces_exercise_id AS r FROM exercises "
            "WHERE id = 'my-own-row'",
          )
          .getSingle();
      expect(row.read<String>('r'), '395');
      expect(result.overridesRewritten, 1);
    });

    test('nothing anywhere still points at a retired id', () async {
      await seedRoutine('r1', ['512', '1793', '1800']);
      await seedSetLog('512', 'a');

      await const ExerciseAliasMigration().run(db);

      expect(
        await countWhere(
          'routine_exercises WHERE exercise_id IN '
          '(SELECT old_id FROM exercise_aliases)',
        ),
        0,
      );
      expect(
        await countWhere(
          'set_logs WHERE exercise_id IN (SELECT old_id FROM exercise_aliases)',
        ),
        0,
      );
      expect(
        await countWhere(
          'exercises WHERE replaces_exercise_id IN '
          '(SELECT old_id FROM exercise_aliases)',
        ),
        0,
      );
    });
  });

  group('two ids collapsing into one', () {
    test('an empty duplicate slot is removed', () async {
      final slots = await seedRoutine('r2', ['1793', '1800']);
      await seedSetTemplate(slots[0]);

      final result = await const ExerciseAliasMigration().run(db);

      expect(await exerciseIdsIn('r2'), ['1778']);
      expect(result.duplicateSlotsRemoved, 1);
      // The survivor keeps what the user configured.
      expect(await countWhere('routine_set_templates'), 1);
    });

    test('a duplicate carrying planned sets is kept, not collapsed', () async {
      // routine_set_templates cascades off routine_exercises, so deleting the
      // losing row would silently delete the user's planned sets with it. Two
      // identically named entries are confusing and fixable in two taps; a
      // deleted set scheme is neither.
      final slots = await seedRoutine('r2', ['1793', '1800']);
      await seedSetTemplate(slots[0]);
      await seedSetTemplate(slots[1]);

      final result = await const ExerciseAliasMigration().run(db);

      expect(await exerciseIdsIn('r2'), ['1778', '1778']);
      expect(result.duplicateSlotsRemoved, 0);
      expect(result.duplicateSlotsKept, 1);
      expect(await countWhere('routine_set_templates'), 2);
    });

    test('a duplicate carrying a note is kept too', () async {
      await db.into(db.routines).insert(
            RoutinesCompanion.insert(id: const Value('r3'), name: 'r3'),
          );
      await db.into(db.routineExercises).insert(
            RoutineExercisesCompanion.insert(
              id: const Value('r3-a'),
              routineId: 'r3',
              exerciseId: '1793',
              orderIndex: 0,
            ),
          );
      await db.into(db.routineExercises).insert(
            RoutineExercisesCompanion.insert(
              id: const Value('r3-b'),
              routineId: 'r3',
              exerciseId: '1800',
              orderIndex: 1,
              notes: const Value('drop set on the last one'),
            ),
          );

      await const ExerciseAliasMigration().run(db);

      expect(await exerciseIdsIn('r3'), ['1778', '1778']);
    });

    test('the same exercise in two different routines is not touched',
        () async {
      await seedRoutine('r1', ['1793']);
      await seedRoutine('r2', ['1800']);

      final result = await const ExerciseAliasMigration().run(db);

      expect(await exerciseIdsIn('r1'), ['1778']);
      expect(await exerciseIdsIn('r2'), ['1778']);
      expect(result.duplicateSlotsRemoved, 0);
    });
  });

  group('safety', () {
    test('an alias whose target is missing leaves its rows alone', () async {
      await db.into(db.exerciseAliases).insert(
            ExerciseAliasesCompanion.insert(
              oldId: '512',
              newId: 'a-target-that-does-not-exist',
            ),
            mode: InsertMode.insertOrReplace,
          );
      await seedRoutine('r1', ['512']);

      final result = await const ExerciseAliasMigration().run(db);

      // Better a stale pointer than a routine entry aimed at nothing.
      expect(await exerciseIdsIn('r1'), ['512']);
      expect(result.skippedMissingTarget, 1);
    });

    test('running twice changes nothing the second time', () async {
      await seedRoutine('r1', ['512']);
      await seedRoutine('r2', ['1793', '1800']);
      await seedSetLog('512', 'a');

      await const ExerciseAliasMigration().run(db);
      final after = await exerciseIdsIn('r2');
      final second = await const ExerciseAliasMigration().run(db);

      expect(second.routineExercisesRewritten, 0);
      expect(second.setLogsRewritten, 0);
      expect(second.overridesRewritten, 0);
      expect(second.duplicateSlotsRemoved, 0);
      expect(await exerciseIdsIn('r2'), after);
      expect(await exerciseIdsIn('r1'), ['395']);
    });

    test('an empty alias register is a no-op', () async {
      await db.delete(db.exerciseAliases).go();
      await seedRoutine('r1', ['512']);

      final result = await const ExerciseAliasMigration().run(db);

      expect(result.routineExercisesRewritten, 0);
      expect(await exerciseIdsIn('r1'), ['512']);
    });

    test('the importer applies the register on its own', () async {
      // The rewrite has to be part of the import, not a step someone has to
      // remember to call.
      await seedRoutine('r1', ['512']);

      await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
        File(kFixturePath).absolute.path,
      );

      expect(await exerciseIdsIn('r1'), ['395']);
    });
  });
}
