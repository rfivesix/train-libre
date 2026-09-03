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
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/domain/classification/workout_classification.dart';

/// Which logged sets are allowed to move the muscle statistics.
///
/// Before v2 this barely mattered: most stretches carried no muscle
/// annotation, so they contributed nothing by accident. Now all 909 exercises
/// are annotated, and for a stretch `role: primary` names the muscle being
/// stretched — so an unfiltered hamstring stretch would credit the hamstrings
/// a full working set and open a recovery window on them.
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

/// Fixture exercises, one per modality.
const String kStrength = '20';
const String kPlyometric = '320';
const String kStretch = '1002';
const String kMobility = '716';
const String kCardio = '177';
const String kBalance = '1238';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('the rule itself', () {
    bool counts(String? modality) =>
        WorkoutClassification.countsTowardsMuscleLoad(
          modality: modality,
          setType: 'normal',
          categoryName: 'Legs',
          exerciseNameSnapshot: 'Something',
          reps: 10,
        );

    test('strength and plyometric count, the rest do not', () {
      expect(counts('strength'), isTrue);
      expect(counts('plyometric'), isTrue);
      expect(counts('stretch'), isFalse);
      expect(counts('mobility'), isFalse);
      expect(counts('cardio'), isFalse);
      expect(counts('balance'), isFalse);
    });

    test('an unclassified exercise falls back to the old heuristic', () {
      // Pre-v2 rows and everything the user creates. Dropping these would be a
      // regression in existing statistics, not a fix.
      expect(counts(null), isTrue);
      expect(
        WorkoutClassification.countsTowardsMuscleLoad(
          modality: null,
          setType: 'normal',
          categoryName: 'Cardio',
          exerciseNameSnapshot: 'Treadmill',
          reps: 10,
        ),
        isFalse,
      );
    });

    test('modality beats a misleading category', () {
      // 120 of the 122 stretch and mobility exercises wear a body region as
      // their category_name. The heuristic never had a chance.
      expect(
        WorkoutClassification.countsTowardsMuscleLoad(
          modality: 'stretch',
          setType: 'normal',
          categoryName: 'Legs',
          exerciseNameSnapshot: 'Sit and Reach',
          reps: 1,
        ),
        isFalse,
      );
      // And the other way: a cardio-sounding name on a strength exercise.
      expect(
        WorkoutClassification.countsTowardsMuscleLoad(
          modality: 'strength',
          setType: 'normal',
          categoryName: 'Cardio',
          exerciseNameSnapshot: 'Rowing',
          reps: 10,
        ),
        isTrue,
      );
    });

    test('a warmup set never counts, whatever the modality', () {
      expect(
        WorkoutClassification.countsTowardsMuscleLoad(
          modality: 'strength',
          setType: 'warmup',
          categoryName: 'Legs',
          exerciseNameSnapshot: 'Squat',
          reps: 10,
        ),
        isTrue,
        reason: 'set_type filtering happens in the query, not here',
      );
      expect(
        WorkoutClassification.countsTowardsMuscleLoad(
          modality: 'strength',
          setType: 'normal',
          categoryName: 'Legs',
          exerciseNameSnapshot: 'Squat',
          reps: 0,
        ),
        isFalse,
      );
    });

    test('recovery and volume agree on what counts', () {
      for (final modality in [
        'strength',
        'plyometric',
        'stretch',
        'mobility',
        'cardio',
        'balance',
        null,
      ]) {
        expect(
          WorkoutClassification.isRecoveryStrengthWorkSet(
            modality: modality,
            setType: 'normal',
            categoryName: 'Legs',
            nameDe: null,
            nameEn: null,
            exerciseNameSnapshot: 'Something',
            reps: 10,
          ),
          WorkoutClassification.countsTowardsMuscleLoad(
            modality: modality,
            setType: 'normal',
            categoryName: 'Legs',
            exerciseNameSnapshot: 'Something',
            reps: 10,
          ),
          reason: 'divergence here means volume and recovery tell different '
              'stories about the same set: $modality',
        );
      }
    });
  });

  group('end to end through the analytics queries', () {
    late AppDatabase db;
    late WorkoutLocalDataSource source;

    Future<void> logSet(String exerciseId, {required String logId}) async {
      await db.into(db.workoutLogs).insert(
            WorkoutLogsCompanion.insert(
              id: Value(logId),
              startTime: DateTime.now().subtract(const Duration(hours: 4)),
              status: const Value('completed'),
            ),
          );
      // Three working sets, weighted, so nothing else in the query filters
      // them out for us and the modality rule is what is actually under test.
      for (var i = 0; i < 3; i++) {
        await db.into(db.setLogs).insert(
              SetLogsCompanion.insert(
                workoutLogId: logId,
                exerciseId: Value(exerciseId),
                exerciseNameSnapshot: Value('set for $exerciseId'),
                weight: const Value(50),
                reps: const Value(10),
                isCompleted: const Value(true),
                setType: const Value('normal'),
              ),
            );
      }
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

    tearDown(() async {
      await db.close();
    });

    Future<double> volume() async {
      final summary = await source.getMuscleGroupAnalytics();
      return (summary['totalEquivalentSets'] as num).toDouble();
    }

    Future<Set<String>> recoveringMuscles() async {
      final analytics = await source.getRecoveryAnalytics();
      final muscles = analytics['muscles'] as List;
      return muscles
          .where((m) => (m as Map)['state'] == 'recovering')
          .map((m) => (m as Map)['muscleGroup'] as String)
          .toSet();
    }

    test('a strength exercise moves both', () async {
      await logSet(kStrength, logId: 'log-strength');

      expect(await volume(), greaterThan(0));
      expect(await recoveringMuscles(), isNotEmpty);
    });

    test('a plyometric exercise moves both', () async {
      await logSet(kPlyometric, logId: 'log-plyo');

      expect(await volume(), greaterThan(0));
      expect(await recoveringMuscles(), isNotEmpty);
    });

    test('a stretch moves neither', () async {
      await logSet(kStretch, logId: 'log-stretch');

      expect(await volume(), 0);
      expect(await recoveringMuscles(), isEmpty,
          reason: 'a stretch must not open a recovery window on the muscle '
              'it stretches');
    });

    test('a mobility drill moves neither', () async {
      await logSet(kMobility, logId: 'log-mobility');

      expect(await volume(), 0);
      expect(await recoveringMuscles(), isEmpty);
    });

    test('cardio and balance move neither', () async {
      await logSet(kCardio, logId: 'log-cardio');
      await logSet(kBalance, logId: 'log-balance');

      expect(await volume(), 0);
      expect(await recoveringMuscles(), isEmpty);
    });

    test('a stretch logged alongside a strength set adds nothing', () async {
      await logSet(kStrength, logId: 'log-strength');
      final strengthOnly = await volume();
      final strengthRecovering = await recoveringMuscles();

      await logSet(kStretch, logId: 'log-stretch');

      expect(await volume(), strengthOnly,
          reason: 'the stretch inflated the total');
      expect(await recoveringMuscles(), strengthRecovering);
    });
  });
}
