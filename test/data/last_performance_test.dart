@TestOn('vm')
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

/// The "last time" column, for exercises that log neither a weight nor reps.
///
/// The query that feeds it built its [SetLog]s from weight, reps and RIR only.
/// A plank held for a minute last week came back with a null duration, so the
/// cell read "-" and tapping it applied nothing — and every run ever recorded
/// had the same problem, for the same reason, with two columns instead of one.
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

  /// A catalog row, so the query can learn what the logged numbers mean.
  /// Without one it falls back to the caller's `isCardio` belief, which is the
  /// documented behaviour for pre-v2 rows and user-created exercises.
  Future<String> exerciseRow(String id, String trackingType,
      {String loadMode = 'external'}) async {
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: Value(id),
            trackingType: Value(trackingType),
            loadMode: Value(loadMode),
          ),
        );
    return id;
  }

  Future<void> logSet(
    String exerciseName, {
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distanceKm,
  }) async {
    final logId = 'log-$exerciseName';
    await db.into(db.workoutLogs).insert(
          WorkoutLogsCompanion.insert(
            id: Value(logId),
            startTime: DateTime.now().subtract(const Duration(days: 3)),
            status: const Value('completed'),
          ),
        );
    await db.into(db.setLogs).insert(
          SetLogsCompanion.insert(
            workoutLogId: logId,
            exerciseNameSnapshot: Value(exerciseName),
            weight: Value(weight),
            reps: Value(reps),
            durationSeconds: Value(durationSeconds),
            distance: Value(distanceKm),
            isCompleted: const Value(true),
            setType: const Value('normal'),
          ),
        );
  }

  test('a plank comes back with its duration', () async {
    await logSet('Plank', durationSeconds: 60);

    final sets = await source.getLastSetsForExercise('Plank');
    expect(sets, hasLength(1));
    expect(sets.single.durationSeconds, 60);
  });

  test('a run comes back with both distance and duration', () async {
    await logSet('Run', distanceKm: 5.0, durationSeconds: 1694);

    final sets = await source.getLastSetsForExercise('Run');
    expect(sets, hasLength(1));
    expect(sets.single.distanceKm, 5.0);
    expect(sets.single.durationSeconds, 1694);
  });

  group('personal records follow the shape of the exercise', () {
    test('a held position holds a duration record', () async {
      // Not cardio, so it used to be sent down the rep-bracket branch, where
      // it has no reps and therefore never held a record of any kind.
      final uuid =
          await exerciseRow('ex-plank', 'time', loadMode: 'bodyweight');
      await logSet('Plank', durationSeconds: 90);

      final prs = await source.getExercisePRs('Plank', exerciseUuid: uuid);
      expect(prs.keys, ['Longest Duration']);
      expect(prs['Longest Duration']?.durationSeconds, 90);
    });

    test('the longest hold wins, not the last one', () async {
      final uuid = await exerciseRow('ex-hang', 'time', loadMode: 'bodyweight');
      await logSet('Hang', durationSeconds: 45);
      await db.into(db.setLogs).insert(
            SetLogsCompanion.insert(
              workoutLogId: 'log-Hang',
              exerciseNameSnapshot: const Value('Hang'),
              durationSeconds: const Value(20),
              isCompleted: const Value(true),
              setType: const Value('normal'),
            ),
          );

      final prs = await source.getExercisePRs('Hang', exerciseUuid: uuid);
      expect(prs['Longest Duration']?.durationSeconds, 45);
    });

    test('a run still holds the three cardio records', () async {
      await logSet('Run', distanceKm: 5.0, durationSeconds: 1500);

      final prs = await source.getExercisePRs('Run', isCardio: true);
      expect(
        prs.keys,
        containsAll(['Best Distance', 'Longest Duration', 'Fastest Pace']),
      );
      expect(prs['Best Distance']?.distanceKm, 5.0);
    });

    test('a rep-based exercise still holds its brackets', () async {
      await logSet('Squat', weight: 100, reps: 5);

      final prs = await source.getExercisePRs('Squat');
      expect(prs.keys, contains('Est. 1RM'));
      expect(prs['4-6 RM']?.weightKg, 100);
    });

    test('a body-weight set reaches the brackets with no weight typed',
        () async {
      // The query required `weight > 0 AND reps > 0`, so a pull-up at body
      // weight never reached the aggregation at all.
      final uuid = await exerciseRow('ex-pullup', 'bodyweight_reps',
          loadMode: 'bodyweight');
      await db.into(db.measurements).insert(
            MeasurementsCompanion.insert(
              type: 'weight',
              value: 82,
              unit: 'kg',
              date: DateTime.now().subtract(const Duration(days: 10)),
            ),
          );
      await logSet('Pull-up', reps: 8);

      final prs = await source.getExercisePRs('Pull-up', exerciseUuid: uuid);
      expect(prs['7-10 RM']?.reps, 8);
    });
  });

  test('a barbell set still carries weight and reps', () async {
    await logSet('Squat', weight: 70, reps: 6);

    final sets = await source.getLastSetsForExercise('Squat');
    expect(sets, hasLength(1));
    expect(sets.single.weightKg, 70);
    expect(sets.single.reps, 6);
    expect(sets.single.durationSeconds, isNull);
    expect(sets.single.distanceKm, isNull);
  });
}
