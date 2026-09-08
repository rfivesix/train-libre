import 'dart:math' as math;
import 'progression_models.dart';
export 'progression_models.dart';

ProgressionPolicy selectProgressionPolicy(
    List<double?> loads, List<RepRange?> ranges) {
  if (loads.isEmpty ||
      loads.length != ranges.length ||
      loads.first == null ||
      ranges.first == null ||
      ranges.first!.min <= 0) {
    return ProgressionPolicy.linkedWorkingSets;
  }
  return List.generate(loads.length,
              (i) => loads[i] == loads.first && ranges[i] == ranges.first)
          .every((v) => v)
      ? ProgressionPolicy.independentWorkingSets
      : ProgressionPolicy.linkedWorkingSets;
}

extension BridgeReview on ProgressionReview {
  ProgressionReview? declineBridge(RepRange range) =>
      kind != ReviewKind.largeStepTrial
          ? null
          : ProgressionReview(
              kind: ReviewKind.overRepBridge,
              position: position,
              policy: policy,
              ladderSource: ladderSource,
              reason: 'temporary_over_rep_bridge',
              currentLoad: currentLoad,
              targetLoad: currentLoad,
              targetReps: range.max + 2);
}

class ProgressionResult {
  final ProgressionPolicy policy;
  final List<ProgressionSuggestion> suggestions;
  final List<ProgressionReview> reviews;
  const ProgressionResult(
      {required this.policy, required this.suggestions, required this.reviews});
}

