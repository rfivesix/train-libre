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

  test('swaps exercises within a superset and preserves the group', () {
    final moved = reorderRoutineExercise([
      exercise(1, 1),
      exercise(2, 1),
    ], 0, 1);

    expect(moved.map((e) => e.id), [2, 1]);
    expect(moved.map((e) => e.supersetGroup), [1, 1]);
  });

  test('reorders exercises within a triset and preserves the group', () {
    final moved = reorderRoutineExercise([
      exercise(1, 1),
      exercise(2, 1),
      exercise(3, 1),
    ], 2, 0);

    expect(moved.map((e) => e.id), [3, 1, 2]);
    expect(moved.map((e) => e.supersetGroup), [1, 1, 1]);
  });

  test('moving one exercise out of a 2-exercise superset dissolves it into standalone exercises', () {
    final moved = reorderRoutineExercise([
      exercise(1, 1),
      exercise(2, 1),
      exercise(3, null),
    ], 0, 2);

    expect(moved.map((e) => e.id), [2, 3, 1]);
    expect(moved.map((e) => e.supersetGroup), [null, null, null]);
  });

  test('moving one exercise out of a triset leaves the remaining pair as a superset', () {
    final moved = reorderRoutineExercise([
      exercise(1, 1),
      exercise(2, 1),
      exercise(3, 1),
      exercise(4, null),
    ], 0, 3);

    expect(moved.map((e) => e.id), [2, 3, 4, 1]);
    expect(moved.map((e) => e.supersetGroup), [1, 1, null, null]);
  });

  test('dragging top exercise from first superset to bottom in 4-exercise 2-superset setup', () {
    final moved = reorderRoutineExercise([
      exercise(1, 1),
      exercise(2, 1),
      exercise(3, 2),
      exercise(4, 2),
    ], 0, 3);

    expect(moved.map((e) => e.id), [2, 3, 4, 1]);
    expect(moved.map((e) => e.supersetGroup), [null, 2, 2, null]);
  });

  test('inserting an exercise strictly between members of a superset joins that superset', () {
    final moved = reorderRoutineExercise([
      exercise(1, null),
      exercise(2, 5),
      exercise(3, 5),
    ], 0, 1);

    expect(moved.map((e) => e.id), [2, 1, 3]);
    expect(moved.map((e) => e.supersetGroup), [5, 5, 5]);
  });

  test('dropping an exercise at the outer boundary of a superset does not join it', () {
    final moved = reorderRoutineExercise([
      exercise(1, null),
      exercise(2, 5),
      exercise(3, 5),
    ], 0, 2);

    expect(moved.map((e) => e.id), [2, 3, 1]);
    expect(moved.map((e) => e.supersetGroup), [5, 5, null]);
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
