import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart' show AppDatabase;
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart'
    as model;
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';
import 'package:train_libre/features/workout/domain/log_workout_set_use_case.dart';
import 'package:train_libre/features/workout/domain/models/prescription_enums.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late WorkoutLocalDataSource workoutDb;
  late LiveWorkoutViewModel manager;

  LiveWorkoutViewModel buildManager() => LiveWorkoutViewModel.forTesting(
        workoutDb: WorkoutRepository(
          localDataSource: WorkoutLocalDataSource(database),
        ),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    workoutDb = WorkoutLocalDataSource.forTesting(database);
    manager = buildManager();
  });

  tearDown(() async {
    manager.dispose();
    await database.close();
  });

  model.Exercise exerciseNamed(String name, int id) => model.Exercise(
        id: id,
        uuid: 'uuid-ex-$id',
        texts: {
          'de': model.ExerciseText(name: name, description: ''),
          'en': model.ExerciseText(name: name, description: ''),
        },
        categoryName: 'Strength',
        primaryMuscles: const ['chest'],
        secondaryMuscles: const [],
      );

  test(
      'Routine workout copies prescription as snapshot and remains immutable on template change',
      () async {
    // 1. Create a routine in the database
    final routine = await workoutDb.createRoutine('Hypertrophy Day');
    final template = SetTemplate(
      id: 555,
      setType: 'normal',
      targetReps: '8-12',
      targetWeight: 80.0,
      targetRir: 2,
    );

    // 2. Start live workout from this routine
    final startLog = await workoutDb.startWorkout(
      routineName: routine.name,
    );

    final reForSession = RoutineExercise(
      id: 100,
      exercise: exerciseNamed('Bench Press', 1),
      setTemplates: [template],
      pauseSeconds: 90,
    );

    await manager.startWorkout(startLog, [reForSession]);

    // Verify initial set log in manager
    final setLog = manager.setLogs[template.id!];
    expect(setLog, isNotNull);
    expect(setLog!.prescriptionOrigin, equals(PrescriptionOrigin.routine.name));
    expect(setLog.prescribedRepMin, equals(8));
    expect(setLog.prescribedRepMax, equals(12));
    expect(setLog.prescribedWeight, equals(80.0));
    expect(setLog.prescribedRir, equals(2));
    expect(setLog.prescriptionOverridden, isFalse);
    expect(setLog.valuesAutoFilled, isFalse);

    // 3. Mutate the routine template in database (simulating user editing routine later)
    await workoutDb.updateSetTemplate(template.copyWith(
      targetReps: '10-15',
      targetWeight: 100.0,
      targetRir: 1,
    ));

    // 4. Verify the logged set in DB still carries the original snapshot
    final setsInDb = await workoutDb.getSetLogsForWorkout(startLog.id!);
    expect(setsInDb.length, 1);
    final loggedSet = setsInDb.first;
    expect(loggedSet.prescriptionOrigin, equals('routine'));
    expect(loggedSet.prescribedRepMin, equals(8));
    expect(loggedSet.prescribedRepMax, equals(12));
    expect(loggedSet.prescribedWeight, equals(80.0));
    expect(loggedSet.prescribedRir, equals(2));
  });

  test(
      'Spontaneous set added during session gets origin none and null prescribed values',
      () async {
    final startLog = await workoutDb.startWorkout(routineName: 'Push A');
    final ex = exerciseNamed('Bench Press', 1);
    final re = RoutineExercise(
      id: 10,
      exercise: ex,
      pauseSeconds: 60,
      setTemplates: [
        SetTemplate(
            id: 101,
            setType: 'normal',
            targetReps: '8-12',
            targetWeight: 70.0,
            targetRir: 2),
      ],
    );

    await manager.startWorkout(startLog, [re]);

    // Add spontaneous set
    await manager.addSetToExercise(10);

    expect(manager.exercises.first.setTemplates.length, 2);
    final spontaneousTemplate = manager.exercises.first.setTemplates.last;
    final spontaneousSet = manager.setLogs[spontaneousTemplate.id!];

    expect(spontaneousSet, isNotNull);
    expect(spontaneousSet!.prescriptionOrigin,
        equals(PrescriptionOrigin.none.name));
    expect(spontaneousSet.prescribedRepMin, isNull);
    expect(spontaneousSet.prescribedRepMax, isNull);
    expect(spontaneousSet.prescribedWeight, isNull);
    expect(spontaneousSet.prescribedRir, isNull);
  });

  test('Workout without routine gets prescriptionOrigin none for all sets',
      () async {
    // Routine-less workout
    final startLog = await workoutDb.startWorkout(); // no routine
    final ex = exerciseNamed('Overhead Press', 2);
    final re = RoutineExercise(
      id: 20,
      exercise: ex,
      pauseSeconds: 60,
      setTemplates: [
        SetTemplate(
            id: 201, setType: 'normal', targetReps: '10', targetWeight: 50.0),
      ],
    );

    await manager.startWorkout(startLog, [re]);

    final setLog = manager.setLogs[201];
    expect(setLog, isNotNull);
    expect(setLog!.prescriptionOrigin, equals(PrescriptionOrigin.none.name));
    expect(setLog.prescribedRepMin, isNull);
    expect(setLog.prescribedRepMax, isNull);
    expect(setLog.prescribedWeight, isNull);
    expect(setLog.prescribedRir, isNull);
  });

  test('Warm-up set in routine receives prescription snapshot like normal sets',
      () async {
    final startLog = await workoutDb.startWorkout(routineName: 'Leg Day');
    final ex = exerciseNamed('Squat', 3);
    final warmupTemplate = SetTemplate(
      id: 301,
      setType: 'warmup',
      targetReps: '15',
      targetWeight: 20.0,
    );
    final re = RoutineExercise(
      id: 30,
      exercise: ex,
      pauseSeconds: 60,
      setTemplates: [warmupTemplate],
    );

    await manager.startWorkout(startLog, [re]);

    final setLog = manager.setLogs[301];
    expect(setLog, isNotNull);
    expect(setLog!.setType, equals('warmup'));
    expect(setLog.prescriptionOrigin, equals(PrescriptionOrigin.routine.name));
    expect(setLog.prescribedRepMin, equals(15));
    expect(setLog.prescribedRepMax, equals(15));
    expect(setLog.prescribedWeight, equals(20.0));
  });

  test(
      'valuesAutoFilled is true when completing empty set from template and false when user inputs values',
      () {
    final useCase = LogWorkoutSetUseCase();
    final template = SetTemplate(
      id: 500,
      setType: 'normal',
      targetReps: '8-12',
      targetWeight: 60.0,
    );

    final emptySet = SetLog(
      id: 1,
      workoutLogId: 1,
      exerciseName: 'Bench Press',
      setType: 'normal',
      weightKg: null,
      reps: null,
      isCompleted: false,
    );

    // Case 1: Auto-filled upon completing
    final autoFilledResult = useCase.execute(
      oldLog: emptySet,
      template: template,
      isCompleted: true,
    );
    expect(autoFilledResult.updatedSet.valuesAutoFilled, isTrue);
    expect(autoFilledResult.updatedSet.weightKg, equals(60.0));
    expect(autoFilledResult.updatedSet.reps, equals(10));

    // Case 2: User explicitly provided values
    final userFilledResult = useCase.execute(
      oldLog: emptySet,
      template: template,
      weight: 65.0,
      reps: 8,
      isCompleted: true,
    );
    expect(userFilledResult.updatedSet.valuesAutoFilled, isFalse);
    expect(userFilledResult.updatedSet.weightKg, equals(65.0));
    expect(userFilledResult.updatedSet.reps, equals(8));
  });
}
