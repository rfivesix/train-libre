import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart' show AppDatabase;
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart'
    as model;
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';

/// What survives when the app is killed mid-workout.
///
/// The running session lives in the database as a flat list of set rows; the
/// view model rebuilds the exercises, their order and their pauses from it on
/// the next start. Every test here kills the view model and builds a fresh one
/// on the same database, which is what iOS does to the process when the user
/// swipes the app away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late WorkoutLocalDataSource workoutDb;
  late LiveWorkoutViewModel manager;

  LiveWorkoutViewModel buildManager() => LiveWorkoutViewModel.forTesting(
        workoutDb: WorkoutRepository(
          localDataSource: WorkoutLocalDataSource(database),
        ),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    workoutDb = WorkoutLocalDataSource.forTesting(database);
    manager = buildManager();
  });

  tearDown(() async {
    manager.dispose();
    await database.close();
  });

  /// Kills the session the way the OS does and returns a view model that only
  /// knows what reached the database.
  Future<LiveWorkoutViewModel> restartApp() async {
    manager.dispose();
    manager = buildManager();
    await manager.tryRestoreSession();
    return manager;
  }

  model.Exercise exerciseNamed(String name, int id) => model.Exercise(
        id: id,
        texts: {
          'de': model.ExerciseText(name: name, description: ''),
          'en': model.ExerciseText(name: name, description: ''),
        },
        categoryName: 'Strength',
        primaryMuscles: const ['chest'],
        secondaryMuscles: const [],
      );

  RoutineExercise routineExercise({
    required int id,
    required String name,
    required int exerciseId,
    required int pauseSeconds,
    required List<int> templateIds,
    int? supersetGroup,
  }) =>
      RoutineExercise(
        id: id,
        exercise: exerciseNamed(name, exerciseId),
        pauseSeconds: pauseSeconds,
        supersetGroup: supersetGroup,
        setTemplates: [
          for (final templateId in templateIds)
            SetTemplate(id: templateId, setType: 'normal', targetReps: '8'),
        ],
      );

  /// Sets in the order they appear on screen, exercise by exercise.
  List<SetLog> setsOf(LiveWorkoutViewModel vm, int exerciseIndex) => [
        for (final template in vm.exercises[exerciseIndex].setTemplates)
          vm.setLogs[template.id]!,
      ];

  Future<WorkoutLog> startSession() async {
    final log = await workoutDb.startWorkout(routineName: 'Push A');
    await manager.startWorkout(log, [
      routineExercise(
        id: 100,
        name: 'Bench Press',
        exerciseId: 1,
        pauseSeconds: 60,
        templateIds: [1001, 1002, 1003],
      ),
      routineExercise(
        id: 200,
        name: 'Squat',
        exerciseId: 2,
        pauseSeconds: 90,
        templateIds: [2001, 2002, 2003],
      ),
      routineExercise(
        id: 300,
        name: 'Barbell Row',
        exerciseId: 3,
        pauseSeconds: 120,
        templateIds: [3001, 3002, 3003],
      ),
    ]);
    return log;
  }

  test('a killed session comes back with its exercises in the same order',
      () async {
    await startSession();

    final restored = await restartApp();

    expect(
      [for (final e in restored.exercises) e.exercise.canonicalName],
      ['Bench Press', 'Squat', 'Barbell Row'],
    );
    expect(
        [for (final e in restored.exercises) e.setTemplates.length], [3, 3, 3]);
  });

  test('a killed session restores its superset snapshot exactly', () async {
    final log = await workoutDb.startWorkout(routineName: 'Superset');
    await manager.startWorkout(log, [
      routineExercise(
        id: 100,
        name: 'Bench Press',
        exerciseId: 1,
        pauseSeconds: 60,
        templateIds: [1001, 1002],
        supersetGroup: 4,
      ),
      routineExercise(
        id: 200,
        name: 'Squat',
        exerciseId: 2,
        pauseSeconds: 90,
        templateIds: [2001, 2002],
        supersetGroup: 4,
      ),
    ]);

    final restored = await restartApp();

    expect(restored.exercises.map((e) => e.supersetGroup), [4, 4]);
    expect(restored.setLogs.values.map((s) => s.supersetGroup).toSet(), {4});
  });

  test('values typed but never ticked off survive the kill', () async {
    await startSession();

    // Nothing is completed here on purpose: the user was mid-set when the app
    // went away, and what they had typed is exactly what used to be lost.
    await manager.updateSet(1002, weight: 80, reps: 9, rir: 2);
    await manager.updateSet(3001, weight: 60, reps: 12);

    final restored = await restartApp();

    final benchSets = setsOf(restored, 0);
    expect(benchSets[1].weightKg, 80);
    expect(benchSets[1].reps, 9);
    expect(benchSets[1].rir, 2);
    expect(benchSets[1].isCompleted, isFalse);

    final rowSets = setsOf(restored, 2);
    expect(rowSets[0].weightKg, 60);
    expect(rowSets[0].reps, 12);

    // The values landed on the right sets, not just somewhere in the session.
    expect(benchSets[0].weightKg, isNull);
    expect(benchSets[2].weightKg, isNull);
  });

  test('per-exercise pauses survive the kill', () async {
    await startSession();
    await manager.updatePauseTime(200, 150);

    final restored = await restartApp();

    expect(
      [for (final e in restored.exercises) e.pauseSeconds],
      [60, 150, 120],
    );
    for (final e in restored.exercises) {
      expect(restored.pauseTimes[e.id!], e.pauseSeconds);
    }
  });

  test('a set added mid-workout stays on its own exercise', () async {
    await startSession();

    // The added set used to be stored as if it came last in the whole workout,
    // which tore Bench Press into two exercises on the next start.
    await manager.addSetToExercise(100);

    final restored = await restartApp();

    expect(
      [for (final e in restored.exercises) e.exercise.canonicalName],
      ['Bench Press', 'Squat', 'Barbell Row'],
    );
    expect(
        [for (final e in restored.exercises) e.setTemplates.length], [4, 3, 3]);
  });

  test('a reorder survives the kill', () async {
    await startSession();
    await manager.reorderExercise(2, 0);

    final restored = await restartApp();

    expect(
      [for (final e in restored.exercises) e.exercise.canonicalName],
      ['Barbell Row', 'Bench Press', 'Squat'],
    );
    expect(
      [for (final e in restored.exercises) e.pauseSeconds],
      [120, 60, 90],
    );
  });

  test('a removed set does not come back', () async {
    await startSession();
    await manager.updateSet(1001, weight: 100, reps: 5);
    await manager.removeSet(1002);

    final restored = await restartApp();

    expect(restored.exercises.first.setTemplates.length, 2);
    expect(setsOf(restored, 0).first.weightKg, 100);
    expect(
        [for (final e in restored.exercises) e.setTemplates.length], [2, 3, 3]);
  });

  test('the same exercise entered twice stays two exercises', () async {
    final log = await workoutDb.startWorkout(routineName: 'Push A');
    await manager.startWorkout(log, [
      routineExercise(
        id: 100,
        name: 'Bench Press',
        exerciseId: 1,
        pauseSeconds: 60,
        templateIds: [1001, 1002],
      ),
      routineExercise(
        id: 200,
        name: 'Bench Press',
        exerciseId: 1,
        pauseSeconds: 30,
        templateIds: [2001, 2002],
      ),
    ]);

    final restored = await restartApp();

    // Grouping the rows by exercise name collapsed these into one block of
    // four sets and lost the second entry's pause with it.
    expect(restored.exercises.length, 2);
    expect([for (final e in restored.exercises) e.setTemplates.length], [2, 2]);
    expect([for (final e in restored.exercises) e.pauseSeconds], [60, 30]);
  });

  test('the whole session survives a full round of edits', () async {
    await startSession();

    await manager.updateSet(1001, weight: 100, reps: 5, isCompleted: true);
    await manager.updateSet(1002, weight: 100, reps: 4, rir: 1);
    await manager.updatePauseTime(300, 45);
    await manager.addSetToExercise(200);
    await manager.removeSet(3003);
    await manager.reorderExercise(2, 0);

    final restored = await restartApp();

    expect(
      [for (final e in restored.exercises) e.exercise.canonicalName],
      ['Barbell Row', 'Bench Press', 'Squat'],
    );
    expect(
        [for (final e in restored.exercises) e.setTemplates.length], [2, 3, 4]);
    expect([for (final e in restored.exercises) e.pauseSeconds], [45, 60, 90]);

    final benchSets = setsOf(restored, 1);
    expect(benchSets[0].weightKg, 100);
    expect(benchSets[0].reps, 5);
    expect(benchSets[0].isCompleted, isTrue);
    expect(benchSets[1].reps, 4);
    expect(benchSets[1].rir, 1);
    expect(benchSets[2].weightKg, isNull);
  });

  test('restoring twice in a row changes nothing', () async {
    await startSession();
    await manager.updateSet(2002, weight: 70, reps: 8);
    await manager.addSetToExercise(100);

    final first = await restartApp();
    final firstShape = [
      for (final e in first.exercises)
        '${e.exercise.canonicalName}:${e.setTemplates.length}:${e.pauseSeconds}',
    ];

    final second = await restartApp();
    final secondShape = [
      for (final e in second.exercises)
        '${e.exercise.canonicalName}:${e.setTemplates.length}:${e.pauseSeconds}',
    ];

    expect(secondShape, firstShape);
    expect(setsOf(second, 1)[1].weightKg, 70);
  });

  group('sessions started before the exercise block was recorded', () {
    /// Blanks the columns the way rows written by an older build look: no
    /// position, no exercise block.
    Future<void> makeSessionLookLegacy() async {
      await database.customStatement(
        'UPDATE set_logs SET log_order = 0, exercise_block = NULL',
      );
    }

    test('are restored in the order their rows were written', () async {
      await startSession();
      await manager.updateSet(2001, weight: 70, reps: 8);
      await makeSessionLookLegacy();

      final restored = await restartApp();

      expect(
        [for (final e in restored.exercises) e.exercise.canonicalName],
        ['Bench Press', 'Squat', 'Barbell Row'],
      );
      expect([for (final e in restored.exercises) e.setTemplates.length],
          [3, 3, 3]);
      expect(setsOf(restored, 1).first.weightKg, 70);
    });

    test('are written down on the first restore so the next one is exact',
        () async {
      await startSession();
      await makeSessionLookLegacy();

      await restartApp();

      final rows = await database.select(database.setLogs).get();
      expect(
          rows.map((r) => r.exerciseBlock).toList(), everyElement(isNotNull));
      expect(
        rows.map((r) => r.exerciseBlock).toSet(),
        {0, 1, 2},
        reason: 'the three exercises must be told apart from now on',
      );
      expect(rows.map((r) => r.logOrder).toSet().length, rows.length,
          reason: 'every set needs a position of its own');
    });
  });

  test('reopening an ongoing workout does not duplicate its sets', () async {
    final log = await startSession();
    await manager.updateSet(1001, weight: 100, reps: 5);

    // A view model that never restored — the startup restore failed, or the
    // screen opened before it ran — used to lay a second set of empty rows on
    // top of the ones already stored.
    manager.dispose();
    manager = buildManager();
    await manager.loadInitialData(log, [
      routineExercise(
        id: 100,
        name: 'Bench Press',
        exerciseId: 1,
        pauseSeconds: 60,
        templateIds: [1001, 1002, 1003],
      ),
    ]);

    final rows = await database.select(database.setLogs).get();
    expect(rows.length, 9);
    expect(manager.exercises.length, 3);
    expect(setsOf(manager, 0).first.weightKg, 100);
  });

  test('a finished workout is not treated as an ongoing one', () async {
    await startSession();
    await manager.updateSet(1001, weight: 100, reps: 5, isCompleted: true);
    await manager.finishWorkout(title: 'Done');

    final restored = await restartApp();

    expect(restored.workoutLog, isNull);
    expect(restored.exercises, isEmpty);
  });

  test('set rows come back in a stable order even with equal positions',
      () async {
    // Guards the query itself: ordering on log_order alone left SQLite free to
    // return equal rows in any order it liked.
    await startSession();
    await database.customStatement('UPDATE set_logs SET log_order = 0');

    final first = await workoutDb.getSetLogsForWorkout(
      (await workoutDb.getOngoingWorkout())!.id!,
    );
    final second = await workoutDb.getSetLogsForWorkout(
      (await workoutDb.getOngoingWorkout())!.id!,
    );

    expect(first.map((s) => s.id).toList(), second.map((s) => s.id).toList());
    expect(
      first.map((s) => s.id).toList(),
      [for (final s in first) s.id]..sort((a, b) => a!.compareTo(b!)),
    );
  });

  test('an exercise added mid-workout survives the kill', () async {
    await startSession();
    await manager.updateSet(1001, weight: 100, reps: 5, isCompleted: true);
    await manager.addExercise(exerciseNamed('Overhead Press', 4));

    final beforeKill = [
      for (final e in manager.exercises) e.exercise.canonicalName,
    ];

    final restored = await restartApp();

    expect([for (final e in restored.exercises) e.exercise.canonicalName],
        beforeKill);
    expect(restored.exercises.length, 4);
  });

  test('an exercise removed mid-workout stays gone', () async {
    await startSession();
    await manager.removeExercise(200);

    final restored = await restartApp();

    expect(
      [for (final e in restored.exercises) e.exercise.canonicalName],
      ['Bench Press', 'Barbell Row'],
    );
    expect([for (final e in restored.exercises) e.pauseSeconds], [60, 120]);
  });
}
