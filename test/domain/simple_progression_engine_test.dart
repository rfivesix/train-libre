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
      ordinalAfterFirst: 1,
      increment: LoadIncrement.defaultMetric,
      mode: LoadMode.bodyweight,
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
      ordinalAfterFirst: 1,
      increment: LoadIncrement.assistedMetric,
      mode: LoadMode.assisted,
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
      ordinalAfterFirst: 1,
      increment: LoadIncrement.assistedMetric,
      mode: LoadMode.assisted,
    );

    expect(suggestion.targetWeight, 20);
    expect(suggestion.targetReps, 8);
    expect(suggestion.reason, ProgressionReason.e1rmUnavailable);
  });
}
