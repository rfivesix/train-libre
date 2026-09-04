import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/domain/exercise_metrics.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';

/// Which lines the exercise history chart offers, and which it opens on.
///
/// It used to offer two fixed sets chosen by the same `isCardio` flag the log
/// rows were freed from: three cardio metrics or three strength ones. So a
/// plank could be charted on max weight, volume and e1RM and on nothing else,
/// and a Copenhagen adduction opened on "max weight" — a line that is flat at
/// zero forever, because the number it charts is *added* weight and a body
/// weight exercise has none.
Exercise exercise({
  required String trackingType,
  String loadMode = 'external',
  bool supportsAddedWeight = false,
}) =>
    Exercise(
      texts: const {'en': ExerciseText(name: 'Test')},
      categoryName: 'Test',
      primaryMuscles: const [],
      secondaryMuscles: const [],
      trackingType: trackingType,
      loadMode: loadMode,
      supportsAddedWeight: supportsAddedWeight,
    );

void main() {
  test('a barbell lift keeps the three metrics it always had', () {
    expect(
      exerciseMetricsFor(exercise(trackingType: 'weight_reps')),
      [
        ExerciseMetric.maxWeight,
        ExerciseMetric.volume,
        ExerciseMetric.est1rm,
      ],
    );
  });

  test('a body-weight exercise does not open on a line that is always zero',
      () {
    final metrics = exerciseMetricsFor(
      exercise(trackingType: 'bodyweight_reps', loadMode: 'bodyweight'),
    );
    expect(metrics, isNot(contains(ExerciseMetric.maxWeight)));
    expect(metrics.first, ExerciseMetric.volume);
    expect(metrics, contains(ExerciseMetric.est1rm));
  });

  test('unless a belt is the usual way to load it', () {
    final metrics = exerciseMetricsFor(
      exercise(
        trackingType: 'bodyweight_reps',
        loadMode: 'bodyweight',
        supportsAddedWeight: true,
      ),
    );
    expect(metrics, contains(ExerciseMetric.maxWeight));
  });

  test('an assistance machine is never charted on its stack', () {
    // More kilos there means more help. A rising line would mean the opposite
    // of progress.
    final metrics = exerciseMetricsFor(
      exercise(trackingType: 'weight_reps', loadMode: 'assisted'),
    );
    expect(metrics, isNot(contains(ExerciseMetric.maxWeight)));
    expect(metrics, contains(ExerciseMetric.volume));
  });

  test('a plank is charted on time', () {
    final metrics = exerciseMetricsFor(
      exercise(trackingType: 'time', loadMode: 'bodyweight'),
    );
    expect(metrics, [ExerciseMetric.duration]);
  });

  test('a loaded hold adds the weight it was held with', () {
    expect(
      exerciseMetricsFor(exercise(trackingType: 'time_weight')),
      [ExerciseMetric.duration, ExerciseMetric.maxWeight],
    );
  });

  test('a run keeps distance, duration and pace', () {
    expect(
      exerciseMetricsFor(
        exercise(trackingType: 'distance_time', loadMode: 'bodyweight'),
      ),
      [
        ExerciseMetric.distance,
        ExerciseMetric.duration,
        ExerciseMetric.pace,
      ],
    );
  });

  test('every shape offers at least one metric', () {
    // The screen opens on `.first`, so an empty list is a crash.
    for (final tracking in [
      'weight_reps',
      'bodyweight_reps',
      'time',
      'time_weight',
      'distance_time',
      'distance_only',
    ]) {
      expect(exerciseMetricsFor(exercise(trackingType: tracking)), isNotEmpty,
          reason: tracking);
    }
    // And an unclassified exercise, which is every user-created one.
    expect(
      exerciseMetricsFor(
        Exercise(
          texts: const {'en': ExerciseText(name: 'Mine')},
          categoryName: 'Chest',
          primaryMuscles: const [],
          secondaryMuscles: const [],
        ),
      ),
      isNotEmpty,
    );
  });
}
