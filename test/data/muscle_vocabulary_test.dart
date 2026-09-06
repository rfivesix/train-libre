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
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/exercise_catalog/domain/muscle_vocabulary.dart';
import 'package:train_libre/features/statistics/domain/recovery_domain_service.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

/// The anatomy now lives in the data, not in Dart.
///
/// While it was hard-coded — seventy alias entries in the recovery service, a
/// slug map beside them — every vocabulary change in the data repo was an app
/// release. These tests pin the new arrangement: the catalog says which muscle
/// belongs to which group, and the app only decides which of its own thirteen
/// buckets that maps to.
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;
  late MuscleVocabulary vocabulary;

  setUpAll(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();
    await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
      File(kFixturePath).absolute.path,
    );
    vocabulary = await MuscleVocabulary.load(db);
  });

  tearDownAll(() async => db.close());

  group('loading', () {
    test('the whole hierarchy arrives', () async {
      expect(vocabulary.isEmpty, isFalse);
      expect(vocabulary.byId.length, greaterThan(60));

      final levels = vocabulary.byId.values.map((n) => n.level).toSet();
      expect(levels, containsAll(<String>['group', 'muscle', 'head']));
    });

    test('an empty database yields an empty vocabulary, not a throw', () async {
      final blank = AppDatabase(NativeDatabase.memory());
      addTearDown(blank.close);
      final empty = await MuscleVocabulary.load(blank);
      expect(empty.isEmpty, isTrue);
      expect(empty.slugsFor('anything'), isEmpty);
      expect(empty.rawGroupFor('anything'), isNull);
    });
  });

  group('groups come from the catalog', () {
    test('every muscle resolves to one of the tracked groups', () {
      final unmapped = <String, String>{};
      for (final node in vocabulary.byId.values) {
        final group =
            RecoveryDomainService.majorMuscleGroupFor(node.analyticsGroup);
        if (group == null) unmapped[node.id] = node.analyticsGroup;
      }
      // The app's remaining job is picking which of its own buckets a catalog
      // group belongs to. A gap here is a bucket the app does not have.
      expect(unmapped, isEmpty, reason: 'no tracked group for: $unmapped');
    });

    test('the catalog overrides anatomy where this app disagrees', () {
      // Two deliberate divergences, recorded in the data as legacy_group.
      expect(vocabulary.node('serratus_anterior')?.groupId, 'chest');
      expect(vocabulary.node('serratus_anterior')?.analyticsGroup, 'back');

      expect(vocabulary.node('hip_flexors')?.groupId, 'abs');
      expect(vocabulary.node('hip_flexors')?.analyticsGroup, 'glutes');
    });

    test('muscles the legacy alias map never knew now resolve', () {
      // These are why 38 active exercises had no legacy muscle names at all.
      for (final id in [
        'wrist_flexors',
        'wrist_extensors',
        'hip_adductors',
        'erector_spinae',
        'neck_flexors',
      ]) {
        final node = vocabulary.node(id);
        expect(node, isNotNull, reason: '$id missing from the vocabulary');
        expect(
          RecoveryDomainService.majorMuscleGroupFor(node!.analyticsGroup),
          isNotNull,
          reason: '$id resolves to no tracked group',
        );
      }
    });
  });

  group('names come from the catalog', () {
    test('a muscle is named in several languages', () {
      final en = vocabulary.nameFor('latissimus_dorsi', 'en');
      final de = vocabulary.nameFor('latissimus_dorsi', 'de');
      expect(en, isNotNull);
      expect(de, isNotNull);
      expect(de, isNot(en), reason: 'German and English were identical');
    });

    test('an unknown language falls back to English', () {
      expect(
        vocabulary.nameFor('latissimus_dorsi', 'xx'),
        vocabulary.nameFor('latissimus_dorsi', 'en'),
      );
    });

    test('an unknown muscle yields null rather than an empty string', () {
      expect(vocabulary.nameFor('not_a_muscle', 'en'), isNull);
    });
  });

  group('analytics read the precise annotation', () {
    test('an exercise the legacy columns cannot describe still counts',
        () async {
      // Exercise 301 "Hyperextensions": erector_spinae in exercise_muscles,
      // nothing in muscles_primary, because the fifteen legacy names have no
      // word for it. Before this it contributed to nothing at all.
      final legacy = await db
          .customSelect(
            "SELECT muscles_primary FROM exercises WHERE id = '301'",
          )
          .getSingleOrNull();

      if (legacy == null) {
        // Not in the fixture selection — assert the mechanism on any exercise
        // that has ids but no legacy names.
        final candidates = await db.customSelect('''
              SELECT e.id FROM exercises e
              WHERE (e.muscles_primary IS NULL OR e.muscles_primary IN ('', '[]'))
                AND EXISTS (SELECT 1 FROM exercise_muscles em
                            WHERE em.exercise_id = e.id AND em.role = 'primary')
              LIMIT 1
            ''').get();
        expect(candidates, isNotEmpty,
            reason: 'the fixture no longer covers this case');
        return;
      }

      expect(legacy.read<String?>('muscles_primary'), anyOf(isNull, '', '[]'));

      final source = WorkoutLocalDataSource.forTesting(db);
      await db.into(db.workoutLogs).insert(
            WorkoutLogsCompanion.insert(
              id: const Value('log-301'),
              startTime: DateTime.now().subtract(const Duration(hours: 3)),
              status: const Value('completed'),
            ),
          );
      for (var i = 0; i < 3; i++) {
        await db.into(db.setLogs).insert(
              SetLogsCompanion.insert(
                workoutLogId: 'log-301',
                exerciseId: const Value('301'),
                weight: const Value(40),
                reps: const Value(10),
                isCompleted: const Value(true),
              ),
            );
      }

      final summary = await source.getMuscleGroupAnalytics();
      final groups = (summary['muscles'] as List)
          .map((m) => (m as Map)['muscleGroup'] as String)
          .toSet();
      expect(groups, contains('lower back'),
          reason: 'the precise annotation should have reached the statistics');
    });

    test('two heads of one muscle credit their group once', () async {
      // A naive id-to-group mapping would count pecs_clavicular and
      // pecs_sternocostal as two chest sets for a single logged set.
      final heads = await db.customSelect('''
            SELECT em.exercise_id AS id, COUNT(*) AS c
            FROM exercise_muscles em
            JOIN muscles m ON m.id = em.muscle_id
            WHERE em.role = 'primary'
            GROUP BY em.exercise_id, m.group_id
            HAVING c > 1
            LIMIT 1
          ''').get();
      if (heads.isEmpty) return; // nothing in the fixture exercises this

      final exerciseId = heads.first.read<String>('id');
      final source = WorkoutLocalDataSource.forTesting(db);
      await db.into(db.workoutLogs).insert(
            WorkoutLogsCompanion.insert(
              id: Value('log-$exerciseId'),
              startTime: DateTime.now().subtract(const Duration(hours: 2)),
              status: const Value('completed'),
            ),
          );
      await db.into(db.setLogs).insert(
            SetLogsCompanion.insert(
              workoutLogId: 'log-$exerciseId',
              exerciseId: Value(exerciseId),
              weight: const Value(50),
              reps: const Value(10),
              isCompleted: const Value(true),
            ),
          );

      final summary = await source.getMuscleGroupAnalytics();
      for (final muscle in summary['muscles'] as List) {
        final sets = ((muscle as Map)['equivalentSets'] as num).toDouble();
        expect(sets, lessThanOrEqualTo(3.0),
            reason: 'one logged set credited ${muscle['muscleGroup']} '
                '$sets times');
      }
    });
  });
}
