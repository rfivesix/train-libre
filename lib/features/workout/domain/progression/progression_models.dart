import 'progression_contract.dart';
export 'progression_contract.dart';
import '../models/prescription_enums.dart';
import '../classification/workout_set_position.dart';

export '../models/prescription_enums.dart' show ProgressionOutcome, LoadMode;

/// Represents a repetition range target (e.g. 8-12 reps).
class RepRange {
  final int min;
  final int max;

  const RepRange(this.min, this.max) : assert(min <= max, 'min must be <= max');

  bool contains(int reps) => reps >= min && reps <= max;
  bool isToppedOut(int reps) => reps >= max;
  bool isBelowMin(int reps) => reps < min;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepRange &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => min.hashCode ^ max.hashCode;

  @override
  String toString() => '$min-$max';
}

/// The next explicit rep target for a held load. A range supplies a real
/// training target; without one the most honest continuation is the last
/// recorded number of reps.
int? nextSuggestedReps({
  required int? previousReps,
  required RepRange? range,
  bool loadRaised = false,
}) {
  if (range == null) return previousReps;
  if (loadRaised || previousReps == null || previousReps < range.min) {
    return range.min;
  }
  return previousReps >= range.max ? range.max : previousReps + 1;
}

/// Static table of smallest weight step increments per equipment type and unit.
class LoadIncrement {
  final double value;
  final String unit;

  const LoadIncrement(this.value, {this.unit = 'kg'});

  static const LoadIncrement barbellMetric = LoadIncrement(2.5, unit: 'kg');
  static const LoadIncrement dumbbellMetric = LoadIncrement(2.0, unit: 'kg');
  static const LoadIncrement machineMetric = LoadIncrement(5.0, unit: 'kg');
  static const LoadIncrement cableMetric = LoadIncrement(2.5, unit: 'kg');
  static const LoadIncrement assistedMetric = LoadIncrement(2.5, unit: 'kg');
  static const LoadIncrement defaultMetric = LoadIncrement(2.5, unit: 'kg');

  static const LoadIncrement barbellImperial = LoadIncrement(5.0, unit: 'lb');
  static const LoadIncrement dumbbellImperial = LoadIncrement(5.0, unit: 'lb');
  static const LoadIncrement machineImperial = LoadIncrement(10.0, unit: 'lb');
  static const LoadIncrement cableImperial = LoadIncrement(5.0, unit: 'lb');
  static const LoadIncrement assistedImperial = LoadIncrement(5.0, unit: 'lb');
  static const LoadIncrement defaultImperial = LoadIncrement(5.0, unit: 'lb');

  /// Resolves the load increment for an equipment descriptor.
  static LoadIncrement fromEquipment(String? equipment,
      {bool isMetric = true}) {
    if (equipment == null) {
      return isMetric ? defaultMetric : defaultImperial;
    }
    final norm = equipment.toLowerCase().trim();
    if (norm.contains('langhantel') ||
        norm.contains('barbell') ||
        norm == 'lh') {
      return isMetric ? barbellMetric : barbellImperial;
    }
    if (norm.contains('kurzhantel') ||
        norm.contains('dumbbell') ||
        norm == 'kh') {
      return isMetric ? dumbbellMetric : dumbbellImperial;
    }
    if (norm.contains('assisted')) {
      return isMetric ? assistedMetric : assistedImperial;
    }
    if (norm.contains('kabel') || norm.contains('cable')) {
      return isMetric ? cableMetric : cableImperial;
    }
    if (norm.contains('maschine') || norm.contains('machine')) {
      return isMetric ? machineMetric : machineImperial;
    }
    return isMetric ? defaultMetric : defaultImperial;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadIncrement &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          unit == other.unit;

  @override
  int get hashCode => value.hashCode ^ unit.hashCode;

  @override
  String toString() => '$value $unit';
}

/// A recorded set from workout history used to derive progression.
class ProgressionSetEntry {
  final SetCompletion completion;
  final LoadMode? loadMode;
  final RepRange? range;
  final String? equipmentIdentity;
  final bool substituted;
  final bool overshootConfirmed;
  final int? bridgeTarget;
  final DateTime performedAt;
  final double? weight;
  final int? reps;
  final String setType; // 'normal', 'warmup', 'failure', 'dropset'
  final int? rir;
  final bool valuesAutoFilled;
  final bool isCompleted;
  final String? sessionId;
  final int? order;

