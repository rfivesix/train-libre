@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' hide Exercise;
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

/// The log mask, what the logged number means, and the predicate that decides
/// whether a set counted.
///
/// These three ship together on purpose. `getMuscleGroupAnalytics` used to
/// require `weight > 0`, which was harmless only while every exercise was
/// logged with weight and reps. The moment tracking_type drives the mask, 253
/// bodyweight exercises have no weight field — and that predicate would have
/// deleted every pull-up from the muscle statistics with nothing to show for
/// it.
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

const String kWeightReps = '20'; // Arnold Press
const String kBodyweightReps = '41';
const String kTime = '56';
const String kAssisted = '477';

Exercise _exercise({
  String? trackingType,
  String? loadMode,
  bool supportsAddedWeight = false,
  String categoryName = 'Legs',
}) =>
    Exercise(
      texts: const {'en': ExerciseText(name: 'x')},
      categoryName: categoryName,
      primaryMuscles: const [],
      secondaryMuscles: const [],
      trackingType: trackingType,
      loadMode: loadMode,
      supportsAddedWeight: supportsAddedWeight,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('the log mask', () {
    test('weight_reps asks for weight and reps', () {
      final e = _exercise(trackingType: 'weight_reps');
      expect(e.logsWeight, isTrue);
      expect(e.logsReps, isTrue);
      expect(e.logsDuration, isFalse);
      expect(e.logsDistance, isFalse);
      expect(e.isCardio, isFalse);
    });

    test('bodyweight_reps asks for reps and an added-weight field', () {
      // The field is offered either way and starts empty. Empty means "just
      // me", and the set counts with the user's full body weight; a zero would
      // claim a pull-up moved nothing.
      final plain = _exercise(trackingType: 'bodyweight_reps');
      expect(plain.logsReps, isTrue);
      expect(plain.logsWeight, isTrue);

      final weighted =
          _exercise(trackingType: 'bodyweight_reps', supportsAddedWeight: true);
      expect(weighted.logsWeight, isTrue);
    });

    test('time asks for a duration', () {
      final plank = _exercise(trackingType: 'time', categoryName: 'Abs');
      expect(plank.logsDuration, isTrue);
      expect(plank.logsReps, isFalse);
      expect(plank.logsWeight, isFalse);
      expect(plank.isCardio, isFalse,
          reason: 'a plank logs a duration without being cardio');
    });

    test('distance_time asks for both, and reads as cardio', () {
      final run = _exercise(trackingType: 'distance_time');
      expect(run.logsDistance, isTrue);
      expect(run.logsDuration, isTrue);
      expect(run.logsReps, isFalse);
      expect(run.isCardio, isTrue);
    });

    test('an unclassified exercise still goes by its category', () {
      expect(_exercise(categoryName: 'Cardio').isCardio, isTrue);
      expect(_exercise(categoryName: 'Legs').isCardio, isFalse);
      expect(_exercise(categoryName: 'Legs').logsWeight, isTrue);
    });

    test('a body region as category no longer implies a mask', () {
      // The old failure: category_name is a body region as often as a training
      // type, so a rowing machine filed under "Back" logged weight and reps.
      final rowingMachine =
          _exercise(trackingType: 'distance_time', categoryName: 'Back');
      expect(rowingMachine.isCardio, isTrue);
      expect(rowingMachine.logsWeight, isFalse);
    });
  });

  group('what the number means', () {
    test('an assistance machine is not a resistance reading', () {
      expect(_exercise(loadMode: 'assisted').weightMeansResistance, isFalse);
      expect(_exercise(loadMode: 'external').weightMeansResistance, isTrue);
      expect(_exercise(loadMode: 'bodyweight').weightMeansResistance, isTrue);
      expect(_exercise().weightMeansResistance, isTrue,
          reason: 'unknown load mode must not be treated as assisted');
    });
  });

  group('against the catalog', () {
    late AppDatabase db;
    late WorkoutLocalDataSource source;

    Future<void> logSets(
      String exerciseId, {
      required String logId,
      double? weight,
      int? reps,
      int? durationSeconds,
    }) async {
      await db.into(db.workoutLogs).insert(
            WorkoutLogsCompanion.insert(
              id: Value(logId),
              startTime: DateTime.now().subtract(const Duration(hours: 3)),
              status: const Value('completed'),
            ),
          );
      for (var i = 0; i < 3; i++) {
        await db.into(db.setLogs).insert(
              SetLogsCompanion.insert(
                workoutLogId: logId,
                exerciseId: Value(exerciseId),
                weight: Value(weight),
                reps: Value(reps),
                durationSeconds: Value(durationSeconds),
                isCompleted: const Value(true),
              ),
            );
      }
    }

    Future<double> volume() async {
      final summary = await source.getMuscleGroupAnalytics();
      return (summary['totalEquivalentSets'] as num).toDouble();
    }

    setUp(() async {
      sqflite.databaseFactory = databaseFactoryFfi;
      db = AppDatabase(NativeDatabase.memory());
      DatabaseHelper.setDriftDb(db);
      BasisDataManager.instance.invalidateCatalogPresenceCache();
      await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
        File(kFixturePath).absolute.path,
      );
      source = WorkoutLocalDataSource.forTesting(db);
    });

    tearDown(() async => db.close());

    test('the catalog classification reaches the model', () async {
      final weightReps = await source.getExerciseByUuid(kWeightReps);
      expect(weightReps?.trackingType, 'weight_reps');
      expect(weightReps?.logsWeight, isTrue);

      final bodyweight = await source.getExerciseByUuid(kBodyweightReps);
      expect(bodyweight?.trackingType, 'bodyweight_reps');

      final timed = await source.getExerciseByUuid(kTime);
      expect(timed?.trackingType, 'time');

      final assisted = await source.getExerciseByUuid(kAssisted);
      expect(assisted?.loadMode, 'assisted');
      expect(assisted?.weightMeansResistance, isFalse);
    });

    test('a bodyweight set with no weight still counts towards volume',
        () async {
      // The regression this commit exists to prevent.
      await logSets(kBodyweightReps, logId: 'bw', reps: 10);
      expect(await volume(), greaterThan(0),
          reason: 'a pull-up logged without weight vanished from the '
              'statistics');
    });

    test('a set logged only as a duration counts too', () async {
      await logSets(kTime, logId: 'timed', durationSeconds: 60);
      expect(await volume(), greaterThan(0));
    });

    test('a weighted set still counts, unchanged', () async {
      await logSets(kWeightReps, logId: 'wr', weight: 50, reps: 10);
      expect(await volume(), greaterThan(0));
    });

    test('a set with nothing recorded counts for nothing', () async {
      await logSets(kWeightReps, logId: 'empty');
      expect(await volume(), 0);
    });

    test('progression reads an assistance machine the right way round',
        () async {
      // Two sessions where the entered number went up. On an assistance
      // machine that is more help, not more strength, so it must register as
      // a decline. Before load_mode, this surfaced as an improvement.
      await db.into(db.measurements).insert(
            MeasurementsCompanion.insert(
              type: 'weight',
              value: 80,
              unit: 'kg',
              date: DateTime.now().subtract(const Duration(days: 200)),
            ),
          );

      final assisted = await source.getExerciseByUuid(kAssisted);
      final name = assisted!.canonicalName;

      Future<void> session(String id, DateTime when, double assistance) async {
        await db.into(db.workoutLogs).insert(
              WorkoutLogsCompanion.insert(
                id: Value(id),
                startTime: when,
                status: const Value('completed'),
              ),
            );
        await db.into(db.setLogs).insert(
              SetLogsCompanion.insert(
                workoutLogId: id,
                exerciseId: Value(kAssisted),
                exerciseNameSnapshot: Value(name),
                weight: Value(assistance),
                reps: const Value(10),
                isCompleted: const Value(true),
              ),
            );
      }

      final now = DateTime.now();
      await session('old', now.subtract(const Duration(days: 40)), 20);
      await session('new', now.subtract(const Duration(days: 2)), 40);

      final improvements = await source.getNotablePrImprovements();
      expect(
        improvements.map((m) => m['exerciseName']),
        isNot(contains(name)),
        reason: 'more assistance was reported as more strength',
      );
    });

    test('a body-weight set produces an e1RM at all', () async {
      // It could not before: the query required a weight greater than zero,
      // and a pull-up has none.
      await db.into(db.measurements).insert(
            MeasurementsCompanion.insert(
              type: 'weight',
              value: 80,
              unit: 'kg',
              date: DateTime.now().subtract(const Duration(days: 200)),
            ),
          );

      final exercise = await source.getExerciseByUuid(kBodyweightReps);
      final name = exercise!.canonicalName;

      Future<void> session(String id, DateTime when, int reps) async {
        await db.into(db.workoutLogs).insert(
              WorkoutLogsCompanion.insert(
                id: Value(id),
                startTime: when,
                status: const Value('completed'),
              ),
            );
        await db.into(db.setLogs).insert(
              SetLogsCompanion.insert(
                workoutLogId: id,
                exerciseId: Value(kBodyweightReps),
                exerciseNameSnapshot: Value(name),
                reps: Value(reps),
                isCompleted: const Value(true),
              ),
            );
      }

      final now = DateTime.now();
      await session('bw-old', now.subtract(const Duration(days: 40)), 8);
      await session('bw-new', now.subtract(const Duration(days: 2)), 15);

      final improvements = await source.getNotablePrImprovements();
      expect(improvements.map((m) => m['exerciseName']), contains(name),
          reason: 'going from 8 to 15 pull-ups is progress and used to '
              'register as nothing at all');
    });

    test('a body-weight session counts towards tonnage', () async {
      await db.into(db.measurements).insert(
            MeasurementsCompanion.insert(
              type: 'weight',
              value: 80,
              unit: 'kg',
              date: DateTime.now().subtract(const Duration(days: 200)),
            ),
          );
      await logSets(kBodyweightReps, logId: 'bw-tonnage', reps: 10);

      final byMuscle = await source.getVolumeByMuscleGroup();
      final total = byMuscle.fold<double>(
          0, (sum, row) => sum + (row['tonnage'] as double));
      // Three sets of ten at 80 kg.
      expect(total, greaterThan(0));
    });

    test('without a recorded body weight tonnage falls back to what was typed',
        () async {
      await logSets(kBodyweightReps, logId: 'bw-none', reps: 10, weight: 15);

      final byMuscle = await source.getVolumeByMuscleGroup();
      final total = byMuscle.fold<double>(
          0, (sum, row) => sum + (row['tonnage'] as double));
      expect(total, greaterThan(0),
          reason: 'the added weight is real even when the body weight is '
              'unknown');
    });
  });
}
