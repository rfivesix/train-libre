import '../../../../services/unit_service.dart';
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../classification/exercise_log_mask.dart';
import '../models/set_template.dart';
import '../parsers/rep_range_parser.dart' hide RepRange;
import '../progression/double_progression_engine.dart';
import '../repositories/workout_repository.dart';

/// Thin service layer that loads exercise history from the repository,
/// maps database and domain models into progression inputs (including
/// session grouping, equipment increments, and load modes), and invokes
/// the pure [DoubleProgressionEngine].
class WorkoutProgressionService {
  final IWorkoutRepository _repository;
  final UnitService _unitService;

  WorkoutProgressionService({
    required IWorkoutRepository repository,
    required UnitService unitService,
  })  : _repository = repository,
        _unitService = unitService;

  /// Computes the next set prescription suggestion for the given [exercise]
  /// and [template].
  ///
  /// Returns `null` if:
  /// - The routine template already defines an explicit [template.targetWeight].
  ///   (In this case, routine prescription has precedence and suppresses engine prefill.)
  /// - The exercise mask does not log a primary weight field (e.g. bodyweight-only).
  /// - The target rep range cannot be determined or parsed.
  /// - No completed history exists for the exercise.
  Future<ProgressionSuggestion?> getProgressionSuggestion({
    required Exercise exercise,
    required SetTemplate template,
    DateTime? now,
  }) async {
    // 1. Explicit routine target weight suppresses engine suggestions completely.
    if (template.targetWeight != null) {
      return null;
    }

    // 2. Bodyweight-only or non-weight exercises have no primary weight input.
    final mask = ExerciseLogMask.forExercise(exercise);
    if (!mask.showsPrimary) {
      return null;
    }

    // 3. Resolve rep range from template min/max or targetReps text.
    RepRange? range;
    if (template.targetRepMin != null && template.targetRepMax != null) {
      range = RepRange(template.targetRepMin!, template.targetRepMax!);
    } else {
      final parsed = parseRepRange(template.targetReps);
      if (parsed != null) {
        range = RepRange(parsed.min, parsed.max);
      }
    }
    if (range == null) {
      return null;
    }

    // 4. Load past sets via repository (UUID query with name snapshot fallback).
    final historyLogs = await _repository.getLastSetsForExercise(
      exerciseId: exercise.uuid,
      exerciseNameSnapshot: exercise.canonicalName,
    );
    if (historyLogs.isEmpty) {
      return null;
    }

    final isMetric = _unitService.isMetric;

    // 5. Translate SetLogs into ProgressionSetEntries.
    // sessionId is populated from workoutLogId.toString() so multiple workouts
    // on the same calendar day are grouped into distinct sessions.
    final progressionSets = historyLogs.map((s) {
      final double? weight;
      if (s.weightKg != null) {
        weight = isMetric
            ? s.weightKg
            : _unitService.convertDisplayValue(
                s.weightKg!, UnitDimension.weight);
      } else {
        weight = null;
      }

      return ProgressionSetEntry(
        performedAt: s.performedAt ?? DateTime.now(),
        weight: weight,
        reps: s.reps,
        setType: s.setType,
        rir: s.rir,
        valuesAutoFilled: s.valuesAutoFilled,
        isCompleted: s.isCompleted ?? true,
        sessionId: s.workoutLogId.toString(),
      );
    }).toList();

    // 6. Derive equipment increment and load mode.
    final increment = LoadIncrement.fromEquipment(
      exercise.primaryEquipment,
      isMetric: isMetric,
    );
    final loadMode = LoadMode.fromString(exercise.loadMode);

    // 7. Invoke pure domain engine.
    final suggestion = DoubleProgressionEngine.nextPrescription(
      history: ExerciseProgressionHistory(progressionSets),
      range: range,
      increment: increment,
      loadMode: loadMode,
      now: now,
    );

    if (suggestion.outcome == ProgressionOutcome.noSuggestion ||
        suggestion.targetWeight == null) {
      return null;
    }

    // 8. Convert target weight back to metric kg if working in imperial.
    final double metricTargetWeight = isMetric
        ? suggestion.targetWeight!
        : _unitService.convertToMetric(
            suggestion.targetWeight!, UnitDimension.weight);

    return ProgressionSuggestion(
      outcome: suggestion.outcome,
      targetWeight: metricTargetWeight,
      targetReps: suggestion.targetReps,
      targetRir: suggestion.targetRir,
      reason: suggestion.reason,
      algorithmVersion: suggestion.algorithmVersion,
    );
  }
}
