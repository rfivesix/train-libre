import 'dart:math' as math;

import '../classification/set_load.dart';
import 'progression_models.dart';

/// Part 12's deliberately small progression rule.
///
/// The engine advances a new workout from its previous first working set, then
/// treats each completed working set as the empirical input for exactly one
/// following set. That keeps straight sets straight until the observed result
/// calls for a change instead of pre-computing a descending pyramid.
class SimpleProgressionEngine {
  static const algorithmVersion = 'progression_v1.8_jit';
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

  /// Produces the next working-set prescription from the immediately preceding
  /// completed set. [testLoggedLoadKg] has already preserved any intentional
  /// routine back-off structure; it is rounded to a usable increment before
  /// its repetitions are projected.
  ///
  /// Brzycki is used only through 12 effective repetitions. Assisted work
  /// without a known body weight follows a discrete assistance-step rule,
  /// because the visible assistance value is not the resistance being moved.
  static ProgressionSuggestion laterSet({
    required double? previousLoggedLoadKg,
    required int? previousReps,
    required double? testLoggedLoadKg,
    required RepRange? target,
    required LoadIncrement increment,
    required LoadMode mode,
    int? previousRir,
    double? bodyweightKg,
  }) {
    if (target == null) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: testLoggedLoadKg ?? previousLoggedLoadKg,
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

    if (previousLoggedLoadKg == null || testLoggedLoadKg == null) {
      return _absent(ProgressionReason.e1rmUnavailable);
    }

    final testLoad = _roundTestLoad(testLoggedLoadKg, increment, mode);
    final effectiveReps = _repsToFailure(previousReps, previousRir);

    // A very short hypertrophy-set attempt is not enough evidence to turn the
    // following set into an implausible deload. This guard deliberately does
    // not apply to valid low-rep strength ranges.
    if (effectiveReps != null && effectiveReps <= 3 && target.min >= 6) {
      return _suggest(
        load: testLoad,
        reps: target.min,
        reason: ProgressionReason.inWorkoutShortSetGuard,
      );
    }

    // Brzycki is intentionally unavailable above twelve effective reps. The
    // fallback remains small and deterministic: only an actual top-of-range
    // result earns one increment; otherwise the test load stays in place.
    if ((previousReps != null && previousReps > 12) ||
        (effectiveReps != null && effectiveReps > 12)) {
      final shouldAdvance = previousReps != null && previousReps >= target.max;
      final nextLoad =
          shouldAdvance ? _step(testLoad, increment, mode) : testLoad;
      return _suggest(
        load: nextLoad,
        reps: target.max,
        reason: ProgressionReason.inWorkoutHighRepGuard,
        raise: _isProgressed(testLoad, nextLoad, mode),
      );
    }

    if (mode == LoadMode.assisted && bodyweightKg == null) {
      return _assistedWithoutBodyweight(
        previousReps: previousReps,
        target: target,
        testLoad: testLoad,
        increment: increment,
      );
    }

    final e1rm = estimatedOneRepMaxKg(
      trackingType:
          mode == LoadMode.external ? 'weight_reps' : 'bodyweight_reps',
      loadMode: mode.name,
      loggedWeightKg: previousLoggedLoadKg,
      reps: effectiveReps,
      bodyweightKg: bodyweightKg,
    );
    if (e1rm == null) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: testLoad,
        targetReps: target.min,
        reason: ProgressionReason.e1rmUnavailable,
        algorithmVersion: algorithmVersion,
      );
    }

    // This is a Markov step: the real preceding performance becomes the new
    // capacity anchor, including its own RIR-dependent recovery allowance.
    final retainedCapacity = e1rm * fatigueRetentionForRir(previousRir);
    final testEffectiveLoad = _effectiveLoad(
      loggedLoadKg: testLoad,
      mode: mode,
      bodyweightKg: bodyweightKg,
    );
    if (testEffectiveLoad == null || testEffectiveLoad <= 0) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: testLoad,
        targetReps: target.min,
        reason: ProgressionReason.e1rmUnavailable,
        algorithmVersion: algorithmVersion,
      );
    }

    final rawProjectedReps = 37 - (36 * testEffectiveLoad / retainedCapacity);
    // Floating point representation can place an exact mathematical integer
    // such as 12 at 11.999999999. This epsilon only restores that boundary;
    // it never turns a meaningful fractional rep into the next integer.
    final projectedReps = math.max(0, (rawProjectedReps + 1e-9).floor());
    if (projectedReps > target.max) {
      final nextLoad = _step(testLoad, increment, mode);
      return _suggest(
        load: nextLoad,
        reps: target.max,
        reason: ProgressionReason.inWorkoutProjectedAboveRange,
        raise: _isProgressed(testLoad, nextLoad, mode),
      );
    }
    if (projectedReps >= target.min) {
      return _suggest(
        load: testLoad,
        reps: projectedReps,
        reason: ProgressionReason.inWorkoutProjectedInRange,
      );
    }

    // Invert Brzycki at the lower range boundary, then round conservatively
    // towards an achievable set. The current data model has no per-machine
    // minimum-load metadata, so zero is the only honest universal floor.
    final targetEffectiveLoad = retainedCapacity * ((37 - target.min) / 36);
    final projected = _toLoggedLoad(
      effectiveLoadKg: targetEffectiveLoad,
      mode: mode,
      bodyweightKg: bodyweightKg,
    );
    if (projected == null) {
      return _suggest(
        load: testLoad,
        reps: target.min,
        reason: ProgressionReason.e1rmUnavailable,
      );
    }
    return _suggest(
      load: _roundForMode(projected, increment, mode),
      reps: target.min,
      reason: ProgressionReason.inWorkoutProjectedBelowRange,
    );
  }

  static ProgressionSuggestion _assistedWithoutBodyweight({
    required int? previousReps,
    required RepRange target,
    required double testLoad,
    required LoadIncrement increment,
  }) {
    if (previousReps == null) {
      return _suggest(
        load: testLoad,
        reps: target.min,
        reason: ProgressionReason.e1rmUnavailable,
      );
    }
    if (previousReps >= target.max) {
      return _suggest(
        load: _step(testLoad, increment, LoadMode.assisted),
        reps: target.min,
        reason: ProgressionReason.assistedStepDown,
        raise: true,
      );
    }
    if (previousReps < target.min) {
      return _suggest(
        load: testLoad + increment.value,
        reps: target.min,
        reason: ProgressionReason.assistedStepUp,
      );
    }
    return _suggest(
      load: testLoad,
      reps: math.min(target.max, previousReps + 1),
      reason: ProgressionReason.assistedHold,
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

  static double? _effectiveLoad({
    required double loggedLoadKg,
    required LoadMode mode,
    required double? bodyweightKg,
  }) {
    switch (mode) {
      case LoadMode.external:
        return loggedLoadKg;
      case LoadMode.weightedBodyweight:
        return bodyweightKg == null ? null : bodyweightKg + loggedLoadKg;
      case LoadMode.assisted:
        return bodyweightKg == null ? null : bodyweightKg - loggedLoadKg;
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

  static double _roundTestLoad(
      double value, LoadIncrement increment, LoadMode mode) {
    final nonNegative = math.max(_minimumLoadFor(mode, increment), value);
    // A template ratio can create a value that does not exist on the machine.
    // The test load is descriptive rather than a safety back-off, so use the
    // nearest physical increment before projecting repetitions from it.
    final rounded = (nonNegative / increment.value).roundToDouble();
    return rounded * increment.value;
  }

  static double _roundForMode(
      double value, LoadIncrement increment, LoadMode mode) {
    final nonNegative = math.max(_minimumLoadFor(mode, increment), value);
    final units = nonNegative / increment.value;
    // More assistance is easier; external and added weight round down so the
    // visible target is not made harder by rounding.
    final rounded = mode == LoadMode.assisted
        ? units.ceilToDouble()
        : units.floorToDouble();
    return rounded * increment.value;
  }

  static double _minimumLoadFor(LoadMode mode, LoadIncrement increment) =>
      mode == LoadMode.external ? increment.minimumLoad : 0;

  static bool _isProgressed(double? previous, double? next, LoadMode mode) =>
      previous != null &&
      next != null &&
      (mode == LoadMode.assisted ? next < previous : next > previous);
}
