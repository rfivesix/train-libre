import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/classification/exercise_log_mask.dart';
import 'package:train_libre/features/workout/presentation/widgets/log_mask_labels.dart';

/// The six column widths of a set row.
///
/// The row and its heading used to derive these separately, from two different
/// conditions — `logsDistance || logsDuration` above, `logsDistance &&
/// logsDuration` below. A plank satisfies one and not the other, so its
/// heading and its inputs were laid out to different proportions.
SetRowFlex flexFor(String trackingType) => SetRowFlex.forMask(
  ExerciseLogMask.forExercise(
    Exercise(
      texts: const {'en': ExerciseText(name: 'Test')},
      categoryName: 'Test',
      primaryMuscles: const [],
      secondaryMuscles: const [],
      trackingType: trackingType,
      loadMode: 'bodyweight',
    ),
  ),
);

int total(SetRowFlex f) =>
    f.index + f.lastTime + f.primary + f.secondary + f.intensity;

void main() {
  test('a cardio row gives "last time" the most room', () {
    // "5.0 km · 28:14" is the longest string in the table and used to get less
    // room than the two input fields beside it.
    final cardio = flexFor('distance_time');
    expect(cardio.lastTime, greaterThan(cardio.primary));
    expect(cardio.lastTime, greaterThanOrEqualTo(cardio.secondary));
  });

  test('the duration field keeps every share it had', () {
    final cardio = flexFor('distance_time');
    expect(cardio.secondary, 4, reason: 'the duration column narrowed again');
    expect(cardio.index, lessThan(cardio.primary));
    expect(
      cardio.index / total(cardio),
      greaterThanOrEqualTo(
        flexFor('weight_reps').index / total(flexFor('weight_reps')),
      ),
    );
  });

  test('widening "last time" did not change either row total', () {
    // The checkbox is a fixed 56px beside these, so each shape has to keep
    // summing to what it summed to before or every column shifts under it.
    expect(total(flexFor('distance_time')), 15);
    expect(total(flexFor('weight_reps')), 8);
  });

  test('a plank uses the same proportions as a barbell row', () {
    // It logs a duration, which used to widen the heading but not the row.
    final plank = flexFor('time');
    final barbell = flexFor('weight_reps');
    expect(plank.index, barbell.index);
    expect(plank.lastTime, barbell.lastTime);
    expect(plank.primary, barbell.primary);
    expect(plank.secondary, barbell.secondary);
    expect(plank.intensity, barbell.intensity);
  });

  test('only a row with both distance and duration counts as cardio', () {
    expect(flexFor('distance_time').lastTime, 4);
    expect(flexFor('time_weight').lastTime, 2);
    expect(flexFor('bodyweight_reps').lastTime, 2);
  });
}
