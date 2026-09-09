// lib/features/workout/domain/repositories/workout_repository.dart
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../models/routine.dart';
import '../models/set_log.dart';
import '../models/workout_log.dart';
import '../classification/set_load.dart';

/// Abstract contract for Workout data persistence and operations.
abstract class IWorkoutRepository {
  /// The user's recorded body weight over time.
  ///
  /// Needed wherever a set's worth depends on it: a pull-up lifts the user,
  /// and an assistance machine subtracts from them.
  Future<BodyweightHistory> getBodyweightHistory();

  Future<WorkoutLog?> getOngoingWorkout();
  Future<int> insertSetLog(SetLog log);
  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId);
  Stream<List<SetLog>> watchSetLogsForWorkout(int workoutLogId);
  Future<Routine?> getRoutineByName(String name);
  Future<Exercise?> resolveExerciseForSetLog(SetLog log);
  Future<Exercise?> getExerciseByName(String name);
  Future<String?> getExerciseUuidByLocalId(int localId);
  Future<Map<String, double>> getExerciseBests(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  });
  Future<void> updateSetLogs(List<SetLog> logs);
  Future<void> deleteSetLogs(List<int> ids);
  Future<void> finishWorkout(int logId, {String? title, String? notes});
  Future<void> updatePauseTime(int routineExerciseId, int? seconds);
  Future<void> updateRoutineExerciseNotes(int routineExerciseId, String? notes);
  Future<void> saveWorkoutExerciseNote({
    required int workoutLogId,
    required String exerciseName,
    required String? notes,
  });
  Future<Map<String, String>> getWorkoutExerciseNotes(int workoutLogId);
  Future<List<SetLog>> getLastSetsForExercise({
    required String? exerciseId,
    required String exerciseNameSnapshot,
  });
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
      DateTime start, DateTime end);
  Stream<List<WorkoutLog>> watchFullWorkoutLogs();
  Stream<List<Routine>> watchAllRoutines();
  Stream<List<WorkoutLog>> watchWorkoutLogsForDateRange(
      DateTime start, DateTime end);
  Future<Routine?> getRoutineByUuid(String uuid);
  Future<void> syncRoutineWithWorkout({
    required String routineUuid,
    required int workoutLogId,
  });
  Future<Routine> createRoutineFromWorkout({
    required int workoutLogId,
    required String name,
  });
  Future<void> updateWorkoutLogPhotos(int logId, List<String> paths);
}

/// Optional capability used by the live-workout screen when it commits a
/// session. Keeping it separate from [IWorkoutRepository] avoids forcing
/// unrelated read-only test doubles to implement a write-heavy transaction.
abstract interface class WorkoutFinalizationRepository {
  /// Persists the final set snapshot and marks the workout completed as one
  /// transaction. A failure leaves the ongoing workout untouched so it can be
  /// recovered instead of silently losing rows.
  Future<List<SetLog>> finalizeWorkout({
    required int workoutLogId,
    required List<SetLog> sets,
    required List<int> discardSetIds,
    String? title,
    String? notes,
  });
}

/// Full canonical history for multi-session progression evidence.
abstract interface class ProgressionHistoryRepository {
  Future<List<SetLog>> getProgressionHistory({
    required String exerciseId,
    required String exerciseNameSnapshot,
  });
}

abstract interface class ProgressionPrescriptionRepository {
  Future<void> saveProgressionConfig(String prescriptionKey, String data,
      {bool equipmentOnly = false});
  Future<void> initializeProgressionConfig(int routineExerciseId, String data);
}
