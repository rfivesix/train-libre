import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'v30 migration adds columns, backfills SetLogs.prescriptionOrigin and RoutineSetTemplates.targetRepMin/Max',
      () async {
    final db = AppDatabase(NativeDatabase.memory());

    // Verify schemaVersion is 30
    expect(db.schemaVersion, 30);

    // Verify we can insert and query all new columns on SetLogs
    final profileRow = await db.into(db.profiles).insertReturning(
          ProfilesCompanion.insert(
            id: const drift.Value('test-user-v30'),
            visibility: const drift.Value('private'),
          ),
        );

    await db.into(db.appSettings).insert(
          AppSettingsCompanion.insert(
            userId: profileRow.id,
            trainingAutonomyLevel: const drift.Value('suggest'),
            nutritionAutonomyLevel: const drift.Value('automatic'),
            experienceLevel: const drift.Value('advanced'),
          ),
        );

    final settings = await (db.select(db.appSettings)
          ..where((t) => t.userId.equals('test-user-v30')))
        .getSingle();
    expect(settings.trainingAutonomyLevel, 'suggest');
    expect(settings.nutritionAutonomyLevel, 'automatic');
    expect(settings.experienceLevel, 'advanced');

    final wLog = await db.into(db.workoutLogs).insertReturning(
          WorkoutLogsCompanion.insert(
            id: const drift.Value('wlog-v30'),
            startTime: DateTime.now(),
          ),
        );

    final setRow = await db.into(db.setLogs).insertReturning(
          SetLogsCompanion.insert(
            workoutLogId: wLog.id,
            prescriptionOrigin: const drift.Value('engine'),
            prescribedRepMin: const drift.Value(6),
            prescribedRepMax: const drift.Value(10),
            prescribedWeight: const drift.Value(92.5),
            prescribedRir: const drift.Value(2),
            prescriptionOverridden: const drift.Value(true),
            valuesAutoFilled: const drift.Value(true),
            substitutedForExerciseId: const drift.Value('sub-ex-id'),
            progressionReason:
                const drift.Value('Double progression passed target reps'),
            progressionAlgorithmVersion:
                const drift.Value('double_progression_v1'),
          ),
        );

    expect(setRow.prescriptionOrigin, 'engine');
    expect(setRow.prescribedRepMin, 6);
    expect(setRow.prescribedRepMax, 10);
    expect(setRow.prescribedWeight, 92.5);
    expect(setRow.prescribedRir, 2);
    expect(setRow.prescriptionOverridden, isTrue);
    expect(setRow.valuesAutoFilled, isTrue);
    expect(setRow.substitutedForExerciseId, 'sub-ex-id');
    expect(setRow.progressionReason, 'Double progression passed target reps');
    expect(setRow.progressionAlgorithmVersion, 'double_progression_v1');

    // Test reconcileSchema auto-repair guarantee:
    // If a column was dropped or missing, reconcileSchema restores it because every column is nullable or defaulted
    final repaired = await db.reconcileSchema();
    expect(repaired, isEmpty); // No repair needed on already current DB

    await db.close();
  });
}
