import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/exercise_catalog/domain/muscle_group_normalizer.dart';

void main() {
  test('deduplicates casing and whitespace while retaining the first label',
      () {
    expect(
      deduplicateMuscleGroups([
        'Back',
        ' back ',
        'Biceps',
        'biceps',
        'Upper Back',
        'upper_back',
        '',
        '  ',
        'Quadriceps',
        'QUADRICEPS',
      ]),
      ['Back', 'Biceps', 'Upper Back', 'Quadriceps'],
    );
  });

  test('coarsens precise names into one selectable beginner group', () {
    expect(
      coarsenMuscleGroups([
        'Back',
        'lats',
        'Upper Back',
        'traps',
        'Biceps',
        'biceps_long',
        'Quadriceps',
        'quads',
      ]),
      ['back', 'biceps', 'quads'],
    );
  });

  test('keeps the precise catalog muscle name for pro labels', () {
    expect(preciseMuscleLabel('upper_back'), 'Upper Back');
    expect(preciseMuscleLabel('biceps_long'), 'Biceps Long');
  });
}
