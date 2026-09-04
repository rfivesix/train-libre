import 'package:flutter/foundation.dart';

/// The user's body weight over time, as recorded in `measurements`.
///
/// **Historical sets are valued at the body weight of the day they were
/// performed, not at today's.** That is a decision with consequences either
/// way, so it is written down here rather than left to be inferred:
///
/// * Someone who loses ten kilos did not retroactively do easier pull-ups.
///   Recomputing old sessions at today's weight would drop every past tonnage
///   figure without a single past workout having changed — the statistics
///   would move under the user because of something unrelated to training.
/// * Progression compares past against present. If both sides move with
///   today's weight, a genuine strength change and a body-weight change stop
///   being distinguishable, and a diet reads as a uniform decline across the
///   whole history.
///
/// The cost is that the number depends on how diligently the user weighs
/// themselves. A set performed before the first recorded measurement gets no
/// body-weight component at all — see [at]. Extrapolating the earliest known
/// weight backwards was the obvious alternative and is deliberately not done:
/// it is a guess, it would be invisible in the result, and a guess that only
/// affects the oldest data is the hardest kind to notice being wrong.
@immutable
class BodyweightHistory {
  /// Ascending by date. Kept sorted so [at] can binary-search.
  final List<({DateTime date, double kg})> entries;

  const BodyweightHistory(this.entries);

  static const BodyweightHistory empty = BodyweightHistory([]);

  bool get isEmpty => entries.isEmpty;

  /// The most recent recorded body weight at or before [when].
  ///
  /// Null when nothing was recorded by then — including when the user has
  /// never weighed themselves. Callers must treat null as "unknown" and fall
  /// back to the logged number alone, never to a default.
  double? at(DateTime when) {
    if (entries.isEmpty) return null;

    var low = 0;
    var high = entries.length - 1;
    double? found;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (!entries[mid].date.isAfter(when)) {
        found = entries[mid].kg;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }

  static BodyweightHistory fromRows(
    Iterable<({DateTime date, double kg})> rows,
  ) {
    final sorted = rows.where((r) => r.kg > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return BodyweightHistory(List.unmodifiable(sorted));
  }
}

/// The load a set actually placed on the muscle, in kilograms.
///
/// Returns null when the set carries no meaningful load figure — a plank, a
/// run, or a body-weight set performed before the user ever recorded a weight.
/// Null means "do not count this towards tonnage", which is different from
/// zero and must stay different: a pull-up is not a zero-kilogram lift.
double? effectiveSetLoadKg({
  required String? trackingType,
  required String? loadMode,
  required double? loggedWeightKg,
  required double? bodyweightKg,
}) {
  // An assistance machine: the number is how much of the user's weight the
  // machine carried. What the user lifted is the remainder.
  if (loadMode == 'assisted') {
    if (bodyweightKg == null) return null;
    final load = bodyweightKg - (loggedWeightKg ?? 0);
    return load > 0 ? load : null;
  }

  final movesOwnBody =
      trackingType == 'bodyweight_reps' || loadMode == 'bodyweight';
  if (movesOwnBody) {
    final added = loggedWeightKg ?? 0;
    if (bodyweightKg == null) {
      // No measurement to work from. Only what was actually entered counts —
      // not a guessed 70 kg, and not silently nothing either.
      return added > 0 ? added : null;
    }
    return bodyweightKg + added;
  }

  final logged = loggedWeightKg ?? 0;
  return logged > 0 ? logged : null;
}

/// Tonnage for one set: effective load times repetitions.
///
/// Zero when either side is absent, so callers can sum without null checks.
double setTonnageKg({
  required String? trackingType,
  required String? loadMode,
  required double? loggedWeightKg,
  required int? reps,
  required double? bodyweightKg,
}) {
  if (reps == null || reps <= 0) return 0;
  final load = effectiveSetLoadKg(
    trackingType: trackingType,
    loadMode: loadMode,
    loggedWeightKg: loggedWeightKg,
    bodyweightKg: bodyweightKg,
  );
  return load == null ? 0 : load * reps;
}

/// Estimated one-rep max for a set, in kilograms (Brzycki).
///
/// Returns null when there is nothing honest to estimate from:
///
/// * an assisted set with no recorded body weight — the entered number is
///   assistance, so without a body weight there is no load to work back to,
///   and showing the assistance itself would invert the whole curve;
/// * a set with no load figure at all, or outside the range the formula holds
///   for.
///
/// A missing number is a missing number. An inverted one is a claim about the
/// user's progress that happens to be backwards, and nothing about it looks
/// wrong on screen.
double? estimatedOneRepMaxKg({
  required String? trackingType,
  required String? loadMode,
  required double? loggedWeightKg,
  required int? reps,
  required double? bodyweightKg,
}) {
  if (reps == null || reps <= 0 || reps > 12) return null;

  final load = effectiveSetLoadKg(
    trackingType: trackingType,
    loadMode: loadMode,
    loggedWeightKg: loggedWeightKg,
    bodyweightKg: bodyweightKg,
  );
  if (load == null || load <= 0) return null;

  return load * (36 / (37 - reps));
}
