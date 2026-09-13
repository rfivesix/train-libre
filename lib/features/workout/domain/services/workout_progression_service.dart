import '../../../../services/unit_service.dart';
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../classification/exercise_log_mask.dart';
import '../classification/workout_set_position.dart';
import '../models/set_log.dart';
import '../models/set_template.dart';
import '../parsers/rep_range_parser.dart' hide RepRange;
import '../progression/progression_models.dart';
import '../progression/simple_progression_engine.dart';
import '../repositories/workout_repository.dart';

/// Loads the small amount of history needed by Part 12.
///
/// Only the first working set of the latest comparable session drives the
/// first suggestion. During a live workout, each completed working set drives
/// just the directly following open position.
class WorkoutProgressionService {
  final IWorkoutRepository _repository;

  // Kept in the constructor because every production composition already
  // supplies it. Suggestions are stored in kilograms, so the engine itself
  // must not depend on the display unit.
  // ignore: unused_field
  final UnitService _unitService;

  WorkoutProgressionService({
    required IWorkoutRepository repository,
    required UnitService unitService,
  })  : _repository = repository,
        _unitService = unitService;

  /// Compatibility entry point for callers that request one template. It now
  /// follows the same first-working-set rule as the live workout and no longer
  /// suppresses a suggestion just because a routine has a seed weight.
  Future<ProgressionSuggestion?> getProgressionSuggestion({
    required Exercise exercise,
    required SetTemplate template,
    DateTime? now,
  }) async {
    if (template.id == null) return null;
    final suggestions = await getProgressionSuggestions(
      exercise: exercise,
      workingTemplates: [template],
      now: now,
    );
    return suggestions[template.id];
  }

  /// Returns a suggestion for the first working position only. The rest of a
  /// workout is intentionally not guessed before the user has performed that
  /// first set today.
  Future<Map<int, ProgressionSuggestion>> getProgressionSuggestions({
    required Exercise exercise,
    required List<SetTemplate> workingTemplates,
    ProgressionConfig config = const ProgressionConfig(),
    int? excludeWorkoutLogId,
    DateTime? now,
    double? bodyweightKg,
  }) async {
    if (workingTemplates.isEmpty || workingTemplates.first.id == null) {
      return const {};
    }
    final mode = config.loadMode ?? LoadMode.fromString(exercise.loadMode);
    final mask =
        ExerciseLogMask.forExercise(exercise).withSnapshotMode(mode.name);
    if (!mask.supportsLoadRepProgression) return const {};

    final previous = _latestFirstWorkingSet(
      await _history(exercise),
      excludeWorkoutLogId: excludeWorkoutLogId,
    );
    if (previous == null) return const {};

    final first = workingTemplates.first;
    final suggestion = SimpleProgressionEngine.firstSet(
      previousLoadKg: previous.weightKg,
      previousReps: previous.reps,
      previousRir: previous.rir,
      target: _rangeFor(first),
      increment: _incrementFor(exercise),
      mode: mode,
      bodyweightKg: bodyweightKg,
    );
    if (suggestion.outcome == ProgressionOutcome.noSuggestion) {
      return const {};
    }
    return {first.id!: suggestion};
  }

  /// Creates the next set from today's immediately preceding completed set.
  /// A deliberately different target weight in the routine preserves its
  /// relative relationship to today's actual first working-set load.
  Future<ProgressionSuggestion?> getInWorkoutSuggestion({
    required Exercise exercise,
    required List<SetTemplate> workingTemplates,
    required List<SetLog> currentWorkingSets,
    required int targetTemplateId,
    required int currentWorkoutLogId,
    ProgressionConfig config = const ProgressionConfig(),
    double? bodyweightKg,
  }) async {
    final targetIndex = workingTemplates
        .indexWhere((template) => template.id == targetTemplateId);
    if (targetIndex <= 0 || targetIndex >= currentWorkingSets.length) {
      return null;
    }

    final mode = config.loadMode ?? LoadMode.fromString(exercise.loadMode);
    final mask =
        ExerciseLogMask.forExercise(exercise).withSnapshotMode(mode.name);
    if (!mask.supportsLoadRepProgression) return null;

    final previous = currentWorkingSets[targetIndex - 1];
    if (previous.isCompleted != true ||
        (mode != LoadMode.bodyweight && previous.weightKg == null)) {
      return null;
    }

    final testLoad = _testLoadFor(
      mode: mode,
      increment: _incrementFor(exercise),
      workingTemplates: workingTemplates,
      currentWorkingSets: currentWorkingSets,
      targetIndex: targetIndex,
    );

    return SimpleProgressionEngine.laterSet(
      previousLoggedLoadKg: previous.weightKg,
      previousReps: previous.reps,
      previousRir: previous.rir,
      testLoggedLoadKg: testLoad,
      target: _rangeFor(workingTemplates[targetIndex]),
      increment: _incrementFor(exercise),
      mode: mode,
      bodyweightKg: bodyweightKg,
    );
  }

