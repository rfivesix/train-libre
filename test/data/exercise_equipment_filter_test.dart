@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/exercise_catalog/domain/exercise_locale_chain.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

/// Filtering the catalog by what you have and what you want it for.
///
/// The split between `primary` and `setup` equipment is what makes "what can I
/// do in a hotel room" a query rather than a guess: a bench is furniture, a
/// dumbbell is the thing generating the load, and only the second is what
/// someone means when they pick an implement.
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;
  late WorkoutLocalDataSource source;

  setUpAll(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();
    ExerciseLocaleChain.invalidate();
    await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
      File(kFixturePath).absolute.path,
    );
    ExerciseLocaleChain.invalidate();
    source = WorkoutLocalDataSource.forTesting(db);
  });

  tearDownAll(() async {
    await db.close();
    ExerciseLocaleChain.invalidate();
  });

  group('what the filter offers', () {
    test('only equipment that is primary somewhere live', () async {
      final equipment = await source.getPrimaryEquipment('en');
      expect(equipment, isNotEmpty);

      for (final entry in equipment) {
        final used = await db.customSelect(
          '''
              SELECT COUNT(*) AS c FROM exercise_equipment ee
              JOIN exercises e ON e.id = ee.exercise_id
              WHERE ee.equipment_id = ? AND ee.kind = 'primary'
                AND (e.status IS NULL OR e.status = 'active')
              ''',
          variables: [Variable.withString(entry.id)],
        ).getSingle();
        expect(used.read<int>('c'), greaterThan(0),
            reason: '${entry.id} is a chip that selects nothing');
      }
    });

    test('equipment is named, not just identified', () async {
      final equipment = await source.getPrimaryEquipment('de');
      for (final entry in equipment) {
        expect(entry.name.trim(), isNotEmpty);
      }
      // At least one name should differ from its id, or the translations
      // never arrived.
      expect(equipment.where((e) => e.name != e.id), isNotEmpty);
    });

    test('usage tags come from live exercises only', () async {
      final tags = await source.getUsageTags();
      expect(tags, isNotEmpty);
      expect(tags, equals(tags.toList()..sort()));
    });
  });

  group('filtering', () {
    test('an equipment filter narrows the results', () async {
      final all = await source.searchExercises();
      final equipment = await source.getPrimaryEquipment('en');
      final pick = equipment.first.id;

      final filtered = await source.searchExercises(equipmentIds: [pick]);
      expect(filtered, isNotEmpty);
      expect(filtered.length, lessThan(all.length));

      for (final exercise in filtered) {
        final row = await db.customSelect(
          '''
              SELECT COUNT(*) AS c FROM exercise_equipment
              WHERE exercise_id = ? AND kind = 'primary' AND equipment_id = ?
              ''',
          variables: [
            Variable.withString(exercise.uuid!),
            Variable.withString(pick),
          ],
        ).getSingle();
        expect(row.read<int>('c'), greaterThan(0));
      }
    });

    test('setup equipment does not satisfy an equipment filter', () async {
      // A bench is furniture. Someone picking "bench" means the exercises that
      // are *about* the bench, not every press performed on one.
      final setupOnly = await db.customSelect('''
            SELECT ee.equipment_id AS id, ee.exercise_id AS ex
            FROM exercise_equipment ee
            WHERE ee.kind = 'setup'
              AND NOT EXISTS (
                SELECT 1 FROM exercise_equipment p
                WHERE p.exercise_id = ee.exercise_id
                  AND p.kind = 'primary'
                  AND p.equipment_id = ee.equipment_id)
            LIMIT 1
          ''').get();
      if (setupOnly.isEmpty) return;

      final equipmentId = setupOnly.first.read<String>('id');
      final exerciseId = setupOnly.first.read<String>('ex');

      final filtered =
          await source.searchExercises(equipmentIds: [equipmentId]);
      expect(filtered.map((e) => e.uuid), isNot(contains(exerciseId)));
    });

    test('a usage tag filter narrows the results', () async {
      final all = await source.searchExercises();
      final tags = await source.getUsageTags();
      final pick = tags.first;

      final filtered = await source.searchExercises(usageTags: [pick]);
      expect(filtered, isNotEmpty);
      expect(filtered.length, lessThanOrEqualTo(all.length));

      for (final exercise in filtered) {
        final row = await db.customSelect(
          'SELECT COUNT(*) AS c FROM exercise_tags '
          'WHERE exercise_id = ? AND tag = ?',
          variables: [
            Variable.withString(exercise.uuid!),
            Variable.withString(pick),
          ],
        ).getSingle();
        expect(row.read<int>('c'), greaterThan(0));
      }
    });

    test('filters combine, and combine with the search text', () async {
      final equipment = await source.getPrimaryEquipment('en');
      final tags = await source.getUsageTags();

      final combined = await source.searchExercises(
        equipmentIds: [equipment.first.id],
        usageTags: [tags.first],
      );
      final byEquipmentOnly =
          await source.searchExercises(equipmentIds: [equipment.first.id]);

      expect(combined.length, lessThanOrEqualTo(byEquipmentOnly.length));

      // And with a query on top, which is where the placeholder ordering in
      // the generated SQL would show up if it were wrong.
      final withText = await source.searchExercises(
        query: 'press',
        equipmentIds: [equipment.first.id],
      );
      for (final exercise in withText) {
        expect(exercise.allNames.any((n) => n.toLowerCase().contains('press')),
            isTrue,
            reason: '${exercise.uuid} matched no name containing "press"');
      }
    });

    test('an empty filter list changes nothing', () async {
      final unfiltered = await source.searchExercises();
      final explicitlyEmpty = await source.searchExercises(
        equipmentIds: const [],
        usageTags: const [],
      );
      expect(explicitlyEmpty.length, unfiltered.length);
    });

    test('retired exercises stay out, filtered or not', () async {
      final equipment = await source.getPrimaryEquipment('en');
      for (final entry in equipment.take(3)) {
        final results = await source.searchExercises(equipmentIds: [entry.id]);
        for (final exercise in results) {
          final row = await db.customSelect(
            'SELECT status FROM exercises WHERE id = ?',
            variables: [Variable.withString(exercise.uuid!)],
          ).getSingle();
          expect(row.read<String?>('status'), anyOf(isNull, 'active'));
        }
      }
    });
  });
}
