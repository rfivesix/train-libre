import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart' show AppDatabase;
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart'
    as model;
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';
import 'package:train_libre/features/workout/domain/models/prescription_enums.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/domain/progression/progression_v15.dart';
import 'package:train_libre/features/workout/domain/services/workout_progression_service.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';
import 'package:train_libre/services/training_autonomy_service.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 7, 12, 0);

  late AppDatabase database;
  late WorkoutLocalDataSource workoutDb;
  late WorkoutRepository repository;
  late UnitService unitService;
  late WorkoutProgressionService progressionService;
  late TrainingAutonomyService autonomyService;
  late LiveWorkoutViewModel vm;

  model.Exercise createExercise({
    String equipment = 'barbell',
    String? loadMode = 'external',
    String trackingType = 'weight_reps',
  }) {
    return model.Exercise.single(
      uuid: 'ex-bench',
      languageCode: 'en',
      name: 'Bench Press',
      categoryName: 'Chest',
      primaryMuscles: ['Chest'],
      secondaryMuscles: ['Triceps'],
      trackingType: trackingType,
      loadMode: loadMode,
      primaryEquipment: equipment,
    );
  }

  RoutineExercise createRoutineExercise({
    required model.Exercise exercise,
    List<SetTemplate>? templates,
  }) {
    return RoutineExercise(
      id: 10,
      exercise: exercise,
      pauseSeconds: 60,
      setTemplates: templates ??
          [
            SetTemplate(
              id: 101,
              setType: 'normal',
              targetRepMin: 8,
              targetRepMax: 12,
            ),
            SetTemplate(
              id: 102,
              setType: 'normal',
              targetRepMin: 8,
              targetRepMax: 12,
            ),
          ],
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'unit_system': 'metric',
      'training_autonomy_level': 'suggest',
    });
    database = AppDatabase(NativeDatabase.memory());
    workoutDb = WorkoutLocalDataSource.forTesting(database);
    repository = WorkoutRepository(localDataSource: workoutDb);

    unitService = UnitService();
    await unitService.setUnitSystem(UnitSystem.metric);

    autonomyService = TrainingAutonomyService(database);
    await autonomyService.initialize();
    await autonomyService.setLevel(AutonomyLevel.suggest);

    progressionService = WorkoutProgressionService(
      repository: repository,
      unitService: unitService,
    );

    vm = LiveWorkoutViewModel.forTesting(
      workoutDb: repository,
      unitService: unitService,
      progressionService: progressionService,
      trainingAutonomyService: autonomyService,
    );
  });

  tearDown(() async {
    await vm.pendingProgressionUpdate;
    vm.dispose();
    await database.close();
  });

  Future<void> seedHistorySets({
    required double weightKg,
    required int reps,
    required DateTime date,
  }) async {
    final prevLog = await workoutDb.startWorkout(routineName: 'Previous Push');
    await workoutDb.finishWorkout(prevLog.id!);

    final setLog = SetLog(
      workoutLogId: prevLog.id!,
      exerciseId: 'ex-bench',
      exerciseName: 'Bench Press',
      setType: 'normal',
      weightKg: weightKg,
      reps: reps,
      isCompleted: true,
      performedAt: date,
    );
    await workoutDb.insertSetLog(setLog.copyWith(logOrder: 0));
    await workoutDb.insertSetLog(setLog.copyWith(logOrder: 1));
  }

  Future<void> seedV15(List<(double, int)> performances,
      {LoadMode mode = LoadMode.external}) async {
    final previous = await workoutDb.startWorkout(routineName: 'history');
    await workoutDb.finishWorkout(previous.id!);
    for (var i = 0; i < performances.length; i++) {
      await workoutDb.insertSetLog(SetLog(
          workoutLogId: previous.id!,
          exerciseId: 'ex-bench',
          exerciseName: 'Old name',
          setType: 'normal',
          weightKg: performances[i].$1,
          reps: performances[i].$2,
          isCompleted: true,
          logOrder: i,
          prescribedRepMin: 8,
          prescribedRepMax: 12,
          progressionData: ProgressionConfig(loadMode: mode).encode()));
    }
  }

  test('v1.5 selects and snapshots the visible authored default once',
      () async {
    final templates = [
      SetTemplate(
          id: 101,
          setType: 'normal',
          targetWeight: 60,
          targetRepMin: 8,
          targetRepMax: 12),
      SetTemplate(
          id: 102,
          setType: 'normal',
          targetWeight: 60,
          targetRepMin: 8,
          targetRepMax: 12),
    ];
    final routineExercise = createRoutineExercise(
      exercise: createExercise(),
      templates: templates,
    );
    final workout = await workoutDb.startWorkout(routineName: 'uniform');

    await vm.loadInitialData(workout, [routineExercise]);

    expect(vm.exercises.single.progression.policy,
        ProgressionPolicy.independentWorkingSets);
    expect(
        vm.setLogs.values.every((set) =>
            set.progression.policy == ProgressionPolicy.independentWorkingSets),
        isTrue);
    expect(
        vm.setLogs.values.map((set) => set.progression.prescriptionKey).toSet(),
        hasLength(1));
  });

  test('v1.5 reads legacy null-ID history but rejects a different UUID',
      () async {
    final legacyWorkout =
        await workoutDb.startWorkout(routineName: 'legacy history');
    await workoutDb.finishWorkout(legacyWorkout.id!);
    await workoutDb.insertSetLog(SetLog(
      workoutLogId: legacyWorkout.id!,
      exerciseName: 'Bench Press',
      setType: 'normal',
      weightKg: 60,
      reps: 12,
      isCompleted: true,
      logOrder: 0,
      prescribedRepMin: 8,
      prescribedRepMax: 12,
    ));
    await workoutDb.insertSetLog(SetLog(
      workoutLogId: legacyWorkout.id!,
      exerciseId: 'a-different-exercise',
      exerciseName: 'Bench Press',
      setType: 'normal',
      weightKg: 200,
      reps: 12,
      isCompleted: true,
      logOrder: 1,
      prescribedRepMin: 8,
      prescribedRepMax: 12,
    ));
    final routineExercise = createRoutineExercise(
      exercise: createExercise(),
      templates: [
        SetTemplate(
            id: 101, setType: 'normal', targetRepMin: 8, targetRepMax: 12),
      ],
    );
    final workout = await workoutDb.startWorkout(routineName: 'today');

    await vm.loadInitialData(workout, [routineExercise]);

    expect(vm.setLogs[101]!.weightKg, 62.5);
  });

  test('v1.5 independent positions survive heavier and lighter manual anchors',
      () async {
    await seedV15([(60, 12), (60, 10)]);
    final re = createRoutineExercise(exercise: createExercise()).copyWith(
        progressionData: const ProgressionConfig(
                policy: ProgressionPolicy.independentWorkingSets)
            .encode());
    final workout = await workoutDb.startWorkout(routineName: 'independent');
    await vm.loadInitialData(workout, [re]);
    expect(vm.setLogs[101]!.weightKg, 62.5);
    await vm.updateSet(101, weight: 40, reps: 9, isCompleted: true);
    await vm.pendingProgressionUpdate;
    expect(vm.setLogs[102]!.weightKg, 60);
    await vm.updateSet(101, weight: 80, reps: 9);
    await vm.pendingProgressionUpdate;
    expect(vm.setLogs[102]!.weightKg, 60);
    expect(vm.setLogs[102]!.progression.policy,
        ProgressionPolicy.independentWorkingSets);
    await vm.addSetToExercise(10);
    await vm.pendingProgressionUpdate;
    final added = vm.exercises.single.setTemplates.last.id!;
    expect(vm.setLogs[added]!.weightKg, 80);
    expect(vm.setLogs[added]!.progressionReason,
        ProgressionReason.inWorkoutFallback);
  });

  test('v1.5 coarse trial and bridge decisions persist without changing range',
      () async {
    await seedV15([(8, 12), (8, 12)]);
    final re = createRoutineExercise(exercise: createExercise()).copyWith(
        progressionData: ProgressionConfig(
                policy: ProgressionPolicy.independentWorkingSets,
                ladder: LoadLadder([8, 10], source: LoadLadderSource.user))
            .encode());
    final workout = await workoutDb.startWorkout(routineName: 'coarse');
    await vm.loadInitialData(workout, [re]);
    expect(vm.setLogs[101]!.weightKg, 8);
    final trial = vm.reviewsFor(101).single;
    expect(trial.kind, ReviewKind.largeStepTrial);
    await vm.decideReview(101, trial, ReviewAction.rejected);
    final bridge = vm.reviewsFor(101).single;
    expect(bridge.targetReps, 14);
    await vm.decideReview(101, bridge, ReviewAction.accepted);
    expect(vm.setLogs[101]!.reps, 14);
    expect(vm.setLogs[101]!.prescribedRepMax, 12);
    expect(vm.setLogs[101]!.progression.bridgeTarget, 14);
    expect(vm.setLogs[101]!.progression.bridgeLoad, 8);
    final restored = (await repository.getSetLogsForWorkout(workout.id!)).first;
    expect(restored.progression.events.map((e) => e.action), [
      ReviewAction.offered,
      ReviewAction.rejected,
      ReviewAction.offered,
      ReviewAction.accepted
    ]);
    expect(
        restored.progressionAlgorithmVersion, ProgressionV15.algorithmVersion);
    await vm.updateSet(101, isCompleted: true);
    expect(vm.setLogs[101]!.valuesAutoFilled, true);
  });

  test('completing a set closes its pending target decision', () async {
    await seedV15([(8, 12), (8, 12)]);
    final re = createRoutineExercise(exercise: createExercise()).copyWith(
        progressionData: ProgressionConfig(
                policy: ProgressionPolicy.independentWorkingSets,
                ladder: LoadLadder([8, 10], source: LoadLadderSource.user))
            .encode());
    final workout = await workoutDb.startWorkout(routineName: 'coarse');
    await vm.loadInitialData(workout, [re]);

    expect(vm.reviewsFor(101).single.kind, ReviewKind.largeStepTrial);

    await vm.updateSet(101, isCompleted: true);
    await vm.pendingProgressionUpdate;

    expect(vm.reviewsFor(101), isEmpty);
    expect(
      vm.setLogs[101]!.progression.events.last.action,
      ReviewAction.dismissed,
    );
    expect(vm.setLogs[101]!.progression.events.last.note, 'set_completed');
  });

  test('v1.5 completion states persist and never anchor', () async {
    final re = createRoutineExercise(exercise: createExercise());
    final workout = await workoutDb.startWorkout(routineName: 'interruption');
    await vm.loadInitialData(workout, [re]);
    await vm.updateSet(101, weight: 80, reps: 15);
    await vm.setCompletion(101, SetCompletion.stoppedForPain);
    await vm.pendingProgressionUpdate;
    expect(vm.isSetSuggested(102), false);
    expect(vm.reviewsFor(101), isEmpty);
    final restored = (await repository.getSetLogsForWorkout(workout.id!)).first;
    expect(restored.progression.completion, SetCompletion.stoppedForPain);
  });

  test('completion prompt belongs only to the latest under-target working set',
      () async {
    final re = createRoutineExercise(exercise: createExercise());
    final workout = await workoutDb.startWorkout(routineName: 'under target');
    await vm.loadInitialData(workout, [re]);

    await vm.updateSet(101, weight: 60, reps: 6, isCompleted: true);
    await vm.pendingProgressionUpdate;
    expect(vm.latestCompletedWorkingTemplateId, 101);
    expect(vm.shouldShowCompletionPicker(101), isTrue);
    expect(vm.shouldShowCompletionPicker(102), isFalse);

    await vm.setCompletion(101, SetCompletion.completed);
    await vm.pendingProgressionUpdate;
    expect(vm.shouldShowCompletionPicker(101), isFalse);

    await vm.updateSet(102, weight: 60, reps: 8, isCompleted: true);
    await vm.pendingProgressionUpdate;
    expect(vm.latestCompletedWorkingTemplateId, 102);
    expect(vm.shouldShowCompletionPicker(101), isFalse);
    expect(vm.shouldShowCompletionPicker(102), isFalse);
  });

  test('completion prompt compares against the concrete engine rep target',
      () async {
    await seedV15([(60, 10), (60, 10)]);
    final re = createRoutineExercise(exercise: createExercise()).copyWith(
        progressionData: const ProgressionConfig(
                policy: ProgressionPolicy.independentWorkingSets)
            .encode());
    final workout = await workoutDb.startWorkout(routineName: 'exact target');
    await vm.loadInitialData(workout, [re]);
    expect(vm.setLogs[101]!.reps, 11);

    await vm.updateSet(101, weight: 60, reps: 10, isCompleted: true);
    await vm.pendingProgressionUpdate;

    expect(vm.shouldShowCompletionPicker(101), isTrue);
    await vm.setCompletion(101, SetCompletion.equipmentInterrupted);
    await vm.pendingProgressionUpdate;
    expect(vm.shouldShowCompletionPicker(101), isFalse);
    expect(vm.reviewsFor(101), isEmpty);
  });

  test('completion prompt detects a lower concrete load', () async {
    final re = createRoutineExercise(
      exercise: createExercise(),
      templates: [
        SetTemplate(
          id: 101,
          setType: 'normal',
          targetWeight: 62.5,
          targetRepMin: 8,
          targetRepMax: 12,
        ),
      ],
    );
    final workout = await workoutDb.startWorkout(routineName: 'lower load');
    await vm.loadInitialData(workout, [re]);

    await vm.updateSet(101, weight: 60, reps: 8, isCompleted: true);
    await vm.pendingProgressionUpdate;

    expect(vm.shouldShowCompletionPicker(101), isTrue);
  });

  test('v1.5 stores an overshoot review without showing it on the closed set',
      () async {
    final re = createRoutineExercise(exercise: createExercise());
    final workout = await workoutDb.startWorkout(routineName: 'overshoot');
    await vm.loadInitialData(workout, [re]);
    await vm.updateSet(101, weight: 60, reps: 15, isCompleted: true);
    await vm.pendingProgressionUpdate;
    expect(vm.reviewsFor(101), isEmpty);
    final review = vm.setLogs[101]!.progression.events
        .where((event) => event.action == ReviewAction.offered)
        .map((event) => event.review)
        .single;
    expect(review.kind, ReviewKind.farAboveRange);
    expect(vm.setLogs[101]!.weightKg, 60);
  });

  test(
      'v1.5 bodyweight boundary changes all open positions only after confirmation',
      () async {
    await seedV15([(0, 12), (0, 12)], mode: LoadMode.bodyweight);
    final re = createRoutineExercise(
            exercise: createExercise(
                loadMode: 'bodyweight', trackingType: 'bodyweight_reps'))
        .copyWith(
            progressionData: ProgressionConfig(
                    policy: ProgressionPolicy.independentWorkingSets,
                    loadMode: LoadMode.bodyweight,
                    ladder: LoadLadder([2.5, 5], source: LoadLadderSource.user))
                .encode());
    final workout = await workoutDb.startWorkout(routineName: 'bodyweight');
    await vm.loadInitialData(workout, [re]);
    final review = vm.reviewsFor(101).single;
    expect(review.kind, ReviewKind.modeBoundary);
    expect(vm.setLogs[101]!.weightKg, 0);
    await vm.decideReview(101, review, ReviewAction.accepted);
    for (final id in [101, 102]) {
      expect(vm.setLogs[id]!.weightKg, 2.5);
      expect(vm.setLogs[id]!.progression.loadMode, LoadMode.weightedBodyweight);
    }
    final stored = await repository.getSetLogsForWorkout(workout.id!);
    expect(
        stored.every(
            (s) => s.progression.loadMode == LoadMode.weightedBodyweight),
        true);
  });

  group('Live Workout Progression Integration', () {
    test('never pre-fills a warm-up; it targets the first open working set',
        () async {
      await seedHistorySets(
        weightKg: 80.0,
        reps: 12,
        date: now.subtract(const Duration(days: 2)),
      );
      final exercise = createExercise();
      final routineEx = createRoutineExercise(
        exercise: exercise,
        templates: [
          SetTemplate(
            id: 100,
            setType: 'warmup',
            targetRepMin: 8,
            targetRepMax: 12,
          ),
          SetTemplate(
            id: 101,
            setType: 'normal',
            targetRepMin: 8,
            targetRepMax: 12,
          ),
        ],
      );
      final log = await workoutDb.startWorkout(routineName: 'Chest Day');

      await vm.loadInitialData(log, [routineEx]);

      expect(vm.isSetSuggested(100), isFalse);
      expect(vm.isSetSuggested(101), isTrue);
    });

    test('recalculates every later working set from today\'s completed set',
        () async {
      final previous =
          await workoutDb.startWorkout(routineName: 'Previous Push');
      await workoutDb.finishWorkout(previous.id!);
      await workoutDb.insertSetLog(SetLog(
        workoutLogId: previous.id!,
        exerciseId: 'ex-bench',
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 35,
        reps: 8,
        isCompleted: true,
        performedAt: now.subtract(const Duration(days: 2)),
        logOrder: 1,
      ));
      await workoutDb.insertSetLog(SetLog(
        workoutLogId: previous.id!,
        exerciseId: 'ex-bench',
        exerciseName: 'Bench Press',
        setType: 'normal',
        weightKg: 30,
        reps: 12,
        isCompleted: true,
        performedAt: now.subtract(const Duration(days: 2)),
        logOrder: 2,
      ));
      final exercise = createExercise();
      final routineEx = createRoutineExercise(exercise: exercise);
      final log = await workoutDb.startWorkout(routineName: 'Chest Day');

      await vm.loadInitialData(log, [routineEx]);
      await vm.updateSet(101, weight: 40, reps: 8, isCompleted: true);
      await vm.pendingProgressionUpdate;

      expect(vm.isSetSuggested(102), isTrue);
      expect(vm.weightControllers[102]?.text, equals('35'));
    });

    test('an added set follows today\'s last working set, never a drop set',
        () async {
      final exercise = createExercise();
      final routineEx = createRoutineExercise(exercise: exercise);
      final log = await workoutDb.startWorkout(routineName: 'Chest Day');

      await vm.loadInitialData(log, [routineEx]);
      await vm.updateSet(101, weight: 40, reps: 9, isCompleted: true);
      await vm.pendingProgressionUpdate;
      await vm.addSetToExercise(10);
      await vm.pendingProgressionUpdate;

      final addedTemplateId = vm.exercises.single.setTemplates.last.id!;
      expect(vm.isSetSuggested(addedTemplateId), isTrue);
      expect(vm.weightControllers[addedTemplateId]?.text, equals('40'));
      expect(vm.repsControllers[addedTemplateId]?.text, equals('10'));
    });

    test('Programmatic controller updates do NOT trigger markSetOverridden',
        () async {
      await seedHistorySets(
        weightKg: 80.0,
        reps: 12,
        date: now.subtract(const Duration(days: 2)),
      );

      final exercise = createExercise();
      final routineEx = createRoutineExercise(exercise: exercise);
      final log = await workoutDb.startWorkout(routineName: 'Chest Day');

      await vm.loadInitialData(log, [routineEx]);

      // Set 101 is the first open set: suggestion raised to 82.5 kg
      expect(vm.isSetSuggested(101), isTrue);
      expect(vm.weightControllers[101]?.text, equals('82.50'));

      // Programmatically changing controller text does NOT trigger markSetOverridden
      vm.weightControllers[101]?.text = '82.50';
      expect(vm.isSetSuggested(101), isTrue);
    });

    test(
        'Suggestion pre-filled when autonomy is suggest, marked overridden when user modifies weight',
        () async {
      await seedHistorySets(
        weightKg: 80.0,
        reps: 12,
        date: now.subtract(const Duration(days: 2)),
      );

      final exercise = createExercise();
      final routineEx = createRoutineExercise(exercise: exercise);
      final log = await workoutDb.startWorkout(routineName: 'Chest Day');

      await vm.loadInitialData(log, [routineEx]);

      expect(vm.isSetSuggested(101), isTrue);

      // User modifies weight to 80 (simulated via markSetOverridden)
      vm.markSetOverridden(101);
      expect(vm.isSetSuggested(101), isFalse);

      // Completing the set records provenance with prescriptionOverridden = true
      await vm.updateSet(
        101,
        weight: 80.0,
        reps: 10,
        isCompleted: true,
      );
      await vm.pendingProgressionUpdate;

      final completedSet = vm.setLogs[101]!;
      expect(completedSet.prescriptionOrigin, equals('engine'));
      expect(completedSet.prescribedWeight, equals(82.5));
      expect(completedSet.prescriptionOverridden, isTrue);
      expect(completedSet.progressionReason, equals('ordinaryStep'));
      expect(
          completedSet.progressionAlgorithmVersion, equals('progression_v1.5'));
    });

    test(
        'Set completed accepting suggestion records prescriptionOverridden = false',
        () async {
      await seedHistorySets(
        weightKg: 80.0,
        reps: 12,
        date: now.subtract(const Duration(days: 2)),
      );

      final exercise = createExercise();
      final routineEx = createRoutineExercise(exercise: exercise);
      final log = await workoutDb.startWorkout(routineName: 'Chest Day');

      await vm.loadInitialData(log, [routineEx]);

      // Complete set without modifying weight (accepted suggestion 82.5)
      await vm.updateSet(
        101,
        isCompleted: true,
      );
      await vm.pendingProgressionUpdate;

      final completedSet = vm.setLogs[101]!;
      expect(completedSet.prescriptionOrigin, equals('engine'));
      expect(completedSet.prescribedWeight, equals(82.5));
      expect(completedSet.prescriptionOverridden, isFalse);
      expect(completedSet.weightKg, equals(82.5));
    });

    test(
        'Explicit routine target weight is not pre-filled and not marked suggested',
        () async {
      await seedHistorySets(
        weightKg: 80.0,
        reps: 12,
        date: now.subtract(const Duration(days: 2)),
      );

      final exercise = createExercise();
      final routineEx = createRoutineExercise(
        exercise: exercise,
        templates: [
          SetTemplate(
            id: 201,
            setType: 'normal',
            targetWeight: 90.0, // explicit routine weight
            targetRepMin: 8,
            targetRepMax: 12,
          ),
        ],
      );
      final log = await workoutDb.startWorkout(routineName: 'Chest Day');

      await vm.loadInitialData(log, [routineEx]);

      expect(vm.isSetSuggested(201), isFalse);
      // Routine explicit weight is in controller as hint/initial but provenance is 'routine'
      await vm.updateSet(201, reps: 8, isCompleted: true);
      expect(vm.setLogs[201]!.prescriptionOrigin, equals('routine'));
    });

    test('Toggling autonomy to off clears suggestions from uncompleted sets',
        () async {
      await seedHistorySets(
        weightKg: 80.0,
        reps: 12,
        date: now.subtract(const Duration(days: 2)),
      );

      final exercise = createExercise();
      final routineEx = createRoutineExercise(exercise: exercise);
      final log = await workoutDb.startWorkout(routineName: 'Chest Day');

      await vm.loadInitialData(log, [routineEx]);
      expect(vm.isSetSuggested(101), isTrue);

      // Toggle autonomy to off
      await autonomyService.setLevel(AutonomyLevel.off);

      expect(vm.isSetSuggested(101), isFalse);
      expect(vm.weightControllers[101]?.text, isEmpty);
    });
  });
}
