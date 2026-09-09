import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/progression/progression_models.dart';
import 'package:train_libre/features/workout/domain/progression/simple_progression_engine.dart';

void main() {
  const range = RepRange(8, 12);
  const increment = LoadIncrement.defaultMetric;

  ProgressionSuggestion next({
    required double? previousLoad,
    required int? previousReps,
    double? testLoad,
    int? rir,
    LoadMode mode = LoadMode.external,
    RepRange target = range,
    double? bodyweightKg,
    LoadIncrement loadIncrement = increment,
  }) =>
      SimpleProgressionEngine.laterSet(
        previousLoggedLoadKg: previousLoad,
        previousReps: previousReps,
        previousRir: rir,
        testLoggedLoadKg: testLoad ?? previousLoad,
        target: target,
        increment: loadIncrement,
        mode: mode,
        bodyweightKg: bodyweightKg,
      );

  test('keeps straight-set load and lets repetitions absorb fatigue', () {
    final suggestion = next(previousLoad: 100, previousReps: 11);

    expect(suggestion.targetWeight, 100);
    expect(suggestion.targetReps, 9);
    expect(suggestion.reason, ProgressionReason.inWorkoutProjectedInRange);
  });

  test('raises exactly one increment for a high-repetition result', () {
    final suggestion = next(previousLoad: 100, previousReps: 12, rir: 1);

    expect(suggestion.targetWeight, 102.5);
    expect(suggestion.targetReps, 12);
    expect(suggestion.reason, ProgressionReason.inWorkoutHighRepGuard);
  });

  test('lowers to the highest increment that can achieve range minimum', () {
    final suggestion = next(previousLoad: 100, previousReps: 7);

    // 100 x 7 has an e1RM of 120 kg. After 95% retention, 91.83 kg is
    // the exact 8-rep load; it rounds down to the achievable 90 kg.
    expect(suggestion.targetWeight, 90);
    expect(suggestion.targetReps, 8);
    expect(suggestion.reason, ProgressionReason.inWorkoutProjectedBelowRange);
  });

  test('holds the test load after an implausibly short hypertrophy set', () {
    final suggestion = next(previousLoad: 100, previousReps: 2);

    expect(suggestion.targetWeight, 100);
    expect(suggestion.targetReps, 8);
    expect(suggestion.reason, ProgressionReason.inWorkoutShortSetGuard);
  });

  test('does not apply the short-set guard to a valid low-rep range', () {
    final suggestion = next(
      previousLoad: 100,
      previousReps: 2,
      target: const RepRange(3, 5),
    );

    expect(suggestion.targetWeight, 90);
    expect(suggestion.targetReps, 3);
    expect(suggestion.reason, ProgressionReason.inWorkoutProjectedBelowRange);
  });

  test('rounds a proportional template test load before projection', () {
    final suggestion = next(
      previousLoad: 120,
      previousReps: 7,
      testLoad: 96,
    );

    // 96 kg is not available with 2.5 kg plates; 95 kg is used in the
    // projection and therefore remains the visible prescription.
    expect(suggestion.targetWeight, 95);
    expect(suggestion.targetReps, 12);
  });

  test('never lowers a barbell recommendation below its hardware floor', () {
    final suggestion = next(
      previousLoad: 20,
      previousReps: 7,
      testLoad: 10,
      loadIncrement: LoadIncrement.barbellMetric,
    );

    expect(suggestion.targetWeight, 20);
    expect(suggestion.targetReps, 8);
  });

  test('uses an RIR-aware Markov step from the preceding real set', () {
    final suggestion = next(
      previousLoad: 60,
      previousReps: 10,
      rir: 2,
    );

    expect(suggestion.targetWeight, 60);
    expect(suggestion.targetReps, 11);
  });

  test('assisted work without body weight uses discrete assistance steps', () {
    final toppedOut = next(
      previousLoad: 20,
      previousReps: 12,
      mode: LoadMode.assisted,
    );
    final inRange = next(
      previousLoad: 20,
      previousReps: 9,
      mode: LoadMode.assisted,
    );
    final belowRange = next(
      previousLoad: 20,
      previousReps: 7,
      mode: LoadMode.assisted,
    );

    expect(toppedOut.targetWeight, 17.5);
    expect(toppedOut.targetReps, 8);
    expect(inRange.targetWeight, 20);
    expect(inRange.targetReps, 10);
    expect(belowRange.targetWeight, 22.5);
    expect(belowRange.targetReps, 8);
  });

  test('assisted work with body weight projects from effective resistance', () {
    final suggestion = next(
      previousLoad: 20,
      previousReps: 8,
      mode: LoadMode.assisted,
      bodyweightKg: 80,
    );

    // 20 kg assistance at 80 kg bodyweight is 60 kg effective resistance.
    // The calculated assistance rounds up to keep the 8-rep target reachable.
    expect(suggestion.targetWeight, 25);
    expect(suggestion.targetReps, 8);
  });

  test('bodyweight work receives only its next repetition target', () {
    final suggestion = next(
      previousLoad: null,
      previousReps: 10,
      mode: LoadMode.bodyweight,
    );

    expect(suggestion.targetWeight, isNull);
    expect(suggestion.targetReps, 11);
  });
}
