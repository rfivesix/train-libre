import 'dart:math' as math;

import '../classification/set_load.dart';
import 'progression_models.dart';

/// Part 12's deliberately small progression rule.
///
/// The previous implementation tried to model every working-set relationship
/// and recovery exception. This engine has two decisions only: how to progress
/// the next workout's first working set, and how to size the later sets from
/// today's first completed working set.
class SimpleProgressionEngine {
  static const algorithmVersion = 'progression_v1.7_rir';
  static const fatigueRetentionPerSet = 0.95;

  /// A recorded RIR makes the fixed 95% back-off less severe. Missing RIR
  /// deliberately stays on the original 95% rule, so beginners receive the
  /// exact same suggestions as before.
  static double fatigueRetentionForRir(int? rir) {
    final bounded = (rir ?? 0).clamp(0, 4).toDouble();
    return fatigueRetentionPerSet + (bounded * 0.01);
  }

  /// Suggests the first working set of a new session from the previous first
  /// working set. A range retains simple double progression. A fixed target
  /// uses the same canonical e1RM calculation as the rest of the app, while a
  /// positive increase remains limited to one practical equipment step.
  static ProgressionSuggestion firstSet({
    required double? previousLoadKg,
    required int? previousReps,
    required RepRange? target,
    required LoadIncrement increment,
    required LoadMode mode,
    int? previousRir,
    double? bodyweightKg,
  }) {
    if (previousLoadKg == null && mode != LoadMode.bodyweight) {
      return _absent(ProgressionReason.noHistory);
    }
    if (target == null) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: previousLoadKg,
        reason: ProgressionReason.noRepRange,
        algorithmVersion: algorithmVersion,
      );
    }

    if (mode == LoadMode.bodyweight) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetReps: _nextReps(previousReps, target),
        reason: ProgressionReason.bodyweightReps,
        algorithmVersion: algorithmVersion,
      );
    }

    final isFixedTarget = target.min == target.max;
    if (isFixedTarget) {
      final projected = _projectLoadForReps(
        loggedLoadKg: previousLoadKg,
        reps: previousReps,
        rir: previousRir,
        targetReps: target.min,
        mode: mode,
        bodyweightKg: bodyweightKg,
      );
      final load = projected == null
          ? previousLoadKg
          : _capAndRoundFirstSetChange(
              previousLoadKg: previousLoadKg!,
              projectedLoadKg: projected,
              increment: increment,
              mode: mode,
            );
      return ProgressionSuggestion(
        outcome: _isProgressed(previousLoadKg, load, mode)
            ? ProgressionOutcome.raise
            : ProgressionOutcome.hold,
        targetWeight: load,
        targetReps: target.min,
        reason: ProgressionReason.fixedRepTarget,
        algorithmVersion: algorithmVersion,
      );
    }

    final reps = previousReps;
    if (reps == null) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: previousLoadKg,
        targetReps: target.min,
        reason: ProgressionReason.noWorkingSetsInSession,
        algorithmVersion: algorithmVersion,
      );
    }
    if (reps < target.min) {
      return _suggest(
        load: previousLoadKg!,
        reps: target.min,
        reason: ProgressionReason.repsBelowRangeMin,
      );
    }
    if (reps < target.max) {
      return _suggest(
        load: previousLoadKg!,
        reps: reps + 1,
        reason: ProgressionReason.repsInRangeNotToppedOut,
      );
    }

    final next = _step(previousLoadKg!, increment, mode);
    return _suggest(
      load: next,
      reps: target.min,
      reason: ProgressionReason.rangeToppedOut,
      raise: true,
    );
  }

  /// Projects one later working set from the first completed working set of
  /// the current session. The e1RM is computed from effective load, so
  /// assisted and weighted-bodyweight exercises stay in their own numeric
  /// mode instead of using an inverted signed weight.
  static ProgressionSuggestion laterSet({
    required double? firstLoggedLoadKg,
    required int? firstReps,
    required RepRange? target,
    required LoadIncrement increment,
    required LoadMode mode,
    required List<int?> precedingSetRirs,
    int? firstRir,
    double? bodyweightKg,
    bool reduceOneStep = false,
  }) {
    if (target == null) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: firstLoggedLoadKg,
        reason: ProgressionReason.noRepRange,
        algorithmVersion: algorithmVersion,
      );
    }

    final targetReps = target.min;
    if (mode == LoadMode.bodyweight) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetReps: targetReps,
        reason: ProgressionReason.bodyweightReps,
        algorithmVersion: algorithmVersion,
      );
    }

    final e1rm = estimatedOneRepMaxKg(
      trackingType:
          mode == LoadMode.external ? 'weight_reps' : 'bodyweight_reps',
      loadMode: mode.name,
      loggedWeightKg: firstLoggedLoadKg,
      reps: _repsToFailure(firstReps, firstRir),
      bodyweightKg: bodyweightKg,
    );
    if (e1rm == null) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: firstLoggedLoadKg,
        targetReps: targetReps,
        reason: ProgressionReason.e1rmUnavailable,
        algorithmVersion: algorithmVersion,
      );
    }

    final retainedCapacity = precedingSetRirs.fold(
      e1rm,
      (capacity, rir) => capacity * fatigueRetentionForRir(rir),
    );
    final targetEffectiveLoad = retainedCapacity * ((37 - targetReps) / 36);
    final projected = _toLoggedLoad(
      effectiveLoadKg: targetEffectiveLoad,
      mode: mode,
      bodyweightKg: bodyweightKg,
    );
    if (projected == null) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: firstLoggedLoadKg,
        targetReps: targetReps,
        reason: ProgressionReason.e1rmUnavailable,
        algorithmVersion: algorithmVersion,
      );
    }

    var load = _roundForMode(projected, increment, mode);
    if (reduceOneStep) load = _moreConservative(load, increment, mode);
    return ProgressionSuggestion(
      outcome: ProgressionOutcome.hold,
      targetWeight: load,
      targetReps: targetReps,
      reason: ProgressionReason.firstSetE1rm,
      algorithmVersion: algorithmVersion,
    );
  }

  static ProgressionSuggestion _suggest({
    required double load,
    required int reps,
    required String reason,
    bool raise = false,
  }) =>
      ProgressionSuggestion(
        outcome: raise ? ProgressionOutcome.raise : ProgressionOutcome.hold,
        targetWeight: load,
        targetReps: reps,
        reason: reason,
        algorithmVersion: algorithmVersion,
      );

  static ProgressionSuggestion _absent(String reason) => ProgressionSuggestion(
        outcome: ProgressionOutcome.noSuggestion,
        reason: reason,
        algorithmVersion: algorithmVersion,
      );

  static int _nextReps(int? previousReps, RepRange target) {
    if (previousReps == null || previousReps < target.min) return target.min;
    return previousReps >= target.max ? target.max : previousReps + 1;
  }

  static double? _projectLoadForReps({
    required double? loggedLoadKg,
    required int? reps,
    int? rir,
    required int targetReps,
    required LoadMode mode,
    required double? bodyweightKg,
  }) {
    final e1rm = estimatedOneRepMaxKg(
      trackingType:
          mode == LoadMode.external ? 'weight_reps' : 'bodyweight_reps',
      loadMode: mode.name,
      loggedWeightKg: loggedLoadKg,
      reps: _repsToFailure(reps, rir),
      bodyweightKg: bodyweightKg,
    );
    if (e1rm == null || targetReps > 12) return null;
    return _toLoggedLoad(
      effectiveLoadKg: e1rm * ((37 - targetReps) / 36),
      mode: mode,
      bodyweightKg: bodyweightKg,
    );
  }

  static int? _repsToFailure(int? reps, int? rir) {
    if (reps == null) return null;
    return reps + (rir == null ? 0 : math.max(0, rir));
  }

  static double? _toLoggedLoad({
    required double effectiveLoadKg,
    required LoadMode mode,
    required double? bodyweightKg,
  }) {
    switch (mode) {
      case LoadMode.external:
        return effectiveLoadKg;
      case LoadMode.weightedBodyweight:
        return bodyweightKg == null ? null : effectiveLoadKg - bodyweightKg;
      case LoadMode.assisted:
        return bodyweightKg == null ? null : bodyweightKg - effectiveLoadKg;
      case LoadMode.bodyweight:
      case LoadMode.variable:
        return null;
    }
  }

  static double _capAndRoundFirstSetChange({
    required double previousLoadKg,
    required double projectedLoadKg,
    required LoadIncrement increment,
    required LoadMode mode,
  }) {
    final capped = switch (mode) {
      LoadMode.assisted =>
        math.max(projectedLoadKg, previousLoadKg - increment.value),
      _ => math.min(projectedLoadKg, previousLoadKg + increment.value),
    };
    return _roundForMode(capped, increment, mode);
  }

  static double _step(double load, LoadIncrement increment, LoadMode mode) =>
      mode == LoadMode.assisted
          ? math.max(0, load - increment.value)
          : load + increment.value;

  static double _moreConservative(
          double load, LoadIncrement increment, LoadMode mode) =>
      mode == LoadMode.assisted
          ? load + increment.value
          : math.max(0, load - increment.value);

  static double _roundForMode(
      double value, LoadIncrement increment, LoadMode mode) {
    final nonNegative = math.max(0, value);
    final units = nonNegative / increment.value;
    // More assistance is easier; external and added weight round down so the
    // visible target is not made harder by rounding.
    final rounded = mode == LoadMode.assisted
        ? units.ceilToDouble()
        : units.floorToDouble();
    return rounded * increment.value;
  }

  static bool _isProgressed(double? previous, double? next, LoadMode mode) =>
      previous != null &&
      next != null &&
      (mode == LoadMode.assisted ? next < previous : next > previous);
}
