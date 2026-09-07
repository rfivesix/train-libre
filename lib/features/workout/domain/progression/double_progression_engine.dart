import 'dart:math' as math;

import 'progression_models.dart';

export 'progression_models.dart';

/// Pure domain implementation of the double progression rule.
///
/// Operates strictly on domain history and templates without database or I/O access.
class DoubleProgressionEngine {
  /// The algorithm version tag recorded in SetLogs.progressionAlgorithmVersion.
  static const String algorithmVersion = 'double_progression_v1';

  /// Computes the next prescription suggestion from exercise history and routine targets.
  static ProgressionSuggestion nextPrescription({
    required ExerciseProgressionHistory history,
    required RepRange range,
    required LoadIncrement increment,
    required LoadMode loadMode,
    DateTime? now,
  }) {
    if (history.isEmpty) {
      return const ProgressionSuggestion(
        outcome: ProgressionOutcome.noSuggestion,
        targetWeight: null,
        targetReps: null,
        reason: ProgressionReason.noHistory,
        algorithmVersion: algorithmVersion,
      );
    }

    // Rule 3 & 4: Only completed working sets count (normal and failure).
    // Warm-up sets and drop sets never influence progression.
    final workingSets = history.sets.where((s) => s.isWorkingSet).toList();
    if (workingSets.isEmpty) {
      return const ProgressionSuggestion(
        outcome: ProgressionOutcome.noSuggestion,
        targetWeight: null,
        targetReps: null,
        reason: ProgressionReason.noHistory,
        algorithmVersion: algorithmVersion,
      );
    }

    // Group working sets by session (sessionId if present, otherwise by calendar day).
    final sessionMap = <String, List<ProgressionSetEntry>>{};
    for (final set in workingSets) {
      final key = set.sessionId != null && set.sessionId!.isNotEmpty
          ? set.sessionId!
          : '${set.performedAt.year}-${set.performedAt.month.toString().padLeft(2, '0')}-${set.performedAt.day.toString().padLeft(2, '0')}';
      sessionMap.putIfAbsent(key, () => []).add(set);
    }

    // Sort sessions chronologically by the latest set in each session to find the last session.
    final sortedSessions = sessionMap.values.toList()
      ..sort((a, b) {
        final aLatest =
            a.map((s) => s.performedAt).reduce((x, y) => x.isAfter(y) ? x : y);
        final bLatest =
            b.map((s) => s.performedAt).reduce((x, y) => x.isAfter(y) ? x : y);
        return aLatest.compareTo(bLatest);
      });

    final lastSessionSets = sortedSessions.last;
    final lastSessionDate = lastSessionSets
        .map((s) => s.performedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // Rule 9: Determine baseline working load from the last session.
    final weights =
        lastSessionSets.map((s) => s.weight).whereType<double>().toList();

    if (weights.isEmpty) {
      return const ProgressionSuggestion(
        outcome: ProgressionOutcome.noSuggestion,
        targetWeight: null,
        targetReps: null,
        reason: ProgressionReason.noLoadSupport,
        algorithmVersion: algorithmVersion,
      );
    }

    final lastWeight = weights.reduce(math.max);

    // Rule 6: Break of more than 3 weeks (21 days) resets progression to hold last load.
    final referenceDate = now ?? DateTime.now();
    final gap = referenceDate.difference(lastSessionDate);
    if (gap > const Duration(days: 21)) {
      return ProgressionSuggestion(
        outcome: ProgressionOutcome.hold,
        targetWeight: lastWeight,
        targetReps: null,
        reason: ProgressionReason.breakExceededThreeWeeks,
        algorithmVersion: algorithmVersion,
      );
    }

    // Rule 2 & 10: Range is topped out when ALL working sets in the same session reach range.max.
    //
    // Decision for Rule 10:
    // Sets with valuesAutoFilled == true are NOT ignored completely, because ignoring them would treat
    // the user as having done fewer sets (or no workout at all), which could falsely trigger a 3-week break
    // or allow a raise based on a subset of manual sets. Instead, auto-filled sets are retained as performed
    // volume at the current load, but are not counted as evidence of reaching the top of the range.
    // Thus, auto-filled sets safely hold the current weight without triggering an unearned increase.
    final allToppedOut = lastSessionSets.every(
      (s) => !s.valuesAutoFilled && (s.reps ?? 0) >= range.max,
    );

    // Rule 5 & 8: If topped out, raise load by exactly one increment.
    // For assisted mode, progression means reducing assistance.
    if (allToppedOut) {
      double nextWeight;
      if (loadMode == LoadMode.assisted) {
        nextWeight = math.max(0.0, lastWeight - increment.value);
      } else {
        nextWeight = lastWeight + increment.value;
      }

      return ProgressionSuggestion(
        outcome: ProgressionOutcome.raise,
        targetWeight: nextWeight,
        targetReps: range.min,
        reason: ProgressionReason.rangeToppedOut,
        algorithmVersion: algorithmVersion,
      );
    }

    // Rule 7 & 10: Not all sets topped out -> hold current load.
    // Determine the most accurate reason for plateau diagnosis.
    String reason;
    if (lastSessionSets.any((s) => s.valuesAutoFilled)) {
      reason = ProgressionReason.autoFilledSets;
    } else if (lastSessionSets.any((s) => (s.reps ?? 0) < range.min)) {
      reason = ProgressionReason.repsBelowRangeMin;
    } else {
      reason = ProgressionReason.repsInRangeNotToppedOut;
    }

    return ProgressionSuggestion(
      outcome: ProgressionOutcome.hold,
      targetWeight: lastWeight,
      targetReps: null,
      reason: reason,
      algorithmVersion: algorithmVersion,
    );
  }
}

/// Convenience pure function matching the domain interface.
ProgressionSuggestion nextPrescription({
  required ExerciseProgressionHistory history,
  required RepRange range,
  required LoadIncrement increment,
  required LoadMode loadMode,
  DateTime? now,
}) =>
    DoubleProgressionEngine.nextPrescription(
      history: history,
      range: range,
      increment: increment,
      loadMode: loadMode,
      now: now,
    );
