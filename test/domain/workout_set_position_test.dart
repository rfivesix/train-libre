import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/classification/workout_set_position.dart';

void main() {
  group('WorkoutSetPositionMapper', () {
    test('an added warm-up never shifts working-set history', () {
      const previous = ['warmup', 'normal', 'failure'];
      const current = ['warmup', 'warmup', 'normal', 'failure'];

      expect(
        WorkoutSetPositionMapper.matchingPreviousIndex(
          currentSetTypes: current,
          currentIndex: 2,
          previousSetTypes: previous,
        ),
        equals(1),
      );
      expect(
        WorkoutSetPositionMapper.matchingPreviousIndex(
          currentSetTypes: current,
          currentIndex: 3,
          previousSetTypes: previous,
        ),
        equals(2),
      );
    });

    test('drop sets have their own sequence and do not shift working sets', () {
      const previous = ['normal', 'dropset', 'failure'];
      const current = ['normal', 'dropset', 'dropset', 'failure'];

      expect(
        WorkoutSetPositionMapper.matchingPreviousIndex(
          currentSetTypes: current,
          currentIndex: 3,
          previousSetTypes: previous,
        ),
        equals(2),
      );
      expect(
        WorkoutSetPositionMapper.positionAt(current, 2).lane,
        equals(WorkoutSetLane.dropset),
      );
    });
  });
}
