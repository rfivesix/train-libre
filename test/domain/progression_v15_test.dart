import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/progression/progression_v15.dart';

void main() {
  final now = DateTime(2026, 9, 8);
  List<WorkingSetPosition> positions(int n) => List.generate(
      n, (i) => WorkingSetPosition(id: '$i', range: const RepRange(8, 12)));
  ProgressionSetEntry entry(int i, int reps,
          {double weight = 60,
          int day = 1,
          SetCompletion completion = SetCompletion.completed,
          bool auto = false,
          LoadMode mode = LoadMode.external,
          RepRange range = const RepRange(8, 12),
          String? equipment,
          bool substituted = false,
          String type = 'normal'}) =>
      ProgressionSetEntry(
          performedAt: now.subtract(Duration(days: day)),
          sessionId: '$day',
          order: i,
          reps: reps,
          weight: weight,
          setType: type,
          completion: completion,
          valuesAutoFilled: auto,
          loadMode: mode,
          range: range,
          equipmentIdentity: equipment,
          substituted: substituted);
  ProgressionResult run(List<ProgressionSetEntry> sets,
          {int n = 3,
          ProgressionPolicy policy = ProgressionPolicy.independentWorkingSets,
          LoadLadder? ladder,
          LoadMode mode = LoadMode.external}) =>
      ProgressionV15.evaluate(
          history: ExerciseProgressionHistory(sets),
          positions: positions(n),
          policy: policy,
          ladder: ladder,
          increment: const LoadIncrement(2.5),
          loadMode: mode,
          now: now);

  test('1, 2, 12: authored selection is explicit and stable', () {
    expect(
        selectProgressionPolicy(
            [60, 60, 60], List.filled(3, const RepRange(8, 12))),
        ProgressionPolicy.independentWorkingSets);
    expect(
        selectProgressionPolicy(
            [70, 60, 60], List.filled(3, const RepRange(8, 12))),
        ProgressionPolicy.linkedWorkingSets);
    expect(selectProgressionPolicy([null], [const RepRange(8, 12)]),
        ProgressionPolicy.linkedWorkingSets);
    final config =
        ProgressionConfig(policy: ProgressionPolicy.independentWorkingSets);
    expect(ProgressionConfig.decode(config.encode()).policy, config.policy);
  });
  test('1: uniform sets progress independently, without RIR', () {
    final r = run([entry(0, 12), entry(1, 10), entry(2, 9)]);
    expect(r.suggestions.map((s) => s.targetWeight), [62.5, 60, 60]);
    expect(r.suggestions.map((s) => s.targetReps), [8, 11, 10]);
  });
  test('2: top and back-offs remain linked', () {
    final r = run([entry(0, 12, weight: 70), entry(1, 10), entry(2, 9)],
        policy: ProgressionPolicy.linkedWorkingSets);
    expect(r.suggestions.map((s) => s.targetWeight), [70, 60, 60]);
  });
  test('3: warm-ups and drops never consume working positions', () {
    final r = run([
      entry(0, 1, type: 'warmup'),
      entry(1, 12),
      entry(2, 30, type: 'dropset'),
      entry(3, 10),
      entry(4, 9)
    ]);
    expect(r.suggestions.map((s) => s.targetWeight), [62.5, 60, 60]);
  });
  test('4, 5: coarse rung holds, decline offers U+2, achievement reoffers', () {
    final ladder = LoadLadder([8, 10], source: LoadLadderSource.user);
    final r = run([entry(0, 12, weight: 8)], n: 1, ladder: ladder);
    expect(r.suggestions.single.targetWeight, 8);
    final review = r.reviews.single;
    expect(review.kind, ReviewKind.largeStepTrial);
    expect(review.requiresUserConfirmation, true);
    expect(review.relativeJump, 0.25);
    final bridge = review.declineBridge(const RepRange(8, 12));
    expect(bridge!.targetReps, 14);
    expect(
        run([entry(0, 14, weight: 8)], n: 1, ladder: ladder)
            .reviews
            .single
            .kind,
        ReviewKind.largeStepTrial);
  });
  test('6: U+3 needs log confirmation and never leaps', () {
    final r = run([entry(0, 15)], n: 1);
    expect(r.reviews.single.kind, ReviewKind.farAboveRange);
    expect(r.suggestions.single.targetWeight, 60);
  });
  test('7: exactly three comparable manually entered attempts', () {
    for (var count = 1; count <= 3; count++) {
      final r = run(List.generate(count, (i) => entry(0, 6, day: i + 1)), n: 1);
      expect(r.reviews.any((r) => r.kind == ReviewKind.stallCandidate),
          count == 3);
      expect(r.suggestions.single.targetWeight, 60);
    }
    expect(
        run([
          entry(0, 6),
          entry(0, 9, day: 2),
          entry(0, 6, day: 3),
          entry(0, 6, day: 4)
        ], n: 1)
            .reviews,
        isEmpty);
    expect(
        run([entry(0, 6), entry(0, 6, day: 2, auto: true), entry(0, 6, day: 3)],
                n: 1)
            .reviews,
        isEmpty);
    expect(
        run([
          entry(0, 6),
          entry(0, 6, day: 2, range: const RepRange(5, 8)),
          entry(0, 6, day: 3)
        ], n: 1)
            .reviews,
        isEmpty);
  });
  test('8: interrupted rows retain positions and provide no evidence', () {
    for (final state
        in SetCompletion.values.where((s) => s != SetCompletion.completed)) {
      final r =
          run([entry(0, 12, completion: state), entry(1, 10), entry(2, 9)]);
      expect(r.suggestions.first.outcome, ProgressionOutcome.noSuggestion);
      expect(r.suggestions[1].targetReps, 11);
      expect(r.reviews, isEmpty);
    }
  });
  test('9: assisted zero is a metric boundary, never negative', () {
    final r = run([entry(0, 12, weight: 0, mode: LoadMode.assisted)],
        n: 1, mode: LoadMode.assisted);
    expect(r.reviews.single.kind, ReviewKind.modeBoundary);
    expect(r.reviews.single.targetMode, LoadMode.bodyweight);
    expect(r.suggestions.single.targetWeight, 0);
  });
  test('9: independent bodyweight ceiling accumulates across sessions', () {
    final sets = [
      entry(0, 10, weight: 0, mode: LoadMode.bodyweight),
      entry(1, 12, weight: 0, mode: LoadMode.bodyweight),
      entry(0, 12, weight: 0, day: 2, mode: LoadMode.bodyweight),
      entry(1, 9, weight: 0, day: 2, mode: LoadMode.bodyweight)
    ];
    expect(run(sets, n: 2, mode: LoadMode.bodyweight).reviews.single.targetMode,
        LoadMode.weightedBodyweight);
    expect(
        run(sets,
                n: 2,
                mode: LoadMode.bodyweight,
                policy: ProgressionPolicy.linkedWorkingSets)
            .reviews,
        isEmpty);
  });
  test('10, 11: metadata round trip and conservative legacy defaults', () {
    final r = run([entry(0, 12, weight: 8)],
        n: 1, ladder: LoadLadder([8, 10], source: LoadLadderSource.user));
    final config = ProgressionConfig(
        policy: r.policy,
        ladder: LoadLadder([8, 10], source: LoadLadderSource.user),
        completionReviewAcknowledged: true,
        events: [
          ReviewDecision(
              review: r.reviews.single, action: ReviewAction.rejected, at: now)
        ]);
    final restored = ProgressionConfig.decode(config.encode());
    expect(restored.events.single.review.algorithmVersion,
        ProgressionV15.algorithmVersion);
    expect(restored.events.single.review.ladderSource, LoadLadderSource.user);
    expect(restored.completionReviewAcknowledged, isTrue);
    expect(ProgressionConfig.decode(null).policy,
        ProgressionPolicy.linkedWorkingSets);
  });
  test('13: independent historic positions cannot be anchored either way', () {
    for (final load in [40.0, 80.0]) {
      expect(
          canAnchorPosition(ProgressionPolicy.independentWorkingSets,
              hasOwnHistory: true),
          false);
      expect(
          canAnchorPosition(ProgressionPolicy.independentWorkingSets,
              hasOwnHistory: false),
          true);
      expect(
          canAnchorPosition(ProgressionPolicy.linkedWorkingSets,
              hasOwnHistory: true),
          true);
      expect(load, isPositive);
    }
  });
}
