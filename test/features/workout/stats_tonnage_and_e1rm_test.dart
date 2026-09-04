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

/// The two statistics that still did their own arithmetic.
///
/// The consistency tracker multiplied `weight * reps` by hand, so a week of
/// pull-ups read as zero tonnage there while the volume chart counted it. And
/// the PR dashboard estimated 1RM with a private Epley formula while the rest
/// of the app uses Brzycki through the shared helper, so the same set carried
/// two different numbers on two screens.
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

  Future<void> exercise(
    String id, {
    required String trackingType,
    String loadMode = 'external',
  }) async {
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: Value(id),
            trackingType: Value(trackingType),
            loadMode: Value(loadMode),
          ),
        );
  }

  var logSeq = 0;

  Future<void> logSet(
    String exerciseId, {
    double? weight,
    required int reps,
    required int daysAgo,
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
            isCompleted: const Value(true),
            setType: const Value('normal'),
          ),
        );
  }

  double totalTonnage(List<Map<String, dynamic>> weeks) =>
      weeks.fold(0.0, (sum, w) => sum + (w['tonnage'] as double));

  group('weekly consistency tonnage', () {
    test('counts a pull-up at body weight', () async {
      await bodyweight(80);
      await exercise('Pull-Up',
          trackingType: 'bodyweight_reps', loadMode: 'bodyweight');
      await logSet('Pull-Up', reps: 10, daysAgo: 3);

      expect(totalTonnage(await source.getWeeklyConsistencyMetrics()), 800.0,
          reason: 'a week of pull-ups still read as zero tonnage');
    });

    test('counts an assisted set as what was lifted, not as the assistance',
        () async {
      await bodyweight(80);
      await exercise('Assisted Dip',
          trackingType: 'bodyweight_reps', loadMode: 'assisted');
      await logSet('Assisted Dip', weight: 30, reps: 10, daysAgo: 3);

      expect(totalTonnage(await source.getWeeklyConsistencyMetrics()), 500.0);
    });

    test('agrees with the volume chart about the same sets', () async {
      await bodyweight(80);
      await exercise('Pull-Up',
          trackingType: 'bodyweight_reps', loadMode: 'bodyweight');
      await exercise('Bench', trackingType: 'weight_reps');
      await logSet('Pull-Up', reps: 8, daysAgo: 5);
      await logSet('Bench', weight: 60, reps: 10, daysAgo: 5);

      final weekly = totalTonnage(await source.getWeeklyConsistencyMetrics());
      final byExercise = await source.getTopExercisesByVolume(daysBack: 30);
      final fromChart = byExercise.fold<double>(
          0.0, (sum, e) => sum + (e['tonnage'] as double));

      expect(weekly, fromChart);
      expect(weekly, 640.0 + 600.0);
    });
  });

  group('notable improvements', () {
    test('estimates with Brzycki, like the rest of the app', () async {
      await bodyweight(80);
      await exercise('Bench', trackingType: 'weight_reps');
      await logSet('Bench', weight: 100, reps: 3, daysAgo: 45);
      await logSet('Bench', weight: 110, reps: 3, daysAgo: 5);

      final rows = await source.getNotablePrImprovements();
      expect(rows, hasLength(1));
      // Brzycki: load * 36 / (37 - reps). Epley would have said 110 and 121.
      expect(rows.single['previousBestE1rm'], closeTo(100 * 36 / 34, 0.001));
      expect(rows.single['recentBestE1rm'], closeTo(110 * 36 / 34, 0.001));
    });

    test('a set beyond the formula\'s range invents no improvement', () async {
      await bodyweight(80);
      await exercise('Curl', trackingType: 'weight_reps');
      await logSet('Curl', weight: 20, reps: 20, daysAgo: 45);
      await logSet('Curl', weight: 22, reps: 20, daysAgo: 5);

      expect(await source.getNotablePrImprovements(), isEmpty,
          reason: 'Brzycki declines past 12 reps; Epley extrapolated anyway');
    });

    test('a pull-up can show an improvement', () async {
      await bodyweight(80);
      await exercise('Pull-Up',
          trackingType: 'bodyweight_reps', loadMode: 'bodyweight');
      await logSet('Pull-Up', reps: 5, daysAgo: 45);
      await logSet('Pull-Up', weight: 10, reps: 5, daysAgo: 5);

      final rows = await source.getNotablePrImprovements();
      expect(rows, hasLength(1));
      expect(rows.single['improvementPct'], closeTo(12.5, 0.001));
    });
  });
}
