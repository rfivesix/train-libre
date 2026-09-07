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
import 'package:train_libre/features/workout/domain/progression/double_progression_engine.dart';
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
    await workoutDb.insertSetLog(setLog);
  }

  group('Live Workout Progression Integration', () {
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
      expect(completedSet.progressionReason,
          equals(ProgressionReason.rangeToppedOut));
      expect(completedSet.progressionAlgorithmVersion,
          equals(DoubleProgressionEngine.algorithmVersion));
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
        reps: 8,
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
