// lib/features/exercise_catalog/domain/exercise_metrics.dart
import '../../workout/domain/classification/exercise_log_mask.dart';
import 'models/exercise.dart';

/// A line the exercise history chart can draw.
enum ExerciseMetric { maxWeight, volume, est1rm, distance, duration, pace }

/// Which metrics an exercise can honestly be charted on, best first.
///
/// The chart used to offer two fixed sets — three cardio metrics or three
/// strength ones — chosen by the same `isCardio` flag the log rows were freed
/// from. It produced a plank whose only options were max weight, volume and
/// e1RM, and a Copenhagen adduction that opened on "max weight" and drew a
/// flat line at zero forever, because the number it charts is *added* weight
/// and there never is any.
///
/// The first entry is what the screen opens on, so the order is the answer to
/// "what does progress look like here".
List<ExerciseMetric> exerciseMetricsFor(Exercise exercise) {
  final mask = ExerciseLogMask.forExercise(exercise);

  if (mask.logsDistance) {
    return [
      ExerciseMetric.distance,
      if (mask.logsDuration) ...[
        ExerciseMetric.duration,
        ExerciseMetric.pace,
      ],
    ];
  }

  if (!mask.logsReps) {
    // A plank, a dead hang, a timed carry. Duration is the whole story; a
    // loaded one can also be charted on the weight it was held with.
    return [
      ExerciseMetric.duration,
      if (mask.showsPrimary && mask.weightMeansResistance)
        ExerciseMetric.maxWeight,
    ];
  }

  return [
    // Volume and e1RM are computed from the effective load, so they say
    // something on every rep-based exercise — body weight and assisted
    // included. Max weight only says something where the logged number is
    // resistance and there is one to log.
    if (mask.primary == LogField.weight) ExerciseMetric.maxWeight,
    if (mask.primary == LogField.addedWeight && exercise.supportsAddedWeight)
      ExerciseMetric.maxWeight,
    ExerciseMetric.volume,
    ExerciseMetric.est1rm,
  ];
}
