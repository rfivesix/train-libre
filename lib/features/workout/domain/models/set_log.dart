// lib/models/set_log.dart
// Complete code

/// Represents a single set performed during an exercise.
///
/// Contains data about weight, repetitions, rest time, and completion status.
class SetLog {
  /// Unique identifier for the set log.
  final int? id;

  /// The identifier of the workout session this set belongs to.
  final int workoutLogId;

  /// The stable identifier of the exercise in the catalog or database, if known.
  /// Null for legacy rows written before exercise_id was tracked.
  final String? exerciseId;

  /// The name of the exercise performed in this set.
  final String exerciseName;

  /// The type of set (e.g., "Normal", "Warm-up", "Dropset").
  final String setType;

  /// The weight used for the set in kilograms.
  final double? weightKg;

  /// The number of repetitions performed.
  final int? reps;

  /// The rest time taken after this set in seconds.
  final int? restTimeSeconds;

  /// Whether the set has been completed by the user.
  final bool? isCompleted;

  /// The order in which this set appears in the workout log.
  final int? logOrder;

  /// Which exercise block of a live session this set belongs to.
  ///
  /// Written while a workout runs so the session can be rebuilt exactly after
  /// the app is killed, instead of inferring the grouping from
  /// [exerciseName]. Null for rows written before this existed.
  final int? exerciseBlock;

  /// Snapshot of the routine's contiguous superset group.
  final int? supersetGroup;

  /// Optional notes about the set.
  final String? notes;

  /// The distance covered during the set (for cardio exercises) in kilometers.
  final double? distanceKm;

  /// The duration of the set in seconds.
  final int? durationSeconds;

  /// Rate of Perceived Exertion (1-10 scale).
  final int? rpe;

  /// Identifier for supersets if this set is part of one.
  final int? supersetId;

  /// Reps in Reserve (how many more reps could have been performed).
  final int? rir;

  /// Temporary flag: True if this set is a Max Weight PR.
  final bool isMaxWeightPR;

  /// Temporary flag: True if this set is a Max Volume PR.
  final bool isMaxVolumePR;

  /// Temporary flag: True if this set is an Estimated 1RM PR.
  final bool isMaxEst1RMPR;

  /// Temporary flag: True if this set is a Max Distance PR (Cardio).
  final bool isMaxDistancePR;

  /// Temporary flag: True if this set is a Longest Duration PR (Cardio).
  final bool isMaxDurationPR;

  /// Temporary flag: True if this set is a Fastest Pace PR (Cardio).
  final bool isFastestPacePR;

  /// Temporary value: Difference to previous Weight PR.
  final double? weightPRDiff;

  /// Temporary value: Difference to previous Volume PR.
  final double? volumePRDiff;

  /// Temporary value: Difference to previous Estimated 1RM PR.
  final double? est1rmPRDiff;

  /// Temporary value: Difference to previous Distance PR (Cardio).
  final double? distancePRDiff;

  /// Temporary value: Difference to previous Duration PR (Cardio).
  final int? durationPRDiff;

  /// Temporary value: Difference to previous Pace PR (Cardio).
  final double? pacePRDiff;

  /// Prescription origin ('none', 'routine', 'engine').
  final String prescriptionOrigin;

  /// Prescribed minimum repetitions.
  final int? prescribedRepMin;

  /// Prescribed maximum repetitions.
  final int? prescribedRepMax;

  /// Prescribed target weight in kg.
  final double? prescribedWeight;

  /// Prescribed Reps in Reserve.
  final int? prescribedRir;

  /// Whether the prescription was overridden by the user.
  final bool prescriptionOverridden;

  /// Whether values were auto-filled from target template upon completion.
  final bool valuesAutoFilled;

  /// ID of the exercise for which this exercise was substituted, if any.
  final String? substitutedForExerciseId;

  /// Human-readable explanation of the progression rationale.
  final String? progressionReason;

  /// Version of the algorithm that produced the prescription.
  final String? progressionAlgorithmVersion;

