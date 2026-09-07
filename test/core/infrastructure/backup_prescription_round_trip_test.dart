import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/infrastructure/backup_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart'
    hide Routine, RoutineExercise, SetLog, WorkoutLog;
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/domain/models/routine.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart'
    as model;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase sourceDb;
  late AppDatabase targetDb;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sourceDb = AppDatabase(NativeDatabase.memory());
    targetDb = AppDatabase(NativeDatabase.memory());
    tempDir =
        await Directory.systemTemp.createTemp('backup_prescription_test_');
  });

  tearDown(() async {
    await sourceDb.close();
    await targetDb.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
      'Backup round-trip preserves AppSettings autonomy levels and SetLogs prescription fields',
      () async {
    // 1. Setup Source Data: AppSettings
    final profile = await sourceDb.into(sourceDb.profiles).insertReturning(
          ProfilesCompanion.insert(
            id: const drift.Value('profile-123'),
            visibility: const drift.Value('private'),
          ),
        );

    await sourceDb.into(sourceDb.appSettings).insert(
          AppSettingsCompanion.insert(
            userId: profile.id,
            trainingAutonomyLevel: const drift.Value('suggest'),
            nutritionAutonomyLevel: const drift.Value('automatic'),
            experienceLevel: const drift.Value('advanced'),
          ),
        );

    // 2. Setup Source Data: Exercises, Routines, WorkoutLogs, SetLogs
    final workoutDbSource = WorkoutLocalDataSource.forTesting(sourceDb);
    final productDbSource = ProductLocalDataSource.forTesting(sourceDb);
    final dbHelperSource = DatabaseHelper.forTesting(sourceDb);

    final benchEx = await workoutDbSource.insertExercise(
      model.Exercise(
        uuid: 'ex-bench-uuid',
        categoryName: 'Strength',
        texts: {
          'en': model.ExerciseText(name: 'Bench Press', description: ''),
        },
        primaryMuscles: const ['chest'],
        secondaryMuscles: const [],
      ),
    );

    final setLog = SetLog(
      workoutLogId: 1,
      exerciseId: benchEx.uuid,
      exerciseName: 'Bench Press',
      setType: 'normal',
      weightKg: 85.0,
      reps: 10,
      isCompleted: true,
      prescriptionOrigin: 'routine',
      prescribedRepMin: 8,
      prescribedRepMax: 12,
      prescribedWeight: 80.0,
      prescribedRir: 2,
      prescriptionOverridden: true,
      valuesAutoFilled: false,
      substitutedForExerciseId: 'ex-dumbbell-bench',
      progressionReason: 'Gradual overload +2.5kg',
      progressionAlgorithmVersion: 'v1.4',
    );

    final workoutLog = WorkoutLog(
      startTime: DateTime.now().subtract(const Duration(hours: 1)),
      endTime: DateTime.now(),
      routineName: 'Push Routine',
      sets: [setLog],
    );

    final routineTemplate = SetTemplate(
      id: 1,
      setType: 'normal',
      targetReps: '8-12',
      targetWeight: 80.0,
      targetRir: 2,
      targetRepMin: 8,
      targetRepMax: 12,
    );

    final routine = Routine(
      id: 1,
      name: 'Push Routine',
      exercises: [
        RoutineExercise(
          id: 1,
          exercise: benchEx,
          setTemplates: [routineTemplate],
          pauseSeconds: 90,
        ),
      ],
    );

    await workoutDbSource.importWorkoutData(
      routines: [routine],
      workoutLogs: [workoutLog],
    );

    // 3. Export backup payload from Source DB
    final backupManagerSource = BackupManager(
      userDb: dbHelperSource,
      workoutDb: workoutDbSource,
      productDb: productDbSource,
    );

    final payload = await backupManagerSource.generateBackupPayloadForTesting();
    expect(payload, isNotNull);

    // 4. Import backup into Target DB
    final workoutDbTarget = WorkoutLocalDataSource.forTesting(targetDb);
    final productDbTarget = ProductLocalDataSource.forTesting(targetDb);
    final dbHelperTarget = DatabaseHelper.forTesting(targetDb);
    DatabaseHelper.setDriftDb(targetDb);

    final backupManagerTarget = BackupManager(
      userDb: dbHelperTarget,
      workoutDb: workoutDbTarget,
      productDb: productDbTarget,
    );

    final imported =
        await backupManagerTarget.importBackupPayloadForTesting(payload);
    expect(imported, isTrue);

    // 5. Verify AppSettings in Target DB
    final targetSettings = await (targetDb.select(targetDb.appSettings)
          ..where((t) => t.userId.equals('profile-123')))
        .getSingleOrNull();

    expect(targetSettings, isNotNull);
    expect(targetSettings!.trainingAutonomyLevel, equals('suggest'));
    expect(targetSettings.nutritionAutonomyLevel, equals('automatic'));
    expect(targetSettings.experienceLevel, equals('advanced'));

    // 6. Verify SetLogs and RoutineSetTemplates in Target DB
    final targetSets = await targetDb.select(targetDb.setLogs).get();
    expect(targetSets.isNotEmpty, isTrue);
    final restoredSet = targetSets.first;
    expect(restoredSet.prescriptionOrigin, equals('routine'));
    expect(restoredSet.prescribedRepMin, equals(8));
    expect(restoredSet.prescribedRepMax, equals(12));
    expect(restoredSet.prescribedWeight, equals(80.0));
    expect(restoredSet.prescribedRir, equals(2));
    expect(restoredSet.prescriptionOverridden, isTrue);
    expect(restoredSet.valuesAutoFilled, isFalse);
    expect(restoredSet.substitutedForExerciseId, equals('ex-dumbbell-bench'));
    expect(restoredSet.progressionReason, equals('Gradual overload +2.5kg'));
    expect(restoredSet.progressionAlgorithmVersion, equals('v1.4'));

    final targetTemplates =
        await targetDb.select(targetDb.routineSetTemplates).get();
    expect(targetTemplates.isNotEmpty, isTrue);
    final restoredTemplate = targetTemplates.first;
    expect(restoredTemplate.targetRepMin, equals(8));
    expect(restoredTemplate.targetRepMax, equals(12));
  });
}
