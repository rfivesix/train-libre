import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/classification/exercise_log_mask.dart';
import 'package:train_libre/features/workout/presentation/widgets/log_mask_labels.dart';
import 'package:train_libre/services/experience_level_service.dart';

/// Who gets the third column, and who keeps an empty one.
///
/// The placeholder only earns its space while the cards around it show the
/// column. Below "pro" none of them do, and a plank that kept it had its time
/// sitting out of line with every other row on screen.
ExerciseLogMask _mask({required String trackingType}) =>
    ExerciseLogMask.forExercise(
      Exercise(
        texts: const {'en': ExerciseText(name: 'Test')},
        categoryName: 'Abs',
        primaryMuscles: const [],
        secondaryMuscles: const [],
        trackingType: trackingType,
      ),
    );

Future<({bool shows, bool placeholder})> _column(
  WidgetTester tester, {
  required ExerciseLogMask mask,
  required ExperienceLevel level,
}) async {
  final service = ExperienceLevelService();
  await service.setLevel(level);
  late bool shows;
  late bool placeholder;
  await tester.pumpWidget(
    ChangeNotifierProvider<ExperienceLevelService>.value(
      value: service,
      child: Builder(
        builder: (context) {
          shows = showsIntensityColumn(context, mask);
          placeholder = keepsIntensityPlaceholder(context, mask);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return (shows: shows, placeholder: placeholder);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('pro: a lift shows RIR, a plank holds its place', (tester) async {
    expect(
      await _column(
        tester,
        mask: _mask(trackingType: 'weight_reps'),
        level: ExperienceLevel.pro,
      ),
      (shows: true, placeholder: false),
    );
    expect(
      await _column(
        tester,
        mask: _mask(trackingType: 'time'),
        level: ExperienceLevel.pro,
      ),
      (shows: false, placeholder: true),
    );
  });

  testWidgets('below pro nobody keeps the column, placeholder included',
      (tester) async {
    for (final trackingType in ['weight_reps', 'time', 'distance_time']) {
      expect(
        await _column(
          tester,
          mask: _mask(trackingType: trackingType),
          level: ExperienceLevel.beginner,
        ),
        (shows: false, placeholder: false),
        reason: '$trackingType keeps a column below pro',
      );
    }
  });
}