  const ProgressionSetEntry({
    this.completion = SetCompletion.completed,
    this.loadMode,
    this.range,
    this.equipmentIdentity,
    this.substituted = false,
    this.overshootConfirmed = false,
    this.bridgeTarget,
    required this.performedAt,
    this.weight,
    this.reps,
    this.setType = 'normal',
    this.rir,
    this.valuesAutoFilled = false,
    this.isCompleted = true,
    this.sessionId,
    this.order,
  });

  bool get isWarmup => setType.toLowerCase() == 'warmup';
  bool get isDropset => setType.toLowerCase() == 'dropset';
  bool get isWorkingSet =>
      WorkoutSetPositionMapper.isWorking(setType) && isCompleted;
}

/// One eligible (normal or failure) set in the routine currently being run.
///
/// [id] is deliberately an opaque domain key. The service uses the routine
/// template id, while the pure engine only needs it to return the matching
/// suggestion without ever knowing about persistence.
class WorkingSetPosition {
  final String id;
  final RepRange? range;

  const WorkingSetPosition({required this.id, this.range});
}

/// The collection of past sets for an exercise.
class ExerciseProgressionHistory {
  final List<ProgressionSetEntry> sets;

  const ExerciseProgressionHistory(this.sets);

  bool get isEmpty => sets.isEmpty;
  bool get isNotEmpty => sets.isNotEmpty;
}

/// Machine-readable keys describing the reasoning behind a progression outcome.
abstract class ProgressionReason {
  static const String rangeToppedOut = 'range_topped_out';
  static const String breakExceededThreeWeeks = 'break_exceeded_three_weeks';
  static const String repsBelowRangeMin = 'reps_below_range_min';
  static const String repsInRangeNotToppedOut = 'reps_in_range_not_topped_out';
  static const String autoFilledSets = 'auto_filled_sets';
  static const String noHistory = 'no_history';
  static const String noWorkingSetsInSession = 'no_working_sets_in_session';
  static const String noLoadSupport = 'no_load_support';
  static const String invalidRange = 'invalid_range';
  static const String noRepRange = 'no_rep_range';
  static const String inWorkoutStructure = 'in_workout_structure';
  static const String inWorkoutFallback = 'in_workout_fallback';
  static const String firstSetE1rm = 'first_set_e1rm';
  static const String fixedRepTarget = 'fixed_rep_target';
  static const String bodyweightReps = 'bodyweight_reps';
  static const String e1rmUnavailable = 'e1rm_unavailable';
}

/// The progression prescription produced by the adaptive engine.
class ProgressionSuggestion {
  final ProgressionPolicy policy;
  final LoadLadderSource ladderSource;
  final List<ProgressionReview> reviews;
  final int? bridgeTarget;
  final ProgressionOutcome outcome;
  final double? targetWeight;
  final int? targetReps;
  final int? targetRir;
  final String reason;
  final String algorithmVersion;

  const ProgressionSuggestion({
    this.policy = ProgressionPolicy.linkedWorkingSets,
    this.ladderSource = LoadLadderSource.incrementFallback,
    this.reviews = const [],
    this.bridgeTarget,
    required this.outcome,
    this.targetWeight,
    this.targetReps,
    this.targetRir,
    required this.reason,
    required this.algorithmVersion,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressionSuggestion &&
          runtimeType == other.runtimeType &&
          outcome == other.outcome &&
          targetWeight == other.targetWeight &&
          targetReps == other.targetReps &&
          targetRir == other.targetRir &&
          reason == other.reason &&
          algorithmVersion == other.algorithmVersion;

  @override
  int get hashCode =>
      outcome.hashCode ^
      targetWeight.hashCode ^
      targetReps.hashCode ^
      targetRir.hashCode ^
      reason.hashCode ^
      algorithmVersion.hashCode;

  @override
  String toString() =>
      'ProgressionSuggestion(outcome: $outcome, targetWeight: $targetWeight, targetReps: $targetReps, targetRir: $targetRir, reason: $reason, algorithmVersion: $algorithmVersion)';
}
