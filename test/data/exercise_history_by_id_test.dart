@TestOn('vm')
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' hide SetLog;
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;
  late WorkoutLocalDataSource source;

  setUp(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    source = WorkoutLocalDataSource.forTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> logWorkoutWithSets({
    required String logId,
    required DateTime startTime,
    required List<
            ({
              String? exerciseId,
              String name,
              double? weight,
              int? reps,
              int logOrder
            })>
        sets,
    String status = 'completed',
  }) async {
    await db.into(db.workoutLogs).insert(
          WorkoutLogsCompanion.insert(
            id: Value(logId),
            startTime: startTime,
            status: Value(status),
          ),
        );

    for (final s in sets) {
      await db.into(db.setLogs).insert(
            SetLogsCompanion.insert(
              workoutLogId: logId,
              exerciseId: Value(s.exerciseId),
              exerciseNameSnapshot: Value(s.name),
              weight: Value(s.weight),
              reps: Value(s.reps),
              logOrder: Value(s.logOrder),
              isCompleted: const Value(true),
              setType: const Value('normal'),
            ),
          );
    }
  }

  group('SetLog domain model exerciseId', () {
    test('SetLog carries exerciseId, supports fromMap, toMap, and copyWith',
        () {
      final log = SetLog(
        workoutLogId: 1,
        exerciseId: 'ex-123',
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 100,
        reps: 5,
      );
      expect(log.exerciseId, 'ex-123');

      final map = log.toMap();
      expect(map['exercise_id'], 'ex-123');

      final fromDbMap = SetLog.fromMap({
        'workout_log_id': 1,
        'exercise_id': 'ex-456',
        'exercise_name': 'Incline Bench Press',
        'set_type': 'normal',
      });
      expect(fromDbMap.exerciseId, 'ex-456');

      final fromCamelMap = SetLog.fromMap({
        'workout_log_id': 1,
        'exerciseId': 'ex-789',
        'exercise_name': 'Dumbbell Bench Press',
        'set_type': 'normal',
      });
      expect(fromCamelMap.exerciseId, 'ex-789');

      final copied = log.copyWith(exerciseId: 'ex-updated');
      expect(copied.exerciseId, 'ex-updated');

      final cleared = log.copyWith(clearExerciseId: true);
      expect(cleared.exerciseId, isNull);
    });
  });

  group('Exercise history by UUID (getLastSetsForExercise)', () {
    test(
        'Historie wird gefunden, wenn nur exercise_id passt (z.B. nach Umbenennung)',
        () async {
      // Row logged with exercise_id = 'uuid-bench', snapshot name = 'Bankdruecken' (old name)
      await logWorkoutWithSets(
        logId: 'log-1',
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        sets: [
          (
            exerciseId: 'uuid-bench',
            name: 'Bankdruecken',
            weight: 80.0,
            reps: 10,
            logOrder: 0
          ),
        ],
      );

      // Query with the same exerciseId, but a renamed snapshot name 'Bench Press'
      final result = await source.getLastSetsForExercise(
        exerciseId: 'uuid-bench',
        exerciseNameSnapshot: 'Bench Press',
      );

      expect(result, hasLength(1));
      expect(result.first.exerciseId, 'uuid-bench');
      expect(result.first.weightKg, 80.0);
      expect(result.first.reps, 10);
    });

    test(
        'Historie wird gefunden, wenn exercise_id NULL ist und nur der Name passt (Altdaten)',
        () async {
      // Legacy row: exercise_id is NULL, only exercise_name_snapshot is populated
      await logWorkoutWithSets(
        logId: 'log-legacy',
        startTime: DateTime.now().subtract(const Duration(days: 5)),
        sets: [
          (
            exerciseId: null,
            name: 'Squat',
            weight: 120.0,
            reps: 5,
            logOrder: 0
          ),
        ],
      );

      // Querying with an exerciseId (e.g. resolved in catalog) and matching name snapshot finds the legacy set
      final resultWithId = await source.getLastSetsForExercise(
        exerciseId: 'uuid-squat',
        exerciseNameSnapshot: 'Squat',
      );
      expect(resultWithId, hasLength(1));
      expect(resultWithId.first.exerciseId, isNull);
      expect(resultWithId.first.exerciseName, 'Squat');
      expect(resultWithId.first.weightKg, 120.0);

      // Querying with null exerciseId also finds it
      final resultWithoutId = await source.getLastSetsForExercise(
        exerciseId: null,
        exerciseNameSnapshot: 'Squat',
      );
      expect(resultWithoutId, hasLength(1));
      expect(resultWithoutId.first.weightKg, 120.0);
    });

    test(
        'Historie wird NICHT gefunden, wenn eine andere Uebung denselben Namen traegt, aber eine andere exercise_id hat',
        () async {
      // Row logged for a different exercise that happened to share the same name, but with another ID
      await logWorkoutWithSets(
        logId: 'log-collision',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        sets: [
          (
            exerciseId: 'uuid-other-exercise',
            name: 'Shoulder Press',
            weight: 50.0,
            reps: 8,
            logOrder: 0
          ),
        ],
      );

      // Query for 'uuid-my-exercise' with snapshot name 'Shoulder Press'
      final result = await source.getLastSetsForExercise(
        exerciseId: 'uuid-my-exercise',
        exerciseNameSnapshot: 'Shoulder Press',
      );

      // Must not match the other exercise's history
      expect(result, isEmpty);
    });

    test(
        'Gemischter Fall: alte namensbasierte und neue id-basierte Zeilen derselben Uebung liefern zusammen das erwartete Ergebnis',
        () async {
      // In a workout session, a legacy set (no exercise_id) and a new set (with exercise_id) exist for the same exercise
      await logWorkoutWithSets(
        logId: 'log-mixed',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        sets: [
          (
            exerciseId: null,
            name: 'Deadlift',
            weight: 140.0,
            reps: 5,
            logOrder: 0
          ),
          (
            exerciseId: 'uuid-deadlift',
            name: 'Deadlift',
            weight: 150.0,
            reps: 5,
            logOrder: 1
          ),
        ],
      );

      final result = await source.getLastSetsForExercise(
        exerciseId: 'uuid-deadlift',
        exerciseNameSnapshot: 'Deadlift',
      );

      expect(result, hasLength(2));
      expect(result[0].exerciseId, isNull);
      expect(result[0].weightKg, 140.0);
      expect(result[1].exerciseId, 'uuid-deadlift');
      expect(result[1].weightKg, 150.0);
    });

    test(
        'Gemischter Fall ueber mehrere Workouts: neues Workout mit ID ueberschreibt aelteres Workout ohne ID',
        () async {
      // Older workout has legacy rows (exercise_id is null)
      await logWorkoutWithSets(
        logId: 'log-old',
        startTime: DateTime.now().subtract(const Duration(days: 7)),
        sets: [
          (
            exerciseId: null,
            name: 'Bench Press',
            weight: 70.0,
            reps: 10,
            logOrder: 0
          ),
        ],
      );

      // Newer workout has ID-based rows
      await logWorkoutWithSets(
        logId: 'log-recent',
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        sets: [
          (
            exerciseId: 'uuid-bench',
            name: 'Bench Press',
            weight: 75.0,
            reps: 8,
            logOrder: 0
          ),
        ],
      );

      // Query should return sets from the most recent workout (log-recent)
      final result = await source.getLastSetsForExercise(
        exerciseId: 'uuid-bench',
        exerciseNameSnapshot: 'Bench Press',
      );

      expect(result, hasLength(1));
      expect(result.first.exerciseId, 'uuid-bench');
      expect(result.first.weightKg, 75.0);
    });
  });
}
