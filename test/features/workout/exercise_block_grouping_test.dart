import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/models/exercise_block_key.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';

void main() {
  SetLog set(String name, {int? block, int? id}) => SetLog(
        id: id,
        workoutLogId: 1,
        exerciseName: name,
        setType: 'normal',
        exerciseBlock: block,
      );

  test('same exercise in distinct modern blocks creates distinct cards', () {
    final groups = groupSetsByExerciseBlock([
      set('Row', block: 0, id: 1),
      set('Squat', block: 1, id: 2),
      set('Row', block: 2, id: 3),
    ]);

    expect(groups.length, 3);
    expect(groups.keys.map((key) => key.exerciseBlock), [0, 1, 2]);
    expect(groups.values.map((sets) => sets.single.id), [1, 2, 3]);
  });

  test('legacy rows without a block retain name-based grouping', () {
    final groups = groupSetsByExerciseBlock([
      set('Row', id: 1),
      set('Squat', id: 2),
      set('Row', id: 3),
    ]);

    expect(groups.length, 2);
    expect(groups.values.first.map((set) => set.id), [1, 3]);
  });
}
