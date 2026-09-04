import 'package:flutter/foundation.dart';

import '../../../exercise_catalog/domain/models/exercise.dart';
import 'set_load.dart';

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

  /// Carried so the mask can answer what a logged number is *worth*, not only
  /// which box it goes in. Both are null for pre-v2 rows and user-created
  /// exercises.
  final String? trackingType;
  final String? loadMode;

  /// `compound` | `isolation`, when the catalog has an opinion.
  ///
  /// Not part of the mask's shape — it changes no input column — but carried
  /// here because this is already the channel by which a set row learns what
  /// the catalog says about its exercise, and adding a second one would mean
  /// two places that can disagree.
  final String? mechanic;

  const ExerciseLogMask({
    required this.primary,
    required this.secondary,
    this.trackingType,
    this.loadMode,
    this.mechanic,
  });

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
          trackingType: exercise.trackingType,
          loadMode: exercise.loadMode,
          mechanic: exercise.mechanic,
        );
      case 'bodyweight_reps':
        return ExerciseLogMask(
          primary: exercise!.weightMeansResistance
              ? LogField.addedWeight
              : LogField.assistance,
          secondary: LogField.reps,
          trackingType: exercise.trackingType,
          loadMode: exercise.loadMode,
          mechanic: exercise.mechanic,
        );
      case 'time':
        return ExerciseLogMask(
          primary: LogField.none,
          secondary: LogField.duration,
          trackingType: exercise!.trackingType,
          loadMode: exercise.loadMode,
          mechanic: exercise.mechanic,
        );
      case 'time_weight':
        return ExerciseLogMask(
          primary: LogField.weight,
          secondary: LogField.duration,
          trackingType: exercise!.trackingType,
          loadMode: exercise.loadMode,
          mechanic: exercise.mechanic,
        );
      case 'distance_time':
        return ExerciseLogMask(
          primary: LogField.distance,
          secondary: LogField.duration,
          trackingType: exercise!.trackingType,
          loadMode: exercise.loadMode,
          mechanic: exercise.mechanic,
        );
      case 'distance_only':
        return ExerciseLogMask(
          primary: LogField.distance,
          secondary: LogField.none,
          trackingType: exercise!.trackingType,
          loadMode: exercise.loadMode,
          mechanic: exercise.mechanic,
        );
    }

    // No classification: pre-v2 rows and user-created exercises, where the
    // category is still the only signal there is.
    return (exercise?.isCardio ?? false) ? distanceAndDuration : weightAndReps;
  }

  /// What a logged number was actually worth, in kilograms.
  ///
  /// Delegates rather than reimplementing: the sign error this guards against
  /// is exactly the kind that a second copy of the rule reintroduces.
  double? effectiveLoadKg(double? loggedWeightKg, double? bodyweightKg) =>
      effectiveSetLoadKg(
        trackingType: trackingType,
        loadMode: loadMode,
        loggedWeightKg: loggedWeightKg,
        bodyweightKg: bodyweightKg,
      );

  /// Whether a bigger logged number means a harder set.
  ///
  /// False on an assistance machine, where it means the opposite: a record for
  /// "most kilos" there would celebrate the easiest set of the session.
  bool get weightMeansResistance => loadMode != 'assisted';

  /// Estimated one-rep max, or null when there is nothing honest to show.
  double? estimatedOneRepMax({
    required double? loggedWeightKg,
    required int? reps,
    required double? bodyweightKg,
  }) =>
      estimatedOneRepMaxKg(
        trackingType: trackingType,
        loadMode: loadMode,
        loggedWeightKg: loggedWeightKg,
        reps: reps,
        bodyweightKg: bodyweightKg,
      );

  bool get showsPrimary => primary != LogField.none;
  bool get showsSecondary => secondary != LogField.none;

  /// Whether the third column — RIR, or intensity on a cardio row — is worth
  /// offering.
  ///
  /// RIR is *reps in reserve*, so it needs reps to be in reserve of. A plank
  /// has none, and the column sat there over a duration picker inviting a
  /// number that could not mean anything. Cardio keeps it because the same
  /// column is labelled intensity there, which a run does have.
  bool get showsIntensity => logsReps || logsDistance;

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
      other.secondary == secondary &&
      other.trackingType == trackingType &&
      other.loadMode == loadMode;

  @override
  int get hashCode => Object.hash(primary, secondary, trackingType, loadMode);

  @override
  String toString() => 'ExerciseLogMask($primary, $secondary)';
}
