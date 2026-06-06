import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/statistics/domain/recovery_domain_service.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart'
    as domain_set;
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart'
    as model;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutLocalDataSource query semantics', () {
    late AppDatabase database;
    late WorkoutLocalDataSource helper;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      helper = WorkoutLocalDataSource.forTesting(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('getAllCategories returns sorted unique non-empty categories',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Bench Press'),
              nameEn: const drift.Value('Bench Press'),
              categoryName: const drift.Value('Strength'),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Running'),
              nameEn: const drift.Value('Running'),
              categoryName: const drift.Value('Cardio'),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Push-up'),
              nameEn: const drift.Value('Push-up'),
              categoryName: const drift.Value('Strength'),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('No Category'),
              nameEn: const drift.Value('No Category'),
              categoryName: const drift.Value(''),
            ),
          );

      final categories = await helper.getAllCategories();

      expect(categories, ['Cardio', 'Strength']);
    });

    test('getExercisePRs calculates correct brackets and estimated 1RM',
        () async {
      final log = await helper.startWorkout(routineName: 'PR Test');

      // 1 RM: 100kg
      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: log.id!,
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 100,
        reps: 1,
        isCompleted: true,
        logOrder: 0,
      ));

      // 5 RM: 90kg (Bracket 4-6 RM)
      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: log.id!,
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 90,
        reps: 5,
        isCompleted: true,
        logOrder: 1,
      ));

      // 12 RM: 70kg (Bracket 11-15 RM)
      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: log.id!,
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 70,
        reps: 12,
        isCompleted: true,
        logOrder: 2,
      ));

      final prs = await helper.getExercisePRs('Bench Press');

      expect(prs['1 RM']?.weightKg, 100);
      expect(prs['4-6 RM']?.weightKg, 90);
      expect(prs['11-15 RM']?.weightKg, 70);
      expect(prs['2-3 RM'], isNull);

      // Brzycki for 90kg x 5: 90 / (1.0278 - 0.0278 * 5) = 90 / 0.8888 = 101.26
      // Brzycki for 100kg x 1: 100 / (1.0278 - 0.0278 * 1) = 100 / 1.0 = 100
      // So Est. 1RM should be from the 90x5 set.
      expect(prs['Est. 1RM']?.weightKg, 90);
      expect(prs['Est. 1RM']?.reps, 5);
    });

    test('getWeeklyVolumeData aggregates tonnage and sets correctly by week',
        () async {
      final now = DateTime.now();

      // Workout this week
      final log1 = await helper.startWorkout(routineName: 'Week 0');
      await (database.update(database.workoutLogs)
            ..where((t) => t.localId.equals(log1.id!)))
          .write(db.WorkoutLogsCompanion(
        status: const drift.Value('completed'),
        startTime: drift.Value(now),
      ));

      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: log1.id!,
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 100,
        reps: 10,
        isCompleted: true,
        logOrder: 0,
      ));

      // Workout last week
      final lastWeek = now.subtract(const Duration(days: 7));
      final log2 = await helper.startWorkout(routineName: 'Week -1');
      await (database.update(database.workoutLogs)
            ..where((t) => t.localId.equals(log2.id!)))
          .write(db.WorkoutLogsCompanion(
        status: const drift.Value('completed'),
        startTime: drift.Value(lastWeek),
      ));

      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: log2.id!,
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 50,
        reps: 10,
        isCompleted: true,
        logOrder: 0,
      ));

      final data = await helper.getWeeklyVolumeData(weeksBack: 4);

      // Check if we found both entries
      final thisWeekEntry =
          data.firstWhere((e) => (e['tonnage'] as double) > 900);
      final lastWeekEntry =
          data.firstWhere((e) => (e['tonnage'] as double) == 500);

      expect(thisWeekEntry['tonnage'], 1000.0);
      expect(thisWeekEntry['setCount'], 1);
      expect(lastWeekEntry['tonnage'], 500.0);
      expect(lastWeekEntry['setCount'], 1);
    });

    test('getMuscleGroupAnalytics calculates volume and sets per muscle group',
        () async {
      final now = DateTime.now();

      // Create an exercise with muscles
      await helper.insertExercise(
        const model.Exercise(
          nameDe: 'Bankdruecken',
          nameEn: 'Bench Press',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Strength',
          primaryMuscles: ['chest'],
          secondaryMuscles: ['triceps'],
        ),
      );

      final log = await helper.startWorkout(routineName: 'Muscle Test');
      await (database.update(database.workoutLogs)
            ..where((t) => t.localId.equals(log.id!)))
          .write(db.WorkoutLogsCompanion(
        status: const drift.Value('completed'),
        startTime: drift.Value(now),
      ));

      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: log.id!,
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 100,
        reps: 10,
        isCompleted: true,
        logOrder: 0,
      ));

      final result = await helper.getMuscleGroupAnalytics(daysBack: 7);

      expect(result['muscles'], isNotEmpty);
      final muscles = result['muscles'] as List;
      final chestEntry = muscles.firstWhere((e) => e['muscleGroup'] == 'chest');
      final tricepsEntry = muscles.firstWhere((e) => e['muscleGroup'] == 'triceps');

      // Primary muscle gets 1.0 contribution
      expect(chestEntry['equivalentSets'], 1.0);

      // Secondary muscle gets 0.3 contribution
      expect(tricepsEntry['equivalentSets'], 0.3);
    });

    test('searchExercises applies query + category filters and keeps name order',
        () async {
      await helper.insertExercise(
        const model.Exercise(
          nameDe: 'Biceps Curl',
          nameEn: 'Biceps Curl',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Strength',
          primaryMuscles: ['biceps'],
          secondaryMuscles: [],
        ),
      );
      await helper.insertExercise(
        const model.Exercise(
          nameDe: 'Bench Press',
          nameEn: 'Bench Press',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Strength',
          primaryMuscles: ['chest'],
          secondaryMuscles: ['triceps'],
        ),
      );
      await helper.insertExercise(
        const model.Exercise(
          nameDe: 'Burpee',
          nameEn: 'Burpee',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Cardio',
          primaryMuscles: ['legs'],
          secondaryMuscles: [],
        ),
      );

      final strengthB = await helper.searchExercises(
        query: 'B',
        selectedCategories: const ['Strength'],
      );

      expect(strengthB.map((e) => e.nameDe).toList(), [
        'Bench Press',
        'Biceps Curl',
      ]);
    });

    test('getAllMuscleGroups parses json and csv-style lists and deduplicates',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Barbell Row'),
              nameEn: const drift.Value('Barbell Row'),
              categoryName: const drift.Value('Strength'),
              musclesPrimary: const drift.Value('["lats","biceps"]'),
              musclesSecondary: const drift.Value('rear_delts, traps'),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Incline Press'),
              nameEn: const drift.Value('Incline Press'),
              categoryName: const drift.Value('Strength'),
              musclesPrimary: const drift.Value('["chest","front_delts"]'),
              musclesSecondary: const drift.Value('["triceps"]'),
            ),
          );

      final groups = await helper.getAllMuscleGroups();

      expect(
        groups,
        [
          'biceps',
          'chest',
          'front_delts',
          'lats',
          'rear_delts',
          'traps',
          'triceps'
        ],
      );
    });

    test('catalog-style upsert updates metadata for existing exercise id',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              id: const drift.Value('catalog-1'),
              nameDe: const drift.Value('Bankdruecken Alt'),
              nameEn: const drift.Value('Bench Press Old'),
              descriptionDe: const drift.Value('alt'),
              descriptionEn: const drift.Value('old'),
              categoryName: const drift.Value('Strength'),
              musclesPrimary: const drift.Value('["chest"]'),
              musclesSecondary: const drift.Value('["triceps"]'),
              source: const drift.Value('base'),
              isCustom: const drift.Value(false),
            ),
          );

      final refreshedCompanion = db.ExercisesCompanion(
        id: const drift.Value('catalog-1'),
        nameDe: const drift.Value('Bankdruecken Neu'),
        nameEn: const drift.Value('Bench Press New'),
        descriptionDe: const drift.Value('neu'),
        descriptionEn: const drift.Value('new'),
        categoryName: const drift.Value('Strength'),
        musclesPrimary: const drift.Value('["chest"]'),
        musclesSecondary: const drift.Value('["front_delts","triceps"]'),
        source: const drift.Value('base'),
        isCustom: const drift.Value(false),
      );

      await database.into(database.exercises).insert(
            refreshedCompanion,
            onConflict: drift.DoUpdate(
              (_) => refreshedCompanion,
              target: [database.exercises.id],
            ),
          );

      final refreshed = await helper.getExerciseByUuid('catalog-1');
      expect(refreshed, isNotNull);
      expect(refreshed!.nameEn, 'Bench Press New');
      expect(refreshed.secondaryMuscles, contains('front_delts'));
    });

    test(
        'catalog-style refresh remains non-destructive for exercises not present',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              id: const drift.Value('catalog-keep'),
              nameDe: const drift.Value('Historische Uebung'),
              nameEn: const drift.Value('Historical Exercise'),
              categoryName: const drift.Value('Strength'),
              source: const drift.Value('base'),
              isCustom: const drift.Value(false),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              id: const drift.Value('catalog-update'),
              nameDe: const drift.Value('Rudern Alt'),
              nameEn: const drift.Value('Row Old'),
              categoryName: const drift.Value('Strength'),
              source: const drift.Value('base'),
              isCustom: const drift.Value(false),
            ),
          );

      final refreshedCompanion = db.ExercisesCompanion(
        id: const drift.Value('catalog-update'),
        nameDe: const drift.Value('Rudern Neu'),
        nameEn: const drift.Value('Row New'),
        categoryName: const drift.Value('Strength'),
        source: const drift.Value('base'),
        isCustom: const drift.Value(false),
      );
      await database.into(database.exercises).insert(
            refreshedCompanion,
            onConflict: drift.DoUpdate(
              (_) => refreshedCompanion,
              target: [database.exercises.id],
            ),
          );

      final names = (await helper
              .searchExercises(query: '', selectedCategories: const []))
          .map((e) => e.nameEn)
          .toList();
      expect(names, containsAll(['Historical Exercise', 'Row New']));
    });

    group('Exercise Catalog Overhaul Overrides', () {
      test('Exercise.duplicateAsCustom creates a valid custom copy', () {
        final original = model.Exercise(
          id: 42,
          uuid: 'orig-uuid',
          source: 'wger',
          nameDe: 'Kniebeuge',
          nameEn: 'Squat',
          descriptionDe: 'Desc DE',
          descriptionEn: 'Desc EN',
          categoryName: 'Strength',
          primaryMuscles: const ['Quadriceps'],
          secondaryMuscles: const ['Glutes'],
        );

        final duplicate = model.Exercise.duplicateAsCustom(original, newUuid: 'new-uuid');

        expect(duplicate.id, isNull);
        expect(duplicate.uuid, 'new-uuid');
        expect(duplicate.source, 'user');
        expect(duplicate.replacesExerciseId, 'orig-uuid');
        expect(duplicate.nameDe, 'Kniebeuge');
        expect(duplicate.nameEn, 'Squat');
        expect(duplicate.descriptionDe, 'Desc DE');
        expect(duplicate.descriptionEn, 'Desc EN');
        expect(duplicate.categoryName, 'Strength');
        expect(duplicate.primaryMuscles, const ['Quadriceps']);
        expect(duplicate.secondaryMuscles, const ['Glutes']);
      });

      test('searchExercises excludes overridden wger exercises', () async {
        // 1. Insert a wger exercise
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('system-1'),
                nameDe: const drift.Value('Bench Press (System)'),
                nameEn: const drift.Value('Bench Press (System)'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('wger'),
                isCustom: const drift.Value(false),
              ),
            );

        // Verify it shows up in search
        var results = await helper.searchExercises(query: 'Bench');
        expect(results.any((e) => e.uuid == 'system-1'), isTrue);

        // 2. Insert user override
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('custom-override-1'),
                replacesExerciseId: const drift.Value('system-1'),
                nameDe: const drift.Value('Bench Press (Custom Override)'),
                nameEn: const drift.Value('Bench Press (Custom Override)'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('user'),
                isCustom: const drift.Value(true),
              ),
            );

        // Verify the system one is hidden and the override is shown
        results = await helper.searchExercises(query: 'Bench');
        expect(results.any((e) => e.uuid == 'system-1'), isFalse);
        expect(results.any((e) => e.uuid == 'custom-override-1'), isTrue);
      });

      test('getExerciseByUuid resolves to override if present', () async {
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('system-2'),
                nameDe: const drift.Value('Squat (System)'),
                nameEn: const drift.Value('Squat (System)'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('wger'),
                isCustom: const drift.Value(false),
              ),
            );

        // Direct UUID resolution of system-2 should yield the system one when no override exists
        var resolved = await helper.getExerciseByUuid('system-2');
        expect(resolved?.uuid, 'system-2');
        expect(resolved?.source, 'wger');

        // Insert override
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('custom-override-2'),
                replacesExerciseId: const drift.Value('system-2'),
                nameDe: const drift.Value('Squat (Custom)'),
                nameEn: const drift.Value('Squat (Custom)'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('user'),
                isCustom: const drift.Value(true),
              ),
            );

        // Direct UUID resolution of system-2 should now yield the custom override
        resolved = await helper.getExerciseByUuid('system-2');
        expect(resolved?.uuid, 'custom-override-2');
        expect(resolved?.source, 'user');
        expect(resolved?.replacesExerciseId, 'system-2');
      });

      test('getExerciseByName prefers custom/user exercises and overrides', () async {
        // Case A: Custom and system exercise sharing same name (without explicit replacesExerciseId link)
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('system-3a'),
                nameDe: const drift.Value('Deadlift'),
                nameEn: const drift.Value('Deadlift'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('wger'),
                isCustom: const drift.Value(false),
              ),
            );
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('custom-3b'),
                nameDe: const drift.Value('Deadlift'),
                nameEn: const drift.Value('Deadlift'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('user'),
                isCustom: const drift.Value(true),
              ),
            );

        var resolved = await helper.getExerciseByName('Deadlift');
        expect(resolved?.uuid, 'custom-3b');
        expect(resolved?.source, 'user');

        // Case B: System exercise override (different names, but linked via replacesExerciseId)
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('system-4'),
                nameDe: const drift.Value('Overhead Press (System)'),
                nameEn: const drift.Value('Overhead Press (System)'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('wger'),
                isCustom: const drift.Value(false),
              ),
            );
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('custom-override-4'),
                replacesExerciseId: const drift.Value('system-4'),
                nameDe: const drift.Value('Overhead Press (Custom)'),
                nameEn: const drift.Value('Overhead Press (Custom)'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('user'),
                isCustom: const drift.Value(true),
              ),
            );

        // Lookup by system name resolves to override
        resolved = await helper.getExerciseByName('Overhead Press (System)');
        expect(resolved?.uuid, 'custom-override-4');
        expect(resolved?.source, 'user');
      });

      test('updateCustomExercise updates user exercise but throws on wger exercise', () async {
        final systemRow = await database.into(database.exercises).insertReturning(
              db.ExercisesCompanion(
                id: const drift.Value('system-5'),
                nameDe: const drift.Value('Pullup'),
                nameEn: const drift.Value('Pullup'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('wger'),
                isCustom: const drift.Value(false),
              ),
            );
        final systemModel = model.Exercise.fromMap({
          'id': systemRow.localId,
          'uuid': systemRow.id,
          'source': systemRow.source,
          'name_de': systemRow.nameDe,
          'name_en': systemRow.nameEn,
          'category_name': systemRow.categoryName,
        });

        final userRow = await database.into(database.exercises).insertReturning(
              db.ExercisesCompanion(
                id: const drift.Value('custom-5'),
                nameDe: const drift.Value('Chinup'),
                nameEn: const drift.Value('Chinup'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('user'),
                isCustom: const drift.Value(true),
              ),
            );
        final userModel = model.Exercise.fromMap({
          'id': userRow.localId,
          'uuid': userRow.id,
          'source': userRow.source,
          'name_de': userRow.nameDe,
          'name_en': userRow.nameEn,
          'category_name': userRow.categoryName,
        });

        // 1. Try to update wger exercise - should fail
        final updatedSystemModel = systemModel.copyWith(nameEn: 'Pullup (Updated)');
        expect(
          () => helper.updateCustomExercise(updatedSystemModel),
          throwsA(isA<Exception>()),
        );

        // Verify name not changed
        final verifySystem = await helper.getExerciseByUuid('system-5');
        expect(verifySystem?.nameEn, 'Pullup');

        // 2. Try to update user exercise - should succeed
        final updatedUserModel = userModel.copyWith(nameEn: 'Chinup (Updated)');
        await helper.updateCustomExercise(updatedUserModel);

        // Verify name changed
        final verifyUser = await helper.getExerciseByUuid('custom-5');
        expect(verifyUser?.nameEn, 'Chinup (Updated)');
      });
    });

    group('Exercise Catalog Search Overhaul', () {
      test('searchExercises applies tokenization and word-order invariant matching', () async {
        await helper.insertExercise(
          const model.Exercise(
            nameDe: 'Barbell Bench Press',
            nameEn: 'Barbell Bench Press',
            descriptionDe: '',
            descriptionEn: '',
            categoryName: 'Strength',
            primaryMuscles: [],
            secondaryMuscles: [],
          ),
        );
        await helper.insertExercise(
          const model.Exercise(
            nameDe: 'Incline Bench Press',
            nameEn: 'Incline Bench Press',
            descriptionDe: '',
            descriptionEn: '',
            categoryName: 'Strength',
            primaryMuscles: [],
            secondaryMuscles: [],
          ),
        );

        // Word-order invariant: "Press Bench Barbell"
        final results = await helper.searchExercises(query: 'Press Bench Barbell');
        
        expect(results.length, 1);
        expect(results.first.nameEn, 'Barbell Bench Press');
      });

      test('searchExercises scores and ranks by 90-day training history and hierarchical priority', () async {
        // Insert system exercises (source = 'wger', isCustom = false)
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('bench-press-uuid'),
                nameDe: const drift.Value('Bench Press'),
                nameEn: const drift.Value('Bench Press'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('wger'),
                isCustom: const drift.Value(false),
              ),
            );
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('incline-bench-press-uuid'),
                nameDe: const drift.Value('Incline Bench Press'),
                nameEn: const drift.Value('Incline Bench Press'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('wger'),
                isCustom: const drift.Value(false),
              ),
            );
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('dumbbell-bench-press-uuid'),
                nameDe: const drift.Value('Dumbbell Bench Press'),
                nameEn: const drift.Value('Dumbbell Bench Press'),
                categoryName: const drift.Value('Strength'),
                source: const drift.Value('wger'),
                isCustom: const drift.Value(false),
              ),
            );

        // Log workout and sets:
        // Set log 1: Dumbbell Bench Press, 10 days ago (within 90-day window)
        final workoutLog1 = await _insertWorkout(
          database,
          id: 'workout-1',
          startTime: DateTime.now().subtract(const Duration(days: 10)),
        );
        await _insertSet(
          database,
          workoutId: workoutLog1,
          exerciseId: 'dumbbell-bench-press-uuid',
          exerciseName: 'Dumbbell Bench Press',
        );

        // Set log 2: Incline Bench Press, 100 days ago (outside 90-day window)
        final workoutLog2 = await _insertWorkout(
          database,
          id: 'workout-2',
          startTime: DateTime.now().subtract(const Duration(days: 100)),
        );
        await _insertSet(
          database,
          workoutId: workoutLog2,
          exerciseId: 'incline-bench-press-uuid',
          exerciseName: 'Incline Bench Press',
        );

        // Search for "Bench Press".
        // 1st: Exact match: "Bench Press" (bench-press-uuid)
        // 2nd: History priority (logged in last 90 days): "Dumbbell Bench Press" (dumbbell-bench-press-uuid)
        // 3rd: Fallback prefix match (or custom/alphabetical): "Incline Bench Press" (incline-bench-press-uuid)
        final results = await helper.searchExercises(query: 'Bench Press');

        expect(results.length, 3);
        expect(results[0].uuid, 'bench-press-uuid');
        expect(results[1].uuid, 'dumbbell-bench-press-uuid');
        expect(results[2].uuid, 'incline-bench-press-uuid');
      });
    });

    test('getRecoveryAnalytics counts bodyweight and weighted strength only',
        () async {
      final now = DateTime.now();
      final workoutId = await _insertWorkout(
        database,
        id: 'recovery-workout-main',
        startTime: now.subtract(const Duration(hours: 2)),
      );
      final ongoingWorkoutId = await _insertWorkout(
        database,
        id: 'recovery-workout-ongoing',
        startTime: now.subtract(const Duration(hours: 1)),
        status: 'ongoing',
      );

      final pushupId = await _insertExercise(
        database,
        id: 'recovery-pushup',
        name: 'Push-up',
        category: 'Strength',
        primaryMuscles: '["chest"]',
      );
      final pullupId = await _insertExercise(
        database,
        id: 'recovery-weighted-pullup',
        name: 'Weighted Pull-up',
        category: 'Strength',
        primaryMuscles: '["lats"]',
      );
      final warmupId = await _insertExercise(
        database,
        id: 'recovery-shoulder-raise',
        name: 'Shoulder Raise',
        category: 'Strength',
        primaryMuscles: '["front_delts"]',
      );
      final runId = await _insertExercise(
        database,
        id: 'recovery-running',
        name: 'Running',
        category: 'Cardio',
        primaryMuscles: '["quads","hamstrings"]',
      );
      final incompleteId = await _insertExercise(
        database,
        id: 'recovery-lunge',
        name: 'Lunge',
        category: 'Strength',
        primaryMuscles: '["glutes"]',
      );

      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: pushupId,
        exerciseName: 'Push-up',
        weight: 0,
        reps: 12,
      );
      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: pullupId,
        exerciseName: 'Weighted Pull-up',
        weight: 10,
        reps: 5,
      );
      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: warmupId,
        exerciseName: 'Shoulder Raise',
        setType: 'warmup',
        weight: 5,
        reps: 15,
      );
      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: runId,
        exerciseName: 'Running',
        reps: 1,
        distance: 5,
        durationSeconds: 1800,
      );
      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: incompleteId,
        exerciseName: 'Lunge',
        reps: 10,
        isCompleted: false,
      );
      await _insertSet(
        database,
        workoutId: ongoingWorkoutId,
        exerciseId: incompleteId,
        exerciseName: 'Lunge',
        reps: 10,
      );

      final analytics = await helper.getRecoveryAnalytics(lookbackDays: 30);
      final muscles = _musclesByName(analytics);

      expect(analytics['hasData'], isTrue);
      // 'lats' is mapped to the 'back' major muscle group.
      expect(muscles.keys, containsAll(['chest', 'back']));
      expect(muscles['chest']!['lastEquivalentSets'], 1.0);
      expect(muscles['back']!['lastEquivalentSets'], 1.0);
      expect(muscles.keys, isNot(contains('front_delts')));
      expect(muscles.keys, isNot(contains('quads')));
      expect(muscles.keys, isNot(contains('hamstrings')));
      expect(muscles.keys, isNot(contains('glutes')));
    });

    test('getRecoveryAnalytics ignores sub-threshold muscle noise', () async {
      final now = DateTime.now();
      final workoutId = await _insertWorkout(
        database,
        id: 'recovery-threshold-workout',
        startTime: now.subtract(const Duration(hours: 2)),
      );
      final exerciseId = await _insertExercise(
        database,
        id: 'recovery-secondary-only',
        name: 'Secondary Only Row',
        category: 'Strength',
        primaryMuscles: '[]',
        secondaryMuscles: '["traps"]',
      );

      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: exerciseId,
        exerciseName: 'Secondary Only Row',
        weight: 20,
        reps: 10,
      );

      final analytics = await helper.getRecoveryAnalytics(lookbackDays: 30);

      expect(
        RecoveryDomainService.minimumSignificantEquivalentSets,
        1.0,
      );
      expect(analytics['hasData'], isFalse);
      expect(analytics['muscles'], isEmpty);
    });

    test('getRecoveryAnalytics uses fixed lookback instead of stale history',
        () async {
      final now = DateTime.now();
      final oldWorkoutId = await _insertWorkout(
        database,
        id: 'recovery-old-workout',
        startTime: now.subtract(const Duration(days: 30)),
      );
      final recentWorkoutId = await _insertWorkout(
        database,
        id: 'recovery-recent-workout',
        startTime: now.subtract(const Duration(hours: 2)),
      );
      final chestId = await _insertExercise(
        database,
        id: 'recovery-old-bench',
        name: 'Bench Press',
        category: 'Strength',
        primaryMuscles: '["chest"]',
      );
      final bicepsId = await _insertExercise(
        database,
        id: 'recovery-recent-curl',
        name: 'Curl',
        category: 'Strength',
        primaryMuscles: '["biceps"]',
      );

      await _insertSet(
        database,
        workoutId: oldWorkoutId,
        exerciseId: chestId,
        exerciseName: 'Bench Press',
        weight: 80,
        reps: 8,
      );
      await _insertSet(
        database,
        workoutId: recentWorkoutId,
        exerciseId: bicepsId,
        exerciseName: 'Curl',
        weight: 20,
        reps: 8,
      );

      final analytics = await helper.getRecoveryAnalytics();
      final muscles = _musclesByName(analytics);

      expect(
        RecoveryDomainService.recoveryLookbackDays,
        14,
      );
      expect(muscles.keys, contains('biceps'));
      expect(muscles.keys, isNot(contains('chest')));
    });

    test('syncRoutineWithWorkout preserves correct template set type order (warmups first) when adding warmup sets', () async {
      final routine = await helper.createRoutine('Sync Routine');
      final exercise = await helper.insertExercise(
        const model.Exercise(
          nameDe: 'Bench Press',
          nameEn: 'Bench Press',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Strength',
          primaryMuscles: ['chest'],
          secondaryMuscles: [],
        ),
      );

      final routineEx = await helper.addExerciseToRoutine(routine.id!, exercise.id!);
      expect(routineEx, isNotNull);

      // Setup initial template: 1 warmup, 2 normal sets
      final templateSets = [
        SetTemplate(setType: 'warmup', targetReps: '15'),
        SetTemplate(setType: 'normal', targetReps: '10'),
        SetTemplate(setType: 'normal', targetReps: '10'),
      ];
      await helper.replaceSetTemplatesForExercise(routineEx!.id!, templateSets);

      // Start workout log
      final workoutLog = await helper.startWorkout(routineName: 'Sync Routine');
      
      // Associate with routine
      final routineRow = await (database.select(database.routines)
            ..where((tbl) => tbl.localId.equals(routine.id!)))
          .getSingle();
      
      await (database.update(database.workoutLogs)
            ..where((tbl) => tbl.localId.equals(workoutLog.id!)))
          .write(db.WorkoutLogsCompanion(
            routineId: drift.Value(routineRow.id),
          ));

      // Insert completed logs (added a warmup set at the end or logged two warmups)
      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: workoutLog.id!,
        exerciseName: 'Bench Press',
        setType: 'warmup',
        reps: 15,
        isCompleted: true,
        logOrder: 0,
      ));
      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: workoutLog.id!,
        exerciseName: 'Bench Press',
        setType: 'warmup',
        reps: 12,
        isCompleted: true,
        logOrder: 1,
      ));
      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: workoutLog.id!,
        exerciseName: 'Bench Press',
        setType: 'normal',
        reps: 10,
        isCompleted: true,
        logOrder: 2,
      ));
      await helper.insertSetLog(domain_set.SetLog(
        workoutLogId: workoutLog.id!,
        exerciseName: 'Bench Press',
        setType: 'normal',
        reps: 10,
        isCompleted: true,
        logOrder: 3,
      ));

      // Synchronize
      await helper.syncRoutineWithWorkout(
        routineUuid: routineRow.id,
        workoutLogId: workoutLog.id!,
      );

      // Verify template order is: warmup, warmup, normal, normal
      final updatedRoutine = await helper.getRoutineById(routine.id!);
      expect(updatedRoutine, isNotNull);
      expect(updatedRoutine!.exercises.length, 1);
      
      final updatedTemplates = updatedRoutine.exercises.first.setTemplates;
      expect(updatedTemplates.length, 4);
      expect(updatedTemplates[0].setType, 'warmup');
      expect(updatedTemplates[1].setType, 'warmup');
      expect(updatedTemplates[2].setType, 'normal');
      expect(updatedTemplates[3].setType, 'normal');
    });

    test('createRoutineFromWorkout correctly creates a routine from a workout log', () async {
      // 1. Setup exercises
      final squatId = await _insertExercise(
        database,
        id: 'squat-uuid',
        name: 'Squat',
        category: 'Strength',
        primaryMuscles: '["quads"]',
      );
      final benchId = await _insertExercise(
        database,
        id: 'bench-uuid',
        name: 'Bench Press',
        category: 'Strength',
        primaryMuscles: '["chest"]',
      );

      // 2. Create a workout log
      final workoutLogIdStr = await _insertWorkout(
        database,
        id: 'workout-for-creation',
        startTime: DateTime.now(),
      );

      // 3. Add sets to the workout log.
      // Exercise 1: Squat. Let's add normal set, warmup set (out of order, e.g. normal first then warmup), and an incomplete set (which should be skipped, isCompleted: false).
      // Normal set 1 (order 0)
      await _insertSet(
        database,
        workoutId: workoutLogIdStr,
        exerciseId: squatId,
        exerciseName: 'Squat',
        setType: 'normal',
        weight: 100.0,
        reps: 5,
        isCompleted: true,
      );
      // Warmup set 1 (order 1)
      await _insertSet(
        database,
        workoutId: workoutLogIdStr,
        exerciseId: squatId,
        exerciseName: 'Squat',
        setType: 'warmup',
        weight: 60.0,
        reps: 8,
        isCompleted: true,
      );
      // Incomplete set (order 2) - should not be included
      await _insertSet(
        database,
        workoutId: workoutLogIdStr,
        exerciseId: squatId,
        exerciseName: 'Squat',
        setType: 'normal',
        weight: 100.0,
        reps: 5,
        isCompleted: false,
      );

      // Exercise 2: Bench Press. Add completed sets with rest times.
      // Normal set 1 (order 3) with rest time 90s (mapped to restTimeSeconds)
      await database.into(database.setLogs).insert(
            db.SetLogsCompanion(
              workoutLogId: drift.Value(workoutLogIdStr),
              exerciseId: drift.Value(benchId),
              exerciseNameSnapshot: drift.Value('Bench Press'),
              setType: drift.Value('normal'),
              weight: drift.Value(80.0),
              reps: drift.Value(10),
              isCompleted: drift.Value(true),
              restTimeSeconds: drift.Value(90),
            ),
          );

      // We need localId (int) of workoutLog. Let's find it.
      final workoutLog = await database.select(database.workoutLogs).getSingle();

      // 4. Create routine from workout log
      final routine = await helper.createRoutineFromWorkout(
        workoutLogId: workoutLog.localId,
        name: 'New Custom Routine',
      );

      expect(routine, isNotNull);
      expect(routine.name, 'New Custom Routine');

      // 5. Verify database records
      // Verify Routine is created
      final dbRoutine = await helper.getRoutineById(routine.id!);
      expect(dbRoutine, isNotNull);
      expect(dbRoutine!.name, 'New Custom Routine');

      // Verify RoutineExercises
      expect(dbRoutine.exercises.length, 2);
      
      // Exercise 1 (Index 0): Squat
      final squatExercise = dbRoutine.exercises[0];
      expect(squatExercise.exercise.uuid, squatId);
      
      // Check set templates for squat: warmup first (weight 60, reps 8), normal second (weight 100, reps 5)
      expect(squatExercise.setTemplates.length, 2); // Excluded incomplete
      expect(squatExercise.setTemplates[0].setType, 'warmup');
      expect(squatExercise.setTemplates[0].targetWeight, 60.0);
      expect(squatExercise.setTemplates[0].targetReps, '8');

      expect(squatExercise.setTemplates[1].setType, 'normal');
      expect(squatExercise.setTemplates[1].targetWeight, 100.0);
      expect(squatExercise.setTemplates[1].targetReps, '5');

      // Exercise 2 (Index 1): Bench Press
      final benchExercise = dbRoutine.exercises[1];
      expect(benchExercise.exercise.uuid, benchId);
      expect(benchExercise.pauseSeconds, 90); // Mapped rest time

      expect(benchExercise.setTemplates.length, 1);
      expect(benchExercise.setTemplates[0].setType, 'normal');
      expect(benchExercise.setTemplates[0].targetWeight, 80.0);
      expect(benchExercise.setTemplates[0].targetReps, '10');
    });
  });
}

