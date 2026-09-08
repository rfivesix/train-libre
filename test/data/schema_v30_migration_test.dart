import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/data/drift_database.dart';

Future<Set<String>> _columnsOf(AppDatabase database, String table) async {
  final rows = await database.customSelect('PRAGMA table_info($table);').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('schema_v30_test_');
    dbFile = File(p.join(tempDir.path, 'v29_to_v30.db'));
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
      'Migration from v29 to the current schema adds columns, backfills data and is idempotent',
      () async {
    // 1. Initialize DB at v30 temporarily and insert baseline data
    final initDb = AppDatabase(NativeDatabase(dbFile));

    final profile = await initDb.into(initDb.profiles).insertReturning(
          ProfilesCompanion.insert(
            id: const drift.Value('profile-v29'),
            visibility: const drift.Value('private'),
          ),
        );

    await initDb.into(initDb.appSettings).insert(
          AppSettingsCompanion.insert(
            userId: profile.id,
            themeMode: const drift.Value('dark'),
            unitSystem: const drift.Value('metric'),
          ),
        );

    final exercise = await initDb.into(initDb.exercises).insertReturning(
          ExercisesCompanion.insert(
            id: const drift.Value('ex-bench-v29'),
            categoryName: const drift.Value('Chest'),
          ),
        );

    final routine = await initDb.into(initDb.routines).insertReturning(
          RoutinesCompanion.insert(
            id: const drift.Value('routine-v29'),
            name: 'Push Day',
          ),
        );

    final routineEx =
        await initDb.into(initDb.routineExercises).insertReturning(
              RoutineExercisesCompanion.insert(
                id: const drift.Value('re-bench-v29'),
                routineId: routine.id,
                exerciseId: exercise.id,
                orderIndex: 0,
              ),
            );

    // Insert 5 templates with various target_reps formats
    await initDb.into(initDb.routineSetTemplates).insert(
          RoutineSetTemplatesCompanion.insert(
            id: const drift.Value('tmpl-1'),
            routineExerciseId: routineEx.id,
            targetReps: const drift.Value('8-12'),
            targetWeight: const drift.Value(80.0),
            targetRir: const drift.Value(2),
          ),
        );

    await initDb.into(initDb.routineSetTemplates).insert(
          RoutineSetTemplatesCompanion.insert(
            id: const drift.Value('tmpl-2'),
            routineExerciseId: routineEx.id,
            targetReps: const drift.Value('8–12'), // en dash
            targetWeight: const drift.Value(82.5),
            targetRir: const drift.Value(1),
          ),
        );

    await initDb.into(initDb.routineSetTemplates).insert(
          RoutineSetTemplatesCompanion.insert(
            id: const drift.Value('tmpl-3'),
            routineExerciseId: routineEx.id,
            targetReps: const drift.Value('10'),
            targetWeight: const drift.Value(75.0),
            targetRir: const drift.Value(3),
          ),
        );

    await initDb.into(initDb.routineSetTemplates).insert(
          RoutineSetTemplatesCompanion.insert(
            id: const drift.Value('tmpl-4'),
            routineExerciseId: routineEx.id,
            targetReps: const drift.Value('AMRAP'),
            targetWeight: const drift.Value(60.0),
          ),
        );

    await initDb.into(initDb.routineSetTemplates).insert(
          RoutineSetTemplatesCompanion.insert(
            id: const drift.Value('tmpl-5'),
            routineExerciseId: routineEx.id,
            targetReps: const drift.Value(null),
            targetWeight: const drift.Value(50.0),
          ),
        );

    final wlog = await initDb.into(initDb.workoutLogs).insertReturning(
          WorkoutLogsCompanion.insert(
            id: const drift.Value('wlog-v29'),
            startTime: DateTime(2026, 1, 1, 10, 0),
            routineNameSnapshot: const drift.Value('Push Day'),
          ),
        );

    // Insert 2 set logs
    await initDb.into(initDb.setLogs).insert(
          SetLogsCompanion.insert(
            id: const drift.Value('set-1'),
            workoutLogId: wlog.id,
            exerciseId: const drift.Value('ex-bench-v29'),
            exerciseNameSnapshot: const drift.Value('Bench Press'),
            weight: const drift.Value(80.0),
            reps: const drift.Value(10),
            isCompleted: const drift.Value(true),
          ),
        );

    await initDb.into(initDb.setLogs).insert(
          SetLogsCompanion.insert(
            id: const drift.Value('set-2'),
            workoutLogId: wlog.id,
            exerciseId: const drift.Value('ex-bench-v29'),
            exerciseNameSnapshot: const drift.Value('Bench Press'),
            weight: const drift.Value(80.0),
            reps: const drift.Value(8),
            isCompleted: const drift.Value(true),
          ),
        );

    // 2. Drop the v30 and v31 columns to revert the schema to Version 29.
    // AppSettings (3 columns)
    await initDb.customStatement(
        'ALTER TABLE app_settings DROP COLUMN training_autonomy_level;');
    await initDb.customStatement(
        'ALTER TABLE app_settings DROP COLUMN nutrition_autonomy_level;');
    await initDb.customStatement(
        'ALTER TABLE app_settings DROP COLUMN experience_level;');

    // RoutineSetTemplates (2 columns)
    await initDb.customStatement(
        'ALTER TABLE routine_set_templates DROP COLUMN target_rep_min;');
    await initDb.customStatement(
        'ALTER TABLE routine_set_templates DROP COLUMN target_rep_max;');

    // SetLogs (10 columns)
    await initDb.customStatement(
        'ALTER TABLE set_logs DROP COLUMN prescription_origin;');
    await initDb.customStatement(
        'ALTER TABLE set_logs DROP COLUMN prescribed_rep_min;');
    await initDb.customStatement(
        'ALTER TABLE set_logs DROP COLUMN prescribed_rep_max;');
    await initDb
        .customStatement('ALTER TABLE set_logs DROP COLUMN prescribed_weight;');
    await initDb
        .customStatement('ALTER TABLE set_logs DROP COLUMN prescribed_rir;');
    await initDb.customStatement(
        'ALTER TABLE set_logs DROP COLUMN prescription_overridden;');
    await initDb.customStatement(
        'ALTER TABLE set_logs DROP COLUMN values_auto_filled;');
    await initDb.customStatement(
        'ALTER TABLE set_logs DROP COLUMN substituted_for_exercise_id;');
    await initDb.customStatement(
        'ALTER TABLE set_logs DROP COLUMN progression_reason;');
    await initDb.customStatement(
        'ALTER TABLE set_logs DROP COLUMN progression_algorithm_version;');
    await initDb
        .customStatement('ALTER TABLE set_logs DROP COLUMN progression_data;');
    await initDb.customStatement(
        'ALTER TABLE routine_exercises DROP COLUMN progression_data;');

    // Set schema user_version to 29
    await initDb.customStatement('PRAGMA user_version = 29;');

    // Verify v29 state: none of the 15 columns exist
    final v29AppSettingsCols = await _columnsOf(initDb, 'app_settings');
    expect(v29AppSettingsCols, isNot(contains('training_autonomy_level')));
    expect(v29AppSettingsCols, isNot(contains('nutrition_autonomy_level')));
    expect(v29AppSettingsCols, isNot(contains('experience_level')));

    final v29TemplateCols = await _columnsOf(initDb, 'routine_set_templates');
    expect(v29TemplateCols, isNot(contains('target_rep_min')));
    expect(v29TemplateCols, isNot(contains('target_rep_max')));

    final v29SetLogCols = await _columnsOf(initDb, 'set_logs');
    expect(v29SetLogCols, isNot(contains('prescription_origin')));
    expect(v29SetLogCols, isNot(contains('prescribed_rep_min')));
    expect(v29SetLogCols, isNot(contains('progression_data')));
    final v29RoutineExerciseCols =
        await _columnsOf(initDb, 'routine_exercises');
    expect(v29RoutineExerciseCols, isNot(contains('progression_data')));

    await initDb.close();

    // 3. Open the current database on the v29 file. This runs the v30
    // prescription migration and the v31 progression snapshot migration.
    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    // Trigger open and migration
    await db.customSelect('SELECT 1;').get();

    // Verify schemaVersion getter
    expect(db.schemaVersion, 31);

    // 4. Verify all 15 new columns exist
    final migratedAppSettingsCols = await _columnsOf(db, 'app_settings');
    expect(
      migratedAppSettingsCols,
      containsAll([
        'training_autonomy_level',
        'nutrition_autonomy_level',
        'experience_level',
      ]),
    );

    final migratedTemplateCols = await _columnsOf(db, 'routine_set_templates');
    expect(
      migratedTemplateCols,
      containsAll([
        'target_rep_min',
        'target_rep_max',
      ]),
    );

    final migratedSetLogCols = await _columnsOf(db, 'set_logs');
    expect(
      migratedSetLogCols,
      containsAll([
        'prescription_origin',
        'prescribed_rep_min',
        'prescribed_rep_max',
        'prescribed_weight',
        'prescribed_rir',
        'prescription_overridden',
        'values_auto_filled',
        'substituted_for_exercise_id',
        'progression_reason',
        'progression_algorithm_version',
      ]),
    );

    expect(migratedSetLogCols, contains('progression_data'));
    final migratedRoutineExerciseCols =
        await _columnsOf(db, 'routine_exercises');
    expect(migratedRoutineExerciseCols, contains('progression_data'));

    // 5. Verify pre-existing data and backfilled values
    // AppSettings: defaults 'off', 'suggest', 'pro', preserving themeMode 'dark'
    final settings = await (db.select(db.appSettings)
          ..where((t) => t.userId.equals('profile-v29')))
        .getSingle();
    expect(settings.trainingAutonomyLevel, equals('off'));
    expect(settings.nutritionAutonomyLevel, equals('suggest'));
    expect(settings.experienceLevel, equals('pro'));
    expect(settings.themeMode, equals('dark'));
    expect(settings.unitSystem, equals('metric'));

    // RoutineSetTemplates: target_rep_min/max backfills
    final templates = await (db.select(db.routineSetTemplates)
          ..orderBy([(t) => drift.OrderingTerm.asc(t.id)]))
        .get();
    final t1 = templates.firstWhere((t) => t.id == 'tmpl-1');
    expect(t1.targetReps, equals('8-12'));
    expect(t1.targetRepMin, equals(8));
    expect(t1.targetRepMax, equals(12));
    expect(t1.targetWeight, equals(80.0));
    expect(t1.targetRir, equals(2));

    final t2 = templates.firstWhere((t) => t.id == 'tmpl-2');
    expect(t2.targetReps, equals('8–12'));
    expect(t2.targetRepMin, equals(8));
    expect(t2.targetRepMax, equals(12));
    expect(t2.targetWeight, equals(82.5));

    final t3 = templates.firstWhere((t) => t.id == 'tmpl-3');
    expect(t3.targetReps, equals('10'));
    expect(t3.targetRepMin, equals(10));
    expect(t3.targetRepMax, equals(10));

    final t4 = templates.firstWhere((t) => t.id == 'tmpl-4');
    expect(t4.targetReps, equals('AMRAP'));
    expect(t4.targetRepMin, isNull);
    expect(t4.targetRepMax, isNull);

    final t5 = templates.firstWhere((t) => t.id == 'tmpl-5');
    expect(t5.targetReps, isNull);
    expect(t5.targetRepMin, isNull);
    expect(t5.targetRepMax, isNull);

    // SetLogs: every pre-existing row has prescription_origin = 'none'
    final setLogs = await (db.select(db.setLogs)
          ..orderBy([(t) => drift.OrderingTerm.asc(t.id)]))
        .get();
    expect(setLogs.length, equals(2));
    for (final set in setLogs) {
      expect(set.prescriptionOrigin, equals('none'));
      expect(set.prescribedRepMin, isNull);
      expect(set.prescribedRepMax, isNull);
      expect(set.prescribedWeight, isNull);
      expect(set.prescribedRir, isNull);
      expect(set.prescriptionOverridden, isFalse);
      expect(set.valuesAutoFilled, isFalse);
      expect(set.substitutedForExerciseId, isNull);
      expect(set.progressionReason, isNull);
      expect(set.progressionAlgorithmVersion, isNull);
      // Pre-existing data intact
      expect(set.weight, equals(80.0));
      expect(set.exerciseNameSnapshot, equals('Bench Press'));
    }

    // 6. Test Idempotency: Running onUpgrade(29 -> 30) again must not fail
    final migrator = db.createMigrator();
    await expectLater(
      db.migration.onUpgrade(migrator, 29, 30),
      completes,
    );

    // Verify data remains consistent after second upgrade run
    final settingsAfter = await (db.select(db.appSettings)
          ..where((t) => t.userId.equals('profile-v29')))
        .getSingle();
    expect(settingsAfter.trainingAutonomyLevel, equals('off'));
    expect(settingsAfter.nutritionAutonomyLevel, equals('suggest'));
    expect(settingsAfter.experienceLevel, equals('pro'));
  });
}
