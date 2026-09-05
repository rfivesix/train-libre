import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> insertExercise(
      db.AppDatabase database, String id, String name) async {
    await database.into(database.exercises).insert(
          db.ExercisesCompanion.insert(
            id: Value(id),
            isCustom: const Value(true),
            source: const Value('user'),
            categoryName: const Value('Strength'),
          ),
        );
    await database.into(database.exerciseTranslations).insert(
          db.ExerciseTranslationsCompanion.insert(
            exerciseId: id,
            languageCode: 'en',
            name: name,
          ),
        );
  }

  test('routine group survives save, load and duplicate', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final source = WorkoutLocalDataSource.forTesting(database);
    await insertExercise(database, 'exercise-a', 'Exercise A');
    await insertExercise(database, 'exercise-b', 'Exercise B');

    final routine = await source.createRoutine('Grouped');
    final a = await source.addExerciseToRoutine(routine.id!, 1);
    final b = await source.addExerciseToRoutine(routine.id!, 2);
    await source.updateExerciseOrder(routine.id!, [
      a!.copyWith(supersetGroup: 1),
      b!.copyWith(supersetGroup: 1),
    ]);

    final loaded = await source.getRoutineById(routine.id!);
    expect(loaded!.exercises.map((e) => e.supersetGroup), [1, 1]);

    await source.duplicateRoutine(routine.id!);
    final duplicate = await source.getRoutineByName('Grouped (Kopie)');
    expect(duplicate!.exercises.map((e) => e.supersetGroup), [1, 1]);
  });

  test('migration 28 to 29 retains rows and initializes groups to null',
      () async {
    final dir = await Directory.systemTemp.createTemp('superset_migration');
    final file = File('${dir.path}/app.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var database = db.AppDatabase(NativeDatabase(file));
    final source = WorkoutLocalDataSource.forTesting(database);
    await insertExercise(database, 'exercise-a', 'Exercise A');
    final routine = await source.createRoutine('Legacy');
    await source.addExerciseToRoutine(routine.id!, 1);
    await database.customStatement(
      'ALTER TABLE routine_exercises DROP COLUMN superset_group;',
    );
    await database.customStatement(
      'ALTER TABLE set_logs DROP COLUMN superset_group;',
    );
    await database.customStatement('PRAGMA user_version = 28;');
    await database.close();

    database = db.AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    final migratedSource = WorkoutLocalDataSource.forTesting(database);
    final loaded = await migratedSource.getRoutineById(routine.id!);

    expect(database.schemaVersion, 29);
    expect(loaded, isNotNull);
    expect(loaded!.exercises.single.supersetGroup, isNull);
    final setColumns =
        await database.customSelect('PRAGMA table_info(set_logs);').get();
    expect(
      setColumns.map((row) => row.read<String>('name')),
      contains('superset_group'),
    );
  });
}