  double? _testLoadFor({
    required LoadMode mode,
    required LoadIncrement increment,
    required List<SetTemplate> workingTemplates,
    required List<SetLog> currentWorkingSets,
    required int targetIndex,
  }) {
    final previous = currentWorkingSets[targetIndex - 1];
    if (mode == LoadMode.bodyweight || previous.weightKg == null) return null;

    // Assistance values run in the opposite direction and cannot express a
    // useful percentage of resistance. Their discrete fallback uses the last
    // visible assistance amount instead.
    if (mode == LoadMode.assisted) return previous.weightKg;

    final firstTemplateWeight = workingTemplates.first.targetWeight;
    final targetTemplateWeight = workingTemplates[targetIndex].targetWeight;
    final firstActualWeight = currentWorkingSets.first.weightKg;
    final hasRelativeBackoff = firstTemplateWeight != null &&
        firstTemplateWeight > 0 &&
        targetTemplateWeight != null &&
        targetTemplateWeight > 0 &&
        firstActualWeight != null &&
        (targetTemplateWeight - firstTemplateWeight).abs() >= increment.value;
    if (!hasRelativeBackoff) return previous.weightKg;

    // Use a ratio, not an absolute delta: an authored 100 -> 80 back-off
    // remains 20% as the athlete's real first-set load progresses.
    return firstActualWeight * (targetTemplateWeight / firstTemplateWeight);
  }

  Future<List<SetLog>> _history(Exercise exercise) async {
    final repository = _repository;
    if (repository is ProgressionHistoryRepository && exercise.uuid != null) {
      return (repository as ProgressionHistoryRepository).getProgressionHistory(
        exerciseId: exercise.uuid!,
        exerciseNameSnapshot: exercise.canonicalName,
      );
    }
    return repository.getLastSetsForExercise(
      exerciseId: exercise.uuid,
      exerciseNameSnapshot: exercise.canonicalName,
    );
  }

  SetLog? _latestFirstWorkingSet(
    List<SetLog> history, {
    int? excludeWorkoutLogId,
  }) {
    final sessions = <String, List<SetLog>>{};
    for (final set in history) {
      if (set.workoutLogId == excludeWorkoutLogId ||
          set.isCompleted != true ||
          !WorkoutSetPositionMapper.isWorking(set.setType)) {
        continue;
      }
      final key = '${set.workoutLogId}:${set.exerciseBlock ?? 0}';
      sessions.putIfAbsent(key, () => []).add(set);
    }
    if (sessions.isEmpty) return null;

    final latest = sessions.values.reduce((left, right) {
      final leftDate = left
          .map((set) =>
              set.performedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final rightDate = right
          .map((set) =>
              set.performedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return leftDate.isAfter(rightDate) ? left : right;
    });
    latest.sort((left, right) {
      final order = (left.logOrder ?? 0).compareTo(right.logOrder ?? 0);
      return order != 0 ? order : (left.id ?? 0).compareTo(right.id ?? 0);
    });
    return latest.first;
  }

  RepRange? _rangeFor(SetTemplate template) {
    if (template.targetRepMin != null && template.targetRepMax != null) {
      return RepRange(template.targetRepMin!, template.targetRepMax!);
    }
    final parsed = parseRepRange(template.targetReps);
    return parsed == null ? null : RepRange(parsed.min, parsed.max);
  }

  LoadIncrement _incrementFor(Exercise exercise) =>
      LoadIncrement.fromEquipment(exercise.primaryEquipment, isMetric: true);
}
