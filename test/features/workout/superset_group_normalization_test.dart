import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';

void main() {
  RoutineExercise exercise(int id, int? group) => RoutineExercise(
        id: id,
        exercise: Exercise(
          id: id,
          texts: {
            'en': ExerciseText(name: 'Exercise $id', description: ''),
          },
          categoryName: 'Strength',
          primaryMuscles: const [],
          secondaryMuscles: const [],
        ),
        supersetGroup: group,
      );

  test('keeps one contiguous group with at least two members', () {
    final normalized = normalizeSupersetGroups([
      exercise(1, null),
      exercise(2, 4),
      exercise(3, 4),
      exercise(4, 4),
    ]);

    expect(normalized.map((e) => e.supersetGroup), [null, 4, 4, 4]);
  });

  test('clears singleton groups', () {
    final normalized = normalizeSupersetGroups([
      exercise(1, 1),
      exercise(2, null),
      exercise(3, 2),
    ]);

    expect(normalized.map((e) => e.supersetGroup), everyElement(isNull));
  });

  test('clears every run of a non-contiguous group', () {
    final normalized = normalizeSupersetGroups([
      exercise(1, 7),
      exercise(2, 7),
      exercise(3, null),
      exercise(4, 7),
      exercise(5, 7),
    ]);

    expect(normalized.map((e) => e.supersetGroup), everyElement(isNull));
  });
}
