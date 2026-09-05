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

  test('moves an entire group without splitting the target group', () {
    final moved = moveRoutineExerciseGroup([
      exercise(1, 1),
      exercise(2, 1),
      exercise(3, null),
      exercise(4, 2),
      exercise(5, 2),
    ], 0, 4);

    expect(moved.map((e) => e.id), [3, 4, 5, 1, 2]);
    expect(moved.map((e) => e.supersetGroup), [null, 2, 2, 1, 1]);
  });

  test('membership labels support trisets', () {
    final exercises = [
      exercise(1, 3),
      exercise(2, 3),
      exercise(3, 3),
    ];

    expect(supersetMembershipAt(exercises, 0)!.label, 'A1');
    expect(supersetMembershipAt(exercises, 1)!.label, 'A2');
    expect(supersetMembershipAt(exercises, 2)!.label, 'A3');
    expect(supersetMembershipAt(exercises, 2)!.isLast, isTrue);
  });

  test('disconnecting a four-exercise group preserves two pair supersets', () {
    final split = toggleSupersetConnectionAfter([
      exercise(1, 9),
      exercise(2, 9),
      exercise(3, 9),
      exercise(4, 9),
    ], 1);

    expect(split.map((e) => e.supersetGroup), [9, 9, 10, 10]);
  });

  test('disconnecting at an edge leaves the remaining pair connected', () {
    final split = toggleSupersetConnectionAfter([
      exercise(1, 9),
      exercise(2, 9),
      exercise(3, 9),
    ], 0);

    expect(split.map((e) => e.supersetGroup), [null, 10, 10]);
  });
}