Future<String> _insertExercise(
  db.AppDatabase database, {
  required String id,
  required String name,
  required String category,
  required String primaryMuscles,
  String secondaryMuscles = '[]',
}) async {
  final row = await database.into(database.exercises).insertReturning(
        db.ExercisesCompanion(
          id: drift.Value(id),
          nameDe: drift.Value(name),
          nameEn: drift.Value(name),
          categoryName: drift.Value(category),
          musclesPrimary: drift.Value(primaryMuscles),
          musclesSecondary: drift.Value(secondaryMuscles),
        ),
      );
  return row.id;
}

Future<String> _insertWorkout(
  db.AppDatabase database, {
  required String id,
  required DateTime startTime,
  String status = 'completed',
}) async {
  final row = await database.into(database.workoutLogs).insertReturning(
        db.WorkoutLogsCompanion(
          id: drift.Value(id),
          startTime: drift.Value(startTime),
          endTime: drift.Value(startTime.add(const Duration(hours: 1))),
          status: drift.Value(status),
        ),
      );
  return row.id;
}

Future<void> _insertSet(
  db.AppDatabase database, {
  required String workoutId,
  required String exerciseId,
  required String exerciseName,
  String setType = 'normal',
  double? weight,
  int? reps,
  bool isCompleted = true,
  double? distance,
  int? durationSeconds,
}) async {
  await database.into(database.setLogs).insert(
        db.SetLogsCompanion(
          workoutLogId: drift.Value(workoutId),
          exerciseId: drift.Value(exerciseId),
          exerciseNameSnapshot: drift.Value(exerciseName),
          setType: drift.Value(setType),
          weight:
              weight == null ? const drift.Value.absent() : drift.Value(weight),
          reps: reps == null ? const drift.Value.absent() : drift.Value(reps),
          isCompleted: drift.Value(isCompleted),
          distance: distance == null
              ? const drift.Value.absent()
              : drift.Value(distance),
          durationSeconds: durationSeconds == null
              ? const drift.Value.absent()
              : drift.Value(durationSeconds),
        ),
      );
}

Map<String, Map<String, dynamic>> _musclesByName(
  Map<String, dynamic> analytics,
) {
  return {
    for (final muscle
        in (analytics['muscles'] as List<dynamic>).cast<Map<String, dynamic>>())
      muscle['muscleGroup'] as String: muscle,
  };
}
