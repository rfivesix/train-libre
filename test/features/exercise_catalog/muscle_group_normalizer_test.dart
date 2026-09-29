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
        '',
        '  ',
        'Quadriceps',
        'QUADRICEPS',
      ]),
      ['Back', 'Biceps', 'Quadriceps'],
    );
  });
}