/// No I/O, hidden prescription changes or e1RM extrapolation. Sessions retain
/// incomplete/interrupted rows so excluding evidence never shifts a position.
class ProgressionV15 {
  static const algorithmVersion = 'progression_v1.5';
  static ProgressionResult evaluate(
      {required ExerciseProgressionHistory history,
      required List<WorkingSetPosition> positions,
      required LoadIncrement increment,
      required LoadMode loadMode,
      ProgressionPolicy policy = ProgressionPolicy.linkedWorkingSets,
      LoadLadder? ladder,
      LoadLadder? equipmentLadder,
      String? equipmentIdentity,
      DateTime? now}) {
    final resolved = ladder ?? equipmentLadder;
    final source = resolved?.source ?? LoadLadderSource.incrementFallback;
    final reviews = <ProgressionReview>[];
    ProgressionSuggestion suggestion(
            {double? load,
            int? reps,
            required String reason,
            bool raise = false,
            List<ProgressionReview> localReviews = const [],
            int? bridgeTarget}) =>
        ProgressionSuggestion(
            outcome: load == null
                ? ProgressionOutcome.noSuggestion
                : raise
                    ? ProgressionOutcome.raise
                    : ProgressionOutcome.hold,
            targetWeight: load,
            targetReps: reps,
            reason: reason,
            algorithmVersion: algorithmVersion,
            policy: policy,
            ladderSource: source,
            reviews: localReviews,
            bridgeTarget: bridgeTarget);
    ProgressionResult absent(String reason) => ProgressionResult(
        policy: policy,
        reviews: const [],
        suggestions: positions.map((_) => suggestion(reason: reason)).toList());
    final sessions = <String, List<ProgressionSetEntry>>{};
    for (final e in history.sets) {
      if (e.isWarmup ||
          e.isDropset ||
          !['normal', 'failure'].contains(e.setType.toLowerCase())) {
        continue;
      }
      final key = e.sessionId ??
          '${e.performedAt.year}-${e.performedAt.month}-${e.performedAt.day}';
      sessions.putIfAbsent(key, () => []).add(e);
    }
    DateTime date(List<ProgressionSetEntry> s) =>
        s.map((e) => e.performedAt).reduce((a, b) => a.isAfter(b) ? a : b);
    final ordered = sessions.values.toList()
      ..sort((a, b) => date(b).compareTo(date(a)));
    for (final s in ordered) {
      s.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    }
    if (ordered.isEmpty) return absent(ProgressionReason.noHistory);
    if ((now ?? DateTime.now()).difference(date(ordered.first)) >
        const Duration(days: 21)) {
      return absent(ProgressionReason.breakExceededThreeWeeks);
    }
    final latest = ordered.first;
    bool contextMatches(ProgressionSetEntry e, int i) =>
        (e.loadMode == null || e.loadMode == loadMode) &&
        e.equipmentIdentity == equipmentIdentity &&
        !e.substituted &&
        (e.range == null || e.range == positions[i].range);
    bool evidence(ProgressionSetEntry e, int i) =>
        e.isCompleted &&
        e.completion == SetCompletion.completed &&
        !e.valuesAutoFilled &&
        e.weight != null &&
        e.weight!.isFinite &&
        e.weight! >= 0 &&
        e.reps != null &&
        contextMatches(e, i);
    bool top(ProgressionSetEntry e, int i) =>
        evidence(e, i) &&
        positions[i].range != null &&
        e.reps! >= positions[i].range!.max &&
        (e.reps! < positions[i].range!.max + 3 || e.overshootConfirmed);
    final allTop = latest.length == positions.length &&
        List.generate(positions.length, (i) => top(latest[i], i))
            .every((v) => v);
    bool bodyReady = loadMode == LoadMode.bodyweight &&
        positions.isNotEmpty &&
        (policy == ProgressionPolicy.linkedWorkingSets
            ? allTop
            : List.generate(positions.length,
                    (i) => ordered.any((s) => s.length > i && top(s[i], i)))
                .every((v) => v));
    final results = <ProgressionSuggestion>[];
    for (var i = 0; i < positions.length; i++) {
      final ownSession = policy == ProgressionPolicy.independentWorkingSets
          ? ordered.where((s) => s.length > i).firstOrNull
          : latest;
      if (ownSession == null || i >= ownSession.length) {
        results.add(suggestion(reason: ProgressionReason.noHistory));
        continue;
      }
      final e = ownSession[i];
      if ((now ?? DateTime.now()).difference(e.performedAt) >
          const Duration(days: 21)) {
        results
            .add(suggestion(reason: ProgressionReason.breakExceededThreeWeeks));
        continue;
      }
      final range = positions[i].range;
      final local = <ProgressionReview>[];
      if (e.completion != SetCompletion.completed ||
          !e.isCompleted ||
          !contextMatches(e, i) ||
          e.weight == null ||
          !e.weight!.isFinite ||
          e.weight! < 0 ||
          loadMode == LoadMode.variable) {
        results.add(suggestion(reason: 'incomparable_or_interrupted'));
        continue;
      }
      final w = e.weight!;
      double? nextRung() => resolved != null
          ? resolved.next(w, assisted: loadMode == LoadMode.assisted)
          : increment.value <= 0
              ? null
              : loadMode == LoadMode.assisted
                  ? math.max(0.0, w - increment.value)
                  : w + increment.value;
      void review(ReviewKind kind,
          {double? target, int? reps, double? jump, LoadMode? mode}) {
        final r = ProgressionReview(
            kind: kind,
            position: positions[i].id,
            policy: policy,
            ladderSource: source,
            reason: kind.name,
            currentLoad: w,
            targetLoad: target,
            targetReps: reps,
            relativeJump: jump,
            targetMode: mode);
        local.add(r);
        reviews.add(r);
      }

      var load = w;
      var raise = false;
      var reason = range == null
          ? ProgressionReason.noRepRange
          : e.valuesAutoFilled
              ? ProgressionReason.autoFilledSets
              : (e.reps ?? 0) < range.min
                  ? ProgressionReason.repsBelowRangeMin
                  : ProgressionReason.repsInRangeNotToppedOut;
      if (range != null &&
          evidence(e, i) &&
          e.reps! >= range.max + 3 &&
          !e.overshootConfirmed) {
        review(ReviewKind.farAboveRange, target: nextRung(), reps: range.min);
        reason = 'farAboveRange';
      } else if (e.bridgeTarget != null &&
          range != null &&
          e.reps != null &&
          e.reps! < e.bridgeTarget!) {
        reason = 'overRepBridge';
      } else if (loadMode == LoadMode.assisted && w == 0 && evidence(e, i)) {
        review(ReviewKind.modeBoundary, target: 0, mode: LoadMode.bodyweight);
        reason = 'modeBoundary';
      } else if (loadMode == LoadMode.bodyweight) {
        if (bodyReady && i == 0) {
          final first = resolved?.values.where((v) => v > 0).firstOrNull ??
              (resolved == null ? increment.value : null);
          review(ReviewKind.modeBoundary,
              target: first, mode: LoadMode.weightedBodyweight);
        }
        reason = 'bodyweight_ceiling';
      } else if (policy == ProgressionPolicy.linkedWorkingSets
          ? allTop
          : top(e, i)) {
        final candidate = nextRung();
        if (candidate == null || candidate == w) {
          review(ReviewKind.stepUnavailable);
          reason = 'stepUnavailable';
        } else {
          final q = w > 0 ? (candidate - w).abs() / w : double.infinity;
          if (q > 0.10 + 1e-9) {
            review(ReviewKind.largeStepTrial,
                target: candidate,
                reps: range?.min,
                jump: q.isFinite ? q : null);
            reason = 'largeStepTrial';
          } else {
            load = candidate;
            raise = true;
            reason = 'ordinaryStep';
          }
        }
      }
      if (range != null && local.isEmpty) {
        final comparable = ordered
            .where((s) => s.length > i && evidence(s[i], i))
            .take(3)
            .toList();
        if (comparable.length == 3 &&
            comparable.every((s) => s[i].reps! < range.min)) {
          final lower = resolved != null
              ? resolved.next(w, assisted: loadMode != LoadMode.assisted)
              : loadMode == LoadMode.assisted
                  ? w + increment.value
                  : math.max(0.0, w - increment.value);
          review(ReviewKind.stallCandidate,
              target: lower,
              reps: range.min,
              jump: w > 0 && lower != null ? (lower - w).abs() / w : null);
        }
      }
      results.add(suggestion(
          load: load,
          bridgeTarget: e.bridgeTarget,
          reps: reason == 'overRepBridge'
              ? math.min(e.reps! + 1, e.bridgeTarget!)
              : nextSuggestedReps(
                  previousReps: e.reps, range: range, loadRaised: raise),
          reason: reason,
          raise: raise,
          localReviews: local));
    }
    return ProgressionResult(
        policy: policy, suggestions: results, reviews: reviews);
  }
}
