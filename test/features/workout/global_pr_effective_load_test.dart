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

/// The global record lists, for exercises that log no weight or log it
/// backwards.
///
/// All three used to be raw SQL over `MAX(set_logs.weight)`, gated on
/// `weight > 0`. That column holds the number the user typed, not the load:
/// empty for the 254 body-weight exercises in the catalog, and on the 4
/// assistance machines it counts the wrong way round. So the PR dashboard
/// could never show a pull-up at all, and an assisted set won by being easy.
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

  Future<void> bodyweight(double kg) async {
    await db.into(db.measurements).insert(
          MeasurementsCompanion.insert(
            type: 'weight',
            value: kg,
            unit: 'kg',
            date: DateTime.now().subtract(const Duration(days: 400)),
          ),
        );
  }

  Future<String> exercise(
    String id, {
    required String trackingType,
    String loadMode = 'external',
    String? categoryName,
  }) async {
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: Value(id),
            trackingType: Value(trackingType),
            loadMode: Value(loadMode),
            categoryName: Value(categoryName),
          ),
        );
    return id;
  }

  var logSeq = 0;

  Future<void> logSet(
    String exerciseId, {
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distanceKm,
    int daysAgo = 3,
  }) async {
    final logId = 'log-${logSeq++}';
    await db.into(db.workoutLogs).insert(
          WorkoutLogsCompanion.insert(
            id: Value(logId),
            startTime: DateTime.now().subtract(Duration(days: daysAgo)),
            status: const Value('completed'),
          ),
        );
    await db.into(db.setLogs).insert(
          SetLogsCompanion.insert(
            workoutLogId: logId,
            exerciseId: Value(exerciseId),
            exerciseNameSnapshot: Value(exerciseId),
            weight: Value(weight),
            reps: Value(reps),
            durationSeconds: Value(durationSeconds),
            distance: Value(distanceKm),
            isCompleted: const Value(true),
            setType: const Value('normal'),
          ),
        );
  }

  test('a pull-up holds a record, at the body weight it was performed at',
      () async {
    await bodyweight(80);
    await exercise('Pull-Up',
        trackingType: 'bodyweight_reps', loadMode: 'bodyweight');
    await logSet('Pull-Up', reps: 8);

    final all = await source.getAllTimeGlobalPRs();
    expect(all, hasLength(1),
        reason: 'a set with an empty weight column was dropped again');
    expect(all.single['exerciseName'], 'Pull-Up');
    expect(all.single['weight'], 80.0);
    expect(all.single['reps'], 8);
  });

  test('a weighted pull-up outranks an unweighted one', () async {
    await bodyweight(80);
    await exercise('Pull-Up',
        trackingType: 'bodyweight_reps', loadMode: 'bodyweight');
    await logSet('Pull-Up', reps: 8);
    await logSet('Pull-Up', weight: 15, reps: 5);

    final all = await source.getAllTimeGlobalPRs();
    expect(all.single['weight'], 95.0);
    expect(all.single['reps'], 5);
  });

  test('on an assistance machine the easiest set does not win', () async {
    await bodyweight(80);
    await exercise('Assisted Dip',
        trackingType: 'bodyweight_reps', loadMode: 'assisted');
    // 30 kg of help is the easy set; 10 kg of help is the hard one.
    await logSet('Assisted Dip', weight: 30, reps: 6);
    await logSet('Assisted Dip', weight: 10, reps: 6);

    final all = await source.getAllTimeGlobalPRs();
    expect(all.single['weight'], 70.0,
        reason: 'the record was read off the assistance, not off the load');
  });

  test('a barbell lift is still ranked on the number in the column', () async {
    await bodyweight(80);
    await exercise('Bench', trackingType: 'weight_reps');
    await logSet('Bench', weight: 100, reps: 3);
    await logSet('Bench', weight: 90, reps: 8);

    final all = await source.getAllTimeGlobalPRs();
    expect(all.single['weight'], 100.0);
    expect(all.single['reps'], 3);
  });

  test('a run and a plank hold no rep-based record', () async {
    await bodyweight(80);
    await exercise('Run',
        trackingType: 'distance_time', categoryName: 'Cardio');
    await exercise('Plank', trackingType: 'time');
    await logSet('Run', distanceKm: 5, durationSeconds: 1500, reps: 1);
    await logSet('Plank', durationSeconds: 60, reps: 1);

    expect(await source.getAllTimeGlobalPRs(), isEmpty,
        reason: 'a timed hold was ranked as if it were a lift');
  });

  test('recent records are ordered by when the best set was performed',
      () async {
    await bodyweight(80);
    await exercise('Bench', trackingType: 'weight_reps');
    await exercise('Squat', trackingType: 'weight_reps');
    await logSet('Bench', weight: 100, reps: 3, daysAgo: 30);
    await logSet('Squat', weight: 140, reps: 3, daysAgo: 2);

    final recent = await source.getRecentGlobalPRs(limit: 5);
    expect(recent.map((r) => r['exerciseName']), ['Squat', 'Bench']);

    final allTime = await source.getAllTimeGlobalPRs();
    expect(allTime.map((r) => r['exerciseName']), ['Squat', 'Bench'],
        reason: 'all-time is ranked by load, which agrees here by coincidence');
  });

  test('a body-weight set before the first measurement is skipped, not zeroed',
      () async {
    // No measurement at all: there is nothing to value the set at.
    await exercise('Pull-Up',
        trackingType: 'bodyweight_reps', loadMode: 'bodyweight');
    await logSet('Pull-Up', reps: 10);

    expect(await source.getAllTimeGlobalPRs(), isEmpty,
        reason: 'an unvaluable set was counted as a 0 kg record');
  });

  group('rep brackets', () {
    test('are ranked on effective load, and a pull-up can win one', () async {
      await bodyweight(80);
      await exercise('Pull-Up',
          trackingType: 'bodyweight_reps', loadMode: 'bodyweight');
      await exercise('Row', trackingType: 'weight_reps');
      await logSet('Pull-Up', reps: 5);
      await logSet('Row', weight: 60, reps: 5);

      final brackets = await source.getAllTimePRsByRepBracket();
      expect(brackets['4–6 RM']?['exerciseName'], 'Pull-Up');
      expect(brackets['4–6 RM']?['weight'], 80.0);
    });

    test('an assisted set cannot take a bracket by being easy', () async {
      await bodyweight(80);
      await exercise('Assisted Pull-Up',
          trackingType: 'bodyweight_reps', loadMode: 'assisted');
      await exercise('Row', trackingType: 'weight_reps');
      await logSet('Assisted Pull-Up', weight: 60, reps: 5);
      await logSet('Row', weight: 60, reps: 5);

      final brackets = await source.getAllTimePRsByRepBracket();
      expect(brackets['4–6 RM']?['exerciseName'], 'Row',
          reason: '20 kg of actual load outranked 60 kg on the bar');
    });

    test('every bracket is present, empty ones as null', () async {
      final brackets = await source.getAllTimePRsByRepBracket();
      expect(brackets.keys,
          ['1 RM', '2–3 RM', '4–6 RM', '7–10 RM', '11–15 RM', '15+ RM']);
      expect(brackets.values, everyElement(isNull));
    });
  });
}
