import '../../../../services/unit_service.dart';
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../classification/exercise_log_mask.dart';
import '../models/set_template.dart';
import '../models/set_log.dart';
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

  /// Computes matching suggestions for the complete working-set structure of
  /// one exercise. Callers should pass only normal/failure templates, in their
  /// displayed order. The returned map is keyed by template id.
  Future<Map<int, ProgressionSuggestion>> getProgressionSuggestions({
    required Exercise exercise,
    required List<SetTemplate> workingTemplates,
    int? excludeWorkoutLogId,
    DateTime? now,
  }) async {
    final mask = ExerciseLogMask.forExercise(exercise);
    if (!mask.showsPrimary || workingTemplates.isEmpty) return const {};

    final templates =
        workingTemplates.where((template) => template.id != null).toList();
    if (templates.isEmpty) return const {};

    final historyLogs = await _repository.getLastSetsForExercise(
      exerciseId: exercise.uuid,
      exerciseNameSnapshot: exercise.canonicalName,
    );
    final relevantHistory = excludeWorkoutLogId == null
        ? historyLogs
        : historyLogs
            .where((set) => set.workoutLogId != excludeWorkoutLogId)
            .toList();
    if (relevantHistory.isEmpty) return const {};

    final isMetric = _unitService.isMetric;
    final entries = relevantHistory
        .map((set) => _toProgressionEntry(set, isMetric))
        .toList();
    final positions = templates
        .map((template) => WorkingSetPosition(
              id: template.id!.toString(),
              range: _rangeFor(template),
            ))
        .toList();
    final suggestions = DoubleProgressionEngine.nextPrescriptions(
      history: ExerciseProgressionHistory(entries),
      positions: positions,
      increment: LoadIncrement.fromEquipment(exercise.primaryEquipment,
          isMetric: isMetric),
      loadMode: LoadMode.fromString(exercise.loadMode),
      now: now,
    );

    final results = <int, ProgressionSuggestion>{};
    for (var index = 0; index < templates.length; index++) {
      final suggestion = suggestions[index];
      if (suggestion.targetWeight == null) continue;
      results[templates[index].id!] = _toMetricSuggestion(suggestion, isMetric);
    }
    return results;
  }

  /// Re-shapes an unfinished set from a real set completed earlier *today*.
  /// It uses the historic difference between the two positions, not an old
  /// absolute load, which keeps this safe even after the normal history window.
  Future<ProgressionSuggestion?> getInWorkoutSuggestion({
    required Exercise exercise,
    required List<SetTemplate> workingTemplates,
    required List<SetLog> currentWorkingSets,
    required int targetTemplateId,
    required int currentWorkoutLogId,
  }) async {
    final targetIndex =
        workingTemplates.indexWhere((t) => t.id == targetTemplateId);
    if (targetIndex < 0 || targetIndex >= currentWorkingSets.length) {
      return null;
    }

    var anchorIndex = -1;
    for (var index = 0; index < targetIndex; index++) {
      final set = currentWorkingSets[index];
      if (set.isCompleted == true && set.weightKg != null) {
        anchorIndex = index;
      }
    }
    if (anchorIndex < 0) return null;

    final historyLogs = await _repository.getLastSetsForExercise(
      exerciseId: exercise.uuid,
      exerciseNameSnapshot: exercise.canonicalName,
    );
    final previousEntries = historyLogs
        .where((set) => set.workoutLogId != currentWorkoutLogId)
        .map((set) => _toProgressionEntry(set, true))
        .where((set) => set.isWorkingSet)
        .toList();
    final anchorWeight = currentWorkingSets[anchorIndex].weightKg!;
    final anchorReps = currentWorkingSets[anchorIndex].reps;
    final targetRange = _rangeFor(workingTemplates[targetIndex]);
    final previousSession = _latestSession(previousEntries);
    final canPreserveHistoricalStructure =
        previousSession.length > targetIndex &&
            previousSession.length > anchorIndex &&
            previousSession[targetIndex].weight != null &&
            previousSession[anchorIndex].weight != null;
    final targetWeight = canPreserveHistoricalStructure
        ? anchorWeight +
            previousSession[targetIndex].weight! -
            previousSession[anchorIndex].weight!
        : anchorWeight;
    final referenceReps = canPreserveHistoricalStructure
        ? previousSession[targetIndex].reps
        : anchorReps;
    return ProgressionSuggestion(
      outcome: ProgressionOutcome.hold,
      targetWeight: targetWeight,
      targetReps:
          nextSuggestedReps(previousReps: referenceReps, range: targetRange),
      reason: canPreserveHistoricalStructure
          ? ProgressionReason.inWorkoutStructure
          : ProgressionReason.inWorkoutFallback,
      algorithmVersion: DoubleProgressionEngine.algorithmVersion,
    );
  }

  RepRange? _rangeFor(SetTemplate template) {
    if (template.targetRepMin != null && template.targetRepMax != null) {
      return RepRange(template.targetRepMin!, template.targetRepMax!);
    }
    final parsed = parseRepRange(template.targetReps);
    return parsed == null ? null : RepRange(parsed.min, parsed.max);
  }

  ProgressionSetEntry _toProgressionEntry(SetLog set, bool isMetric) {
    final weight = set.weightKg == null
        ? null
        : isMetric
            ? set.weightKg
            : _unitService.convertDisplayValue(
                set.weightKg!, UnitDimension.weight);
    return ProgressionSetEntry(
      performedAt: set.performedAt ?? DateTime.now(),
      weight: weight,
      reps: set.reps,
      setType: set.setType,
      rir: set.rir,
      valuesAutoFilled: set.valuesAutoFilled,
      isCompleted: set.isCompleted ?? true,
      sessionId: set.workoutLogId.toString(),
      order: set.logOrder,
    );
  }

  ProgressionSuggestion _toMetricSuggestion(
      ProgressionSuggestion suggestion, bool isMetric) {
    return ProgressionSuggestion(
      outcome: suggestion.outcome,
      targetWeight: isMetric
          ? suggestion.targetWeight
          : _unitService.convertToMetric(
              suggestion.targetWeight!, UnitDimension.weight),
      targetReps: suggestion.targetReps,
      targetRir: suggestion.targetRir,
      reason: suggestion.reason,
      algorithmVersion: suggestion.algorithmVersion,
    );
  }

  List<ProgressionSetEntry> _latestSession(List<ProgressionSetEntry> entries) {
    if (entries.isEmpty) return const [];
    final sessions = <String, List<ProgressionSetEntry>>{};
    for (final entry in entries) {
      sessions.putIfAbsent(entry.sessionId ?? '', () => []).add(entry);
    }
    final latest = sessions.values.reduce((left, right) {
      DateTime dateOf(List<ProgressionSetEntry> session) => session
          .map((entry) => entry.performedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return dateOf(left).isAfter(dateOf(right)) ? left : right;
    });
    return List<ProgressionSetEntry>.from(latest)
      ..sort((left, right) {
        final order = (left.order ?? 0).compareTo(right.order ?? 0);
        return order != 0
            ? order
            : left.performedAt.compareTo(right.performedAt);
      });
  }
}
