import 'package:flutter/foundation.dart';

import '../../../exercise_catalog/domain/models/exercise.dart';

/// What a single input column of a set row collects.
enum LogField {
  /// Resistance, in the user's weight unit.
  weight,

  /// Extra load on top of body weight — a belt, a vest, a dumbbell between the
  /// feet. Empty means "just me", not zero.
  addedWeight,

  /// A reduction of resistance, on an assistance machine. Bigger is easier.
  assistance,

  reps,
  duration,
  distance,

  /// The column is not shown.
  none,
}

/// Which two inputs a set row shows, and what they mean.
///
/// The set rows have always had exactly two input columns and a single
/// `isCardio` boolean deciding what both of them were. That worked while the
/// catalog only distinguished "cardio" from "not cardio". It cannot express a
/// plank (a duration and nothing else), a pull-up (reps plus optional added
/// weight) or an assisted dip (reps minus assistance), which is what
/// `tracking_type` and `load_mode` are for.
@immutable
class ExerciseLogMask {
  /// The left input column: weight, added weight, assistance, or distance.
  final LogField primary;

  /// The right input column: reps or duration.
  final LogField secondary;

  const ExerciseLogMask({required this.primary, required this.secondary});

  /// The shape everything used before `tracking_type` existed.
  static const ExerciseLogMask weightAndReps =
      ExerciseLogMask(primary: LogField.weight, secondary: LogField.reps);

  static const ExerciseLogMask distanceAndDuration = ExerciseLogMask(
    primary: LogField.distance,
    secondary: LogField.duration,
  );

  factory ExerciseLogMask.forExercise(Exercise? exercise) {
    switch (exercise?.trackingType) {
      case 'weight_reps':
        // An assistance machine logs a number that means the opposite of
        // load, and the column has to say so.
        return ExerciseLogMask(
          primary: exercise!.weightMeansResistance
              ? LogField.weight
              : LogField.assistance,
          secondary: LogField.reps,
        );
      case 'bodyweight_reps':
        return ExerciseLogMask(
          primary: exercise!.weightMeansResistance
              ? LogField.addedWeight
              : LogField.assistance,
          secondary: LogField.reps,
        );
      case 'time':
        return const ExerciseLogMask(
          primary: LogField.none,
          secondary: LogField.duration,
        );
      case 'time_weight':
        return const ExerciseLogMask(
          primary: LogField.weight,
          secondary: LogField.duration,
        );
      case 'distance_time':
        return distanceAndDuration;
      case 'distance_only':
        return const ExerciseLogMask(
          primary: LogField.distance,
          secondary: LogField.none,
        );
    }

    // No classification: pre-v2 rows and user-created exercises, where the
    // category is still the only signal there is.
    return (exercise?.isCardio ?? false) ? distanceAndDuration : weightAndReps;
  }

  bool get showsPrimary => primary != LogField.none;
  bool get showsSecondary => secondary != LogField.none;

  bool get logsWeight =>
      primary == LogField.weight ||
      primary == LogField.addedWeight ||
      primary == LogField.assistance;
  bool get logsDistance => primary == LogField.distance;
  bool get logsReps => secondary == LogField.reps;
  bool get logsDuration => secondary == LogField.duration;

  /// Whether the duration column opens a picker rather than a keyboard, and
  /// whether the distance column is a distance. Both were `isCardio` before.
  bool get usesDurationPicker => logsDuration;

  @override
  bool operator ==(Object other) =>
      other is ExerciseLogMask &&
      other.primary == primary &&
      other.secondary == secondary;

  @override
  int get hashCode => Object.hash(primary, secondary);

  @override
  String toString() => 'ExerciseLogMask($primary, $secondary)';
}
