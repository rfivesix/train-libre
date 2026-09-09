import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/progression/progression_models.dart';
import 'package:train_libre/features/workout/domain/progression/simple_progression_engine.dart';

void main() {
  const range = RepRange(8, 12);

  test('bodyweight sets receive a repetition target without a fake load', () {
    final suggestion = SimpleProgressionEngine.laterSet(
      firstLoggedLoadKg: null,
      firstReps: 10,
      target: range,
      increment: LoadIncrement.defaultMetric,
      mode: LoadMode.bodyweight,
      precedingSetRirs: const [null],
    );

    expect(suggestion.targetWeight, isNull);
    expect(suggestion.targetReps, 8);
    expect(suggestion.reason, ProgressionReason.bodyweightReps);
  });

  test('assisted sets retain assistance semantics and round conservatively',
      () {
    final suggestion = SimpleProgressionEngine.laterSet(
      firstLoggedLoadKg: 20,
      firstReps: 8,
      target: range,
      increment: LoadIncrement.assistedMetric,
      mode: LoadMode.assisted,
      precedingSetRirs: const [null],
      bodyweightKg: 80,
    );

    // 20 kg assistance at 80 kg body weight means 60 kg effective load.
    // The later set rounds up to 25 kg assistance, keeping the 8-rep target
    // achievable rather than making it harder through rounding.
    expect(suggestion.targetWeight, 25);
    expect(suggestion.targetReps, 8);
  });

  test('assisted sets without bodyweight keep the known load as a fallback',
      () {
    final suggestion = SimpleProgressionEngine.laterSet(
      firstLoggedLoadKg: 20,
      firstReps: 8,
      target: range,
      increment: LoadIncrement.assistedMetric,
      mode: LoadMode.assisted,
      precedingSetRirs: const [null],
    );

    expect(suggestion.targetWeight, 20);
    expect(suggestion.targetReps, 8);
    expect(suggestion.reason, ProgressionReason.e1rmUnavailable);
  });

  test('RIR raises the capacity estimate and softens the next back-off', () {
    final suggestion = SimpleProgressionEngine.laterSet(
      firstLoggedLoadKg: 60,
      firstReps: 10,
      firstRir: 2,
      target: range,
      increment: LoadIncrement.defaultMetric,
      mode: LoadMode.external,
      precedingSetRirs: const [2],
    );

    // 60 x 10 with RIR 2 estimates 60 x 12 to failure. The 97% retained
    // capacity then produces 67.5 kg for the visible 8-rep target.
    expect(suggestion.targetWeight, 67.5);
    expect(suggestion.targetReps, 8);
  });

  test('each completed set contributes its own RIR fatigue factor', () {
    final suggestion = SimpleProgressionEngine.laterSet(
      firstLoggedLoadKg: 60,
      firstReps: 10,
      firstRir: 2,
      target: range,
      increment: LoadIncrement.defaultMetric,
      mode: LoadMode.external,
      precedingSetRirs: const [2, 0],
    );

    // 97% after the RIR-2 first set, followed by the normal 95% after a
    // failure set, produces the third set's conservative 62.5 kg target.
    expect(suggestion.targetWeight, 62.5);
  });

  test('RIR refines fixed-target load projection without changing a range',
      () {
    final suggestion = SimpleProgressionEngine.firstSet(
      previousLoadKg: 60,
      previousReps: 8,
      previousRir: 2,
      target: const RepRange(10, 10),
      increment: LoadIncrement.defaultMetric,
      mode: LoadMode.external,
    );

    // The recorded 8 reps plus RIR 2 describe a 10-rep capacity, so the
    // fixed 10-rep target stays at 60 kg rather than being lowered.
    expect(suggestion.targetWeight, 60);
    expect(suggestion.targetReps, 10);
  });
}
