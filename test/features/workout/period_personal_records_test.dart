@TestOn('vm')
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/exercise_catalog/domain/exercise_metrics.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

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

  Future<void> exercise(
    String id, {
    required String trackingType,
    String loadMode = 'external',
    String? categoryName,
  }) async {
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: Value(id),
            trackingType: Value(trackingType),
            loadMode: Value(loadMode),
            categoryName: Value(categoryName),
          ),
        );
  }

  var logSeq = 0;

  Future<void> logWorkout(
    DateTime startTime,
    List<
      ({
        String exerciseId,
        double? weight,
        int? reps,
        double? distance,
        int? durationSeconds,
      })
    >
    sets,
  ) async {
    final logId = 'log-${logSeq++}';
    await db
        .into(db.workoutLogs)
        .insert(
          WorkoutLogsCompanion.insert(
            id: Value(logId),
            startTime: startTime,
            status: const Value('completed'),
          ),
        );
    for (var i = 0; i < sets.length; i++) {
      final s = sets[i];
      await db
          .into(db.setLogs)
          .insert(
            SetLogsCompanion.insert(
              workoutLogId: logId,
              exerciseId: Value(s.exerciseId),
              exerciseNameSnapshot: Value(s.exerciseId),
              weight: Value(s.weight),
              reps: Value(s.reps),
              distance: Value(s.distance),
              durationSeconds: Value(s.durationSeconds),
              logOrder: Value(i),
              isCompleted: const Value(true),
              setType: const Value('normal'),
            ),
          );
    }
  }

  test('returns empty with hasAnyCompletedWorkouts=false when DB is empty', () async {
    final now = DateTime(2026, 11, 22, 12, 0);
    final result = await source.getPeriodPersonalRecords(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    expect(result.hasAnyCompletedWorkouts, isFalse);
    for (final metric in ExerciseMetric.values) {
      expect(result.recordsByMetric[metric], isEmpty);
    }
  });

  test(
    'tracks true all-time PRs in timeframe rather than prior-window comparisons',
    () async {
      await exercise('Bench Press', trackingType: 'weight_reps');
      await exercise('Squat', trackingType: 'weight_reps');
      await exercise('Incline Curl', trackingType: 'weight_reps');
      await exercise('Single Session', trackingType: 'weight_reps');

      final now = DateTime(2026, 11, 22, 12, 0);
      final rangeStart = DateTime(2026, 10, 24);

      // Bench Press: peaked at 120 kg 90 days ago; lifting 80->90 inside range
      // is NOT an all-time PR and must not appear.
      await logWorkout(now.subtract(const Duration(days: 90)), [
        (
          exerciseId: 'Bench Press',
          weight: 120,
          reps: 5,
          distance: null,
          durationSeconds: null,
        ),
      ]);
      await logWorkout(now.subtract(const Duration(days: 20)), [
        (
          exerciseId: 'Bench Press',
          weight: 80,
          reps: 5,
          distance: null,
          durationSeconds: null,
        ),
      ]);
      await logWorkout(now.subtract(const Duration(days: 5)), [
        (
          exerciseId: 'Bench Press',
          weight: 90,
          reps: 5,
          distance: null,
          durationSeconds: null,
        ),
      ]);

      // Squat: old PR was 100 kg x 5 (120 days ago, outside prior 30d window).
      // Two sessions inside range beat it: 105 kg then 110 kg.
      await logWorkout(now.subtract(const Duration(days: 120)), [
        (
          exerciseId: 'Squat',
          weight: 100,
          reps: 5,
          distance: null,
          durationSeconds: null,
        ),
      ]);
      await logWorkout(now.subtract(const Duration(days: 15)), [
        (
          exerciseId: 'Squat',
          weight: 105,
          reps: 5,
          distance: null,
          durationSeconds: null,
        ),
      ]);
      await logWorkout(now.subtract(const Duration(days: 2)), [
        (
          exerciseId: 'Squat',
          weight: 110,
          reps: 5,
          distance: null,
          durationSeconds: null,
        ),
      ]);

      // Incline Curl: first done inside range (10 kg x 10), then beaten inside range (12 kg x 10).
      await logWorkout(now.subtract(const Duration(days: 18)), [
        (
          exerciseId: 'Incline Curl',
          weight: 10,
          reps: 10,
          distance: null,
          durationSeconds: null,
        ),
      ]);
      await logWorkout(now.subtract(const Duration(days: 3)), [
        (
          exerciseId: 'Incline Curl',
          weight: 12,
          reps: 10,
          distance: null,
          durationSeconds: null,
        ),
      ]);

      // Single Session: only logged once ever -> baseline only, not a PR.
      await logWorkout(now.subtract(const Duration(days: 4)), [
        (
          exerciseId: 'Single Session',
          weight: 50,
          reps: 8,
          distance: null,
          durationSeconds: null,
        ),
      ]);

      final result = await source.getPeriodPersonalRecords(
        start: rangeStart,
        end: now,
      );
      expect(result.hasAnyCompletedWorkouts, isTrue);

      final maxWeightRecords =
          result.recordsByMetric[ExerciseMetric.maxWeight]!;
      expect(
        maxWeightRecords.map((r) => r.exerciseName).toList(),
        // Sorted descending by improvementPct: Incline Curl (+20%), Squat (+10%)
        ['Incline Curl', 'Squat'],
      );
      expect(maxWeightRecords[0].previousValue, 10.0);
      expect(maxWeightRecords[0].newValue, 12.0);
      expect(maxWeightRecords[0].improvementPct, closeTo(20.0, 0.001));
      expect(maxWeightRecords[1].previousValue, 100.0);
      expect(maxWeightRecords[1].newValue, 110.0);
      expect(maxWeightRecords[1].improvementPct, closeTo(10.0, 0.001));

      final e1rmRecords = result.recordsByMetric[ExerciseMetric.est1rm]!;
      expect(
        e1rmRecords.map((r) => r.exerciseName).toList(),
        ['Incline Curl', 'Squat'],
      );
      expect(e1rmRecords[1].weightKg, 110.0);
      expect(e1rmRecords[1].reps, 5);

      final volumeRecords = result.recordsByMetric[ExerciseMetric.volume]!;
      expect(
        volumeRecords.map((r) => r.exerciseName).toList(),
        ['Incline Curl', 'Squat'],
      );
      expect(volumeRecords[1].previousValue, 500.0);
      expect(volumeRecords[1].newValue, 550.0);
    },
  );

  test('computes distance, duration, and fastest pace cardio records', () async {
    await exercise(
      'Running',
      trackingType: 'distance_time',
      categoryName: 'Cardio',
    );
    await exercise('Plank', trackingType: 'time');

    final now = DateTime(2026, 11, 22, 12, 0);
    final rangeStart = DateTime(2026, 10, 24);

    // Prior baselines before range
    await logWorkout(now.subtract(const Duration(days: 45)), [
      (
        exerciseId: 'Running',
        weight: null,
        reps: null,
        distance: 5.0,
        durationSeconds: 1800, // 6:00 / km (360 s/km)
      ),
      (
        exerciseId: 'Plank',
        weight: null,
        reps: null,
        distance: null,
        durationSeconds: 60,
      ),
    ]);

    // Inside range: longer & faster run + longer plank
    await logWorkout(now.subtract(const Duration(days: 2)), [
      (
        exerciseId: 'Running',
        weight: null,
        reps: null,
        distance: 10.0,
        durationSeconds: 3000, // 5:00 / km (300 s/km)
      ),
      (
        exerciseId: 'Plank',
        weight: null,
        reps: null,
        distance: null,
        durationSeconds: 90,
      ),
    ]);

    final result = await source.getPeriodPersonalRecords(
      start: rangeStart,
      end: now,
    );

    final distRecords = result.recordsByMetric[ExerciseMetric.distance]!;
    expect(distRecords, hasLength(1));
    expect(distRecords.single.exerciseName, 'Running');
    expect(distRecords.single.previousValue, 5.0);
    expect(distRecords.single.newValue, 10.0);
    expect(distRecords.single.improvementPct, closeTo(100.0, 0.001));

    final durRecords = result.recordsByMetric[ExerciseMetric.duration]!;
    expect(
      durRecords.map((r) => r.exerciseName).toList(),
      ['Running', 'Plank'], // +66.7% vs +50%
    );
    expect(durRecords[1].newValue, 90.0);

    final paceRecords = result.recordsByMetric[ExerciseMetric.pace]!;
    expect(paceRecords, hasLength(1));
    expect(paceRecords.single.exerciseName, 'Running');
    expect(paceRecords.single.previousValue, closeTo(360.0, 0.001));
    expect(paceRecords.single.newValue, closeTo(300.0, 0.001));
    expect(paceRecords.single.deltaValue, closeTo(60.0, 0.001));
    expect(paceRecords.single.improvementPct, closeTo(16.6667, 0.001));
  });
}