  /// Creates a new [SetLog] instance.
  SetLog({
    this.id,
    required this.workoutLogId,
    this.exerciseId,
    required this.exerciseName,
    required this.setType,
    this.weightKg,
    this.reps,
    this.restTimeSeconds,
    this.isCompleted,
    this.logOrder,
    this.exerciseBlock,
    this.supersetGroup,
    this.notes,
    this.distanceKm,
    this.durationSeconds,
    this.rpe,
    this.rir,
    this.supersetId,
    this.isMaxWeightPR = false,
    this.isMaxVolumePR = false,
    this.isMaxEst1RMPR = false,
    this.isMaxDistancePR = false,
    this.isMaxDurationPR = false,
    this.isFastestPacePR = false,
    this.weightPRDiff,
    this.volumePRDiff,
    this.est1rmPRDiff,
    this.distancePRDiff,
    this.durationPRDiff,
    this.pacePRDiff,
    this.prescriptionOrigin = 'none',
    this.prescribedRepMin,
    this.prescribedRepMax,
    this.prescribedWeight,
    this.prescribedRir,
    this.prescriptionOverridden = false,
    this.valuesAutoFilled = false,
    this.substitutedForExerciseId,
    this.progressionReason,
    this.progressionAlgorithmVersion,
  });

  /// Creates a [SetLog] instance from a Map, typically from a database row.
  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      id: map['id'],
      workoutLogId: map['workout_log_id'] ?? map['workoutLogId'],
      exerciseId: map['exercise_id'] as String? ?? map['exerciseId'] as String?,
      exerciseName: map['exercise_name'] ?? map['exerciseName'] ?? '',
      setType: map['set_type'] ?? map['setType'] ?? 'normal',
      weightKg: (map['weight_kg'] as num?)?.toDouble() ??
          (map['weightKg'] as num?)?.toDouble(),
      reps: map['reps'],
      restTimeSeconds: map['rest_time_seconds'] ?? map['restTimeSeconds'],
      // MODIFICATION: isCompleted can be null; map 1 or true to true and everything else to false.
      isCompleted: map['is_completed'] == 1 || map['isCompleted'] == true,
      logOrder: map['log_order'] ?? map['logOrder'],
      exerciseBlock: map['exercise_block'] ?? map['exerciseBlock'],
      supersetGroup: map['superset_group'] ?? map['supersetGroup'],
      notes: map['notes'],
      distanceKm: (map['distance_km'] as num?)?.toDouble() ??
          (map['distanceKm'] as num?)?.toDouble(),
      durationSeconds: map['duration_seconds'] ?? map['durationSeconds'],
      rpe: map['rpe'],
      rir: map['rir'],
      supersetId: map['superset_id'] ?? map['supersetId'],
      prescriptionOrigin: map['prescription_origin'] as String? ??
          map['prescriptionOrigin'] as String? ??
          'none',
      prescribedRepMin: map['prescribed_rep_min'] ?? map['prescribedRepMin'],
      prescribedRepMax: map['prescribed_rep_max'] ?? map['prescribedRepMax'],
      prescribedWeight: (map['prescribed_weight'] as num?)?.toDouble() ??
          (map['prescribedWeight'] as num?)?.toDouble(),
      prescribedRir: map['prescribed_rir'] ?? map['prescribedRir'],
      prescriptionOverridden: map['prescription_overridden'] == 1 ||
          map['prescriptionOverridden'] == true,
      valuesAutoFilled:
          map['values_auto_filled'] == 1 || map['valuesAutoFilled'] == true,
      substitutedForExerciseId: map['substituted_for_exercise_id'] as String? ??
          map['substitutedForExerciseId'] as String?,
      progressionReason: map['progression_reason'] as String? ??
          map['progressionReason'] as String?,
      progressionAlgorithmVersion:
          map['progression_algorithm_version'] as String? ??
              map['progressionAlgorithmVersion'] as String?,
      // Note: PR flags are not stored in the database.
    );
  }

  /// Converts the [SetLog] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_log_id': workoutLogId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'set_type': setType,
      'weight_kg': weightKg,
      'reps': reps,
      'rest_time_seconds': restTimeSeconds,
      // MODIFICATION: Store true as 1, false/null as 0.
      'is_completed': isCompleted == true ? 1 : 0,
      'log_order': logOrder,
      'exercise_block': exerciseBlock,
      'superset_group': supersetGroup,
      'notes': notes,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'rpe': rpe,
      'rir': rir,
      'superset_id': supersetId,
      'prescription_origin': prescriptionOrigin,
      'prescribed_rep_min': prescribedRepMin,
      'prescribed_rep_max': prescribedRepMax,
      'prescribed_weight': prescribedWeight,
      'prescribed_rir': prescribedRir,
      'prescription_overridden': prescriptionOverridden ? 1 : 0,
      'values_auto_filled': valuesAutoFilled ? 1 : 0,
      'substituted_for_exercise_id': substitutedForExerciseId,
      'progression_reason': progressionReason,
      'progression_algorithm_version': progressionAlgorithmVersion,
    };
  }

  /// Creates a copy of this [SetLog] with the given fields replaced by the new values.
  ///
  /// Use optional [clearWeight], [clearReps], [clearRir], [clearDistance], and [clearDuration]
  /// flags to explicitly set those fields to null.
  SetLog copyWith({
    int? id,
    int? workoutLogId,
    String? exerciseId,
    String? exerciseName,
    String? setType,
    double? weightKg,
    int? reps,
    int? restTimeSeconds,
    bool? isCompleted,
    int? logOrder,
    int? exerciseBlock,
    int? supersetGroup,
    String? notes,
    double? distanceKm,
    int? durationSeconds,
    int? rpe,
    int? rir,
    int? supersetId,
    bool? isMaxWeightPR,
    bool? isMaxVolumePR,
    bool? isMaxEst1RMPR,
    bool? isMaxDistancePR,
    bool? isMaxDurationPR,
    bool? isFastestPacePR,
    double? weightPRDiff,
    double? volumePRDiff,
    double? est1rmPRDiff,
    double? distancePRDiff,
    int? durationPRDiff,
    double? pacePRDiff,
    String? prescriptionOrigin,
    int? prescribedRepMin,
    int? prescribedRepMax,
    double? prescribedWeight,
    int? prescribedRir,
    bool? prescriptionOverridden,
    bool? valuesAutoFilled,
    String? substitutedForExerciseId,
    String? progressionReason,
    String? progressionAlgorithmVersion,
    bool clearWeight = false,
    bool clearReps = false,
    bool clearRir = false,
    bool clearDistance = false,
    bool clearDuration = false,
    bool clearSupersetGroup = false,
    bool clearExerciseId = false,
    bool clearPrescribedWeight = false,
    bool clearPrescribedRir = false,
    bool clearPrescribedRepMin = false,
    bool clearPrescribedRepMax = false,
  }) {
    return SetLog(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      exerciseId: clearExerciseId ? null : (exerciseId ?? this.exerciseId),
      exerciseName: exerciseName ?? this.exerciseName,
      setType: setType ?? this.setType,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      reps: clearReps ? null : (reps ?? this.reps),
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      logOrder: logOrder ?? this.logOrder,
      exerciseBlock: exerciseBlock ?? this.exerciseBlock,
      supersetGroup:
          clearSupersetGroup ? null : (supersetGroup ?? this.supersetGroup),
      notes: notes ?? this.notes,
      distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
      durationSeconds:
          clearDuration ? null : (durationSeconds ?? this.durationSeconds),
      rpe: rpe ?? this.rpe,
      rir: clearRir ? null : (rir ?? this.rir),
      supersetId: supersetId ?? this.supersetId,
      isMaxWeightPR: isMaxWeightPR ?? this.isMaxWeightPR,
      isMaxVolumePR: isMaxVolumePR ?? this.isMaxVolumePR,
      isMaxEst1RMPR: isMaxEst1RMPR ?? this.isMaxEst1RMPR,
      isMaxDistancePR: isMaxDistancePR ?? this.isMaxDistancePR,
      isMaxDurationPR: isMaxDurationPR ?? this.isMaxDurationPR,
      isFastestPacePR: isFastestPacePR ?? this.isFastestPacePR,
      weightPRDiff: weightPRDiff ?? this.weightPRDiff,
      volumePRDiff: volumePRDiff ?? this.volumePRDiff,
      est1rmPRDiff: est1rmPRDiff ?? this.est1rmPRDiff,
      distancePRDiff: distancePRDiff ?? this.distancePRDiff,
      durationPRDiff: durationPRDiff ?? this.durationPRDiff,
      pacePRDiff: pacePRDiff ?? this.pacePRDiff,
      prescriptionOrigin: prescriptionOrigin ?? this.prescriptionOrigin,
      prescribedRepMin: clearPrescribedRepMin
          ? null
          : (prescribedRepMin ?? this.prescribedRepMin),
      prescribedRepMax: clearPrescribedRepMax
          ? null
          : (prescribedRepMax ?? this.prescribedRepMax),
      prescribedWeight: clearPrescribedWeight
          ? null
          : (prescribedWeight ?? this.prescribedWeight),
      prescribedRir:
          clearPrescribedRir ? null : (prescribedRir ?? this.prescribedRir),
      prescriptionOverridden:
          prescriptionOverridden ?? this.prescriptionOverridden,
      valuesAutoFilled: valuesAutoFilled ?? this.valuesAutoFilled,
      substitutedForExerciseId:
          substitutedForExerciseId ?? this.substitutedForExerciseId,
      progressionReason: progressionReason ?? this.progressionReason,
      progressionAlgorithmVersion:
          progressionAlgorithmVersion ?? this.progressionAlgorithmVersion,
    );
  }
}
