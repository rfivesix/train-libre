import 'models/routine_exercise.dart';
import 'models/set_log.dart';

/// Identifies the next set in the order a workout is performed.
class WorkoutNextSet {
  final int exerciseIndex;
  final int templateIndex;
  final int templateId;

  const WorkoutNextSet({
    required this.exerciseIndex,
    required this.templateIndex,
    required this.templateId,
  });
}

/// Returns the first unfinished set in workout order.
///
/// Exercises in a superset are performed round by round: A1, B1, C1, A2,
/// B2, C2. Members with fewer sets are simply absent from later rounds.
WorkoutNextSet? findNextWorkoutSet(
  List<RoutineExercise> exercises,
  Map<int, SetLog> setLogs,
) {
  var exerciseIndex = 0;
  while (exerciseIndex < exercises.length) {
    final exercise = exercises[exerciseIndex];
    final group = exercise.supersetGroup;
    if (group == null) {
      for (var templateIndex = 0;
          templateIndex < exercise.setTemplates.length;
          templateIndex++) {
        final id = exercise.setTemplates[templateIndex].id;
        if (id != null && setLogs[id]?.isCompleted != true) {
          return WorkoutNextSet(
            exerciseIndex: exerciseIndex,
            templateIndex: templateIndex,
            templateId: id,
          );
        }
      }
      exerciseIndex++;
      continue;
    }

    var groupEnd = exerciseIndex;
    var rounds = 0;
    while (groupEnd < exercises.length &&
        exercises[groupEnd].supersetGroup == group) {
      rounds = rounds > exercises[groupEnd].setTemplates.length
          ? rounds
          : exercises[groupEnd].setTemplates.length;
      groupEnd++;
    }
    for (var round = 0; round < rounds; round++) {
      for (var member = exerciseIndex; member < groupEnd; member++) {
        final templates = exercises[member].setTemplates;
        if (round >= templates.length) continue;
        final id = templates[round].id;
        if (id != null && setLogs[id]?.isCompleted != true) {
          return WorkoutNextSet(
            exerciseIndex: member,
            templateIndex: round,
            templateId: id,
          );
        }
      }
    }
    exerciseIndex = groupEnd;
  }
  return null;
}
