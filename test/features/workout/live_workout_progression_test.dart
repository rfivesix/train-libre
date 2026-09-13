import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart' show AppDatabase;
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart'
    as model;
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/prescription_enums.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/domain/services/workout_progression_service.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';
import 'package:train_libre/services/training_autonomy_service.dart';
import 'package:train_libre/services/unit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late WorkoutLocalDataSource dataSource;
  late WorkoutRepository repository;
  late UnitService unitService;
  late TrainingAutonomyService autonomy;
  late LiveWorkoutViewModel viewModel;

  model.Exercise exercise({String uuid = 'bench'}) => model.Exercise.single(
        uuid: uuid,
        languageCode: 'en',
        name: uuid == 'squat' ? 'Squat' : 'Bench Press',
        categoryName: 'Strength',
        primaryMuscles: const ['Chest'],
        secondaryMuscles: const [],
        trackingType: 'weight_reps',
        loadMode: 'external',
        primaryEquipment: 'barbell',
      );

  RoutineExercise routine({
    required int id,
    required model.Exercise exercise,
    required List<SetTemplate> templates,
  }) =>
      RoutineExercise(
        id: id,
        exercise: exercise,
        pauseSeconds: 60,
        setTemplates: templates,
      );

  List<SetTemplate> rangedTemplates([int firstId = 101]) => [
        SetTemplate(
          id: firstId,
          setType: 'normal',
          targetRepMin: 8,
          targetRepMax: 12,
        ),
        SetTemplate(
          id: firstId + 1,
          setType: 'normal',
          targetRepMin: 8,
          targetRepMax: 12,
        ),
        SetTemplate(
          id: firstId + 2,
          setType: 'normal',
          targetRepMin: 8,
          targetRepMax: 12,
        ),
      ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'unit_system': 'metric',
      'training_autonomy_level': 'suggest',
    });
    database = AppDatabase(NativeDatabase.memory());
    dataSource = WorkoutLocalDataSource.forTesting(database);
    repository = WorkoutRepository(localDataSource: dataSource);
    unitService = UnitService();
    await unitService.setUnitSystem(UnitSystem.metric);
    autonomy = TrainingAutonomyService(database);
    await autonomy.initialize();
    await autonomy.setLevel(AutonomyLevel.suggest);
    viewModel = LiveWorkoutViewModel.forTesting(
      workoutDb: repository,
      unitService: unitService,
      progressionService: WorkoutProgressionService(
        repository: repository,
        unitService: unitService,
      ),
      trainingAutonomyService: autonomy,
    );
  });

  tearDown(() async {
    await viewModel.pendingProgressionUpdate;
    viewModel.dispose();
    await database.close();
  });

  Future<void> seedPreviousFirstSet({
    required model.Exercise exercise,
    required double weight,
    required int reps,
  }) async {
    final previous = await dataSource.startWorkout(routineName: 'Previous');
    await dataSource.insertSetLog(SetLog(
      workoutLogId: previous.id!,
      exerciseId: exercise.uuid,
      exerciseName: exercise.canonicalName,
      setType: 'normal',
      weightKg: weight,
      reps: reps,
      isCompleted: true,
      logOrder: 0,
    ));
    // A deliberately different later set proves that only the first working
    // set of the prior workout influences the next first-set suggestion.
    await dataSource.insertSetLog(SetLog(
      workoutLogId: previous.id!,
      exerciseId: exercise.uuid,
      exerciseName: exercise.canonicalName,
      setType: 'normal',
      weightKg: weight - 10,
      reps: 8,
      isCompleted: true,
      logOrder: 1,
    ));
    await dataSource.finishWorkout(previous.id!);
  }

  test('pre-fills only the first working set from first-set history', () async {
    final bench = exercise();
    await seedPreviousFirstSet(exercise: bench, weight: 60, reps: 10);
    final workout = await dataSource.startWorkout(routineName: 'Push');

    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: bench, templates: rangedTemplates())],
    );

    expect(viewModel.setLogs[101]!.weightKg, 60);
    expect(viewModel.setLogs[101]!.reps, 11);
    expect(viewModel.isSetSuggested(101), isTrue);
    expect(viewModel.setLogs[102]!.weightKg, isNull);
    expect(viewModel.setLogs[102]!.reps, isNull);

    await viewModel.updateSet(101, isCompleted: true);
    expect(viewModel.setLogs[101]!.valuesAutoFilled, isFalse);
  });

  test('later sets are prescribed one at a time from real prior performance',
      () async {
    final bench = exercise();
    await seedPreviousFirstSet(exercise: bench, weight: 60, reps: 10);
    final workout = await dataSource.startWorkout(routineName: 'Push');
    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: bench, templates: rangedTemplates())],
    );

    await viewModel.updateSet(101, weight: 60, reps: 10, isCompleted: true);
    await viewModel.pendingProgressionUpdate;

    // The first result only fills the directly following row. At 60 x 10,
    // the projected straight-set result is 60 kg x 8.
    expect(viewModel.setLogs[102]!.weightKg, 60);
    expect(viewModel.setLogs[102]!.reps, 8);
    expect(viewModel.setLogs[103]!.weightKg, isNull);

    await viewModel.updateSet(102, weight: 60, reps: 8, isCompleted: true);
    await viewModel.pendingProgressionUpdate;
    expect(viewModel.setLogs[103]!.weightKg, 55);
    expect(viewModel.setLogs[103]!.reps, 8);
  });

  test('preserves a routine back-off as a ratio of the real top set', () async {
    final bench = exercise();
    final workout = await dataSource.startWorkout(routineName: 'Back-off');
    final templates = [
      SetTemplate(
        id: 101,
        setType: 'normal',
        targetWeight: 100,
        targetRepMin: 8,
        targetRepMax: 12,
      ),
      SetTemplate(
        id: 102,
        setType: 'normal',
        targetWeight: 80,
        targetRepMin: 8,
        targetRepMax: 12,
      ),
    ];
    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: bench, templates: templates)],
    );

    await viewModel.updateSet(101, weight: 120, reps: 7, isCompleted: true);
    await viewModel.pendingProgressionUpdate;

    // The authored 80% relationship becomes 96 kg at today's 120 kg top
    // set, then rounds to the available 95 kg increment before projection.
    expect(viewModel.setLogs[102]!.weightKg, 95);
    expect(viewModel.setLogs[102]!.reps, 12);
  });

  test('RIR refines subsequent working-set back-offs', () async {
    final bench = exercise();
    final workout = await dataSource.startWorkout(routineName: 'Push');
    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: bench, templates: rangedTemplates())],
    );

    await viewModel.updateSet(
      101,
      weight: 60,
      reps: 10,
      rir: 2,
      isCompleted: true,
    );
    await viewModel.pendingProgressionUpdate;
    expect(viewModel.setLogs[102]!.weightKg, 60);
    expect(viewModel.setLogs[102]!.reps, 11);

    await viewModel.updateSet(
      102,
      weight: 60,
      reps: 11,
      rir: 0,
      isCompleted: true,
    );
    await viewModel.pendingProgressionUpdate;
    expect(viewModel.setLogs[103]!.weightKg, 60);
    expect(viewModel.setLogs[103]!.reps, 9);
  });

  test('a fixed repetition target still receives a calculated weight',
      () async {
    final bench = exercise();
    await seedPreviousFirstSet(exercise: bench, weight: 60, reps: 10);
    final workout = await dataSource.startWorkout(routineName: 'Strength');
    final fixed = [
      SetTemplate(id: 101, setType: 'normal', targetReps: '8'),
      SetTemplate(id: 102, setType: 'normal', targetReps: '8'),
    ];

    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: bench, templates: fixed)],
    );

    expect(viewModel.setLogs[101]!.weightKg, 62.5);
    expect(viewModel.setLogs[101]!.reps, 8);
  });

  test('a manually entered open set survives restoration and late suggestions',
      () async {
    final bench = exercise();
    await seedPreviousFirstSet(exercise: bench, weight: 60, reps: 10);
    final workout = await dataSource.startWorkout(routineName: 'Push');
    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: bench, templates: rangedTemplates())],
    );

    await viewModel.updateSet(101, weight: 60, reps: 10, isCompleted: true);
    await viewModel.pendingProgressionUpdate;
    await viewModel.updateSet(102, weight: 55, reps: 8);
    viewModel.dispose();

    viewModel = LiveWorkoutViewModel.forTesting(
      workoutDb: repository,
      unitService: unitService,
      progressionService: WorkoutProgressionService(
        repository: repository,
        unitService: unitService,
      ),
      trainingAutonomyService: autonomy,
    );
    await viewModel.restoreWorkoutSession(workout);

    final restoredManual = viewModel.setLogs.entries.singleWhere(
      (entry) => entry.value.weightKg == 55 && entry.value.reps == 8,
    );
    expect(restoredManual.value.valuesAutoFilled, isFalse);
    expect(viewModel.isSetSuggested(restoredManual.key), isFalse);
  });

  test('finishing keeps completed and manually entered sets across exercises',
      () async {
    final bench = exercise();
    final squat = exercise(uuid: 'squat');
    final workout = await dataSource.startWorkout(routineName: 'Real workout');
    await viewModel.loadInitialData(workout, [
      routine(id: 1, exercise: bench, templates: rangedTemplates(101)),
      routine(id: 2, exercise: squat, templates: rangedTemplates(201)),
    ]);

    await viewModel.updateSet(101, weight: 60, reps: 10, isCompleted: true);
    await viewModel.updateSet(102, weight: 55, reps: 8);
    await viewModel.updateSet(201, weight: 100, reps: 8, isCompleted: true);
    await viewModel.finishWorkout();

    final saved = await repository.getSetLogsForWorkout(workout.id!);
    expect(saved, hasLength(3));
    expect(saved.where((set) => set.weightKg == 60 && set.reps == 10),
        hasLength(1));
    expect(saved.where((set) => set.weightKg == 55 && set.reps == 8),
        hasLength(1));
    expect(saved.where((set) => set.weightKg == 100 && set.reps == 8),
        hasLength(1));
  });

  test('atomic finalization rolls back rather than partially saving a workout',
      () async {
    final workout = await dataSource.startWorkout(routineName: 'Atomic');
    final original = SetLog(
      workoutLogId: workout.id!,
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      setType: 'normal',
      weightKg: 50,
      reps: 10,
      isCompleted: true,
      logOrder: 0,
    );
    final originalId = await dataSource.insertSetLog(original);

    await expectLater(
      dataSource.finalizeWorkout(
        workoutLogId: workout.id!,
        sets: [
          original.copyWith(id: originalId, weightKg: 60),
          original.copyWith(id: 999999, weightKg: 70, logOrder: 1),
        ],
        discardSetIds: const [],
      ),
      throwsA(isA<StateError>()),
    );

    final saved = await dataSource.getSetLogsForWorkout(workout.id!);
    expect(saved, hasLength(1));
    expect(saved.single.weightKg, 50);
    expect(await dataSource.getOngoingWorkout(), isNotNull);
  });

  test('discarding clears the deleted workout from memory and storage',
      () async {
    final workout = await dataSource.startWorkout(routineName: 'Discard');
    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: exercise(), templates: rangedTemplates())],
    );

    await dataSource.deleteWorkoutLog(workout.id!);
    await viewModel.clearLocalSessionState();

    expect(await dataSource.getOngoingWorkout(), isNull);
    expect(viewModel.isActive, isFalse);
    expect(viewModel.workoutLog, isNull);
  });

  test('marking a live set as failure immediately shows RIR zero', () async {
    final workout = await dataSource.startWorkout(routineName: 'Failure');
    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: exercise(), templates: rangedTemplates())],
    );

    await viewModel.updateSet(101, setType: 'failure');

    expect(viewModel.setLogs[101]!.rir, 0);
    expect(viewModel.rirControllers[101]!.text, '0');
  });

  test('finishing removes untouched empty set rows from workout history',
      () async {
    final workout = await dataSource.startWorkout(routineName: 'Empty rows');
    await viewModel.loadInitialData(
      workout,
      [routine(id: 1, exercise: exercise(), templates: rangedTemplates())],
    );

    await viewModel.finishWorkout();

    expect(await repository.getSetLogsForWorkout(workout.id!), isEmpty);
  });
}
