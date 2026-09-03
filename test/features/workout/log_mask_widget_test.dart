import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/classification/exercise_log_mask.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/presentation/widgets/workout_log_set_row.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

/// What each exercise actually renders.
///
/// C3 derived the mask correctly in the model and wired it into nothing: the
/// getters existed, no screen read them, and a plank kept a repetitions column
/// while a pull-up kept an empty weight field. A data-layer test cannot see
/// that. This one can.
Exercise _exercise({String? trackingType, String? loadMode}) => Exercise(
      texts: const {'en': ExerciseText(name: 'Test')},
      categoryName: 'Abs',
      primaryMuscles: const [],
      secondaryMuscles: const [],
      trackingType: trackingType,
      loadMode: loadMode,
    );

SetLog _setLog() => SetLog(
      id: 1,
      workoutLogId: 1,
      exerciseName: 'Test',
      setType: 'normal',
      weightKg: 40,
      reps: 8,
      durationSeconds: 45,
      distanceKm: 2.5,
      isCompleted: true,
      logOrder: 0,
    );

Future<void> _pumpRow(WidgetTester tester, ExerciseLogMask mask) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<UnitService>(
        create: (_) => UnitService(),
        child: Scaffold(
          body: WorkoutLogSetRow(
            setLog: _setLog(),
            rowIndex: 0,
            workingSetIndex: 1,
            exerciseName: 'Test',
            isEditMode: false,
            mask: mask,
            weightController: TextEditingController(),
            repsController: TextEditingController(),
            rirController: TextEditingController(),
            onDelete: () {},
            onSetTypeTap: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ExerciseLogMask derivation', () {
    test('weight_reps shows weight and reps', () {
      final mask =
          ExerciseLogMask.forExercise(_exercise(trackingType: 'weight_reps'));
      expect(mask.primary, LogField.weight);
      expect(mask.secondary, LogField.reps);
    });

    test('bodyweight_reps shows an added-weight column, not a weight one', () {
      final mask = ExerciseLogMask.forExercise(
          _exercise(trackingType: 'bodyweight_reps'));
      expect(mask.primary, LogField.addedWeight);
      expect(mask.secondary, LogField.reps);
      expect(mask.showsPrimary, isTrue,
          reason: 'the column stays, so a belt can be entered');
    });

    test('time shows a duration and nothing else', () {
      final mask = ExerciseLogMask.forExercise(_exercise(trackingType: 'time'));
      expect(mask.primary, LogField.none);
      expect(mask.secondary, LogField.duration);
      expect(mask.showsPrimary, isFalse);
    });

    test('time_weight keeps a weight column alongside the duration', () {
      final mask =
          ExerciseLogMask.forExercise(_exercise(trackingType: 'time_weight'));
      expect(mask.primary, LogField.weight);
      expect(mask.secondary, LogField.duration);
    });

    test('distance_only shows a distance and no second column', () {
      final mask =
          ExerciseLogMask.forExercise(_exercise(trackingType: 'distance_only'));
      expect(mask.primary, LogField.distance);
      expect(mask.secondary, LogField.none);
    });

    test('an assistance machine labels its column as assistance', () {
      final mask = ExerciseLogMask.forExercise(
        _exercise(trackingType: 'weight_reps', loadMode: 'assisted'),
      );
      expect(mask.primary, LogField.assistance,
          reason: 'the number is a reduction, and the column has to say so');
    });

    test('an unclassified exercise falls back to weight and reps', () {
      expect(ExerciseLogMask.forExercise(_exercise()),
          ExerciseLogMask.weightAndReps);
      expect(ExerciseLogMask.forExercise(null), ExerciseLogMask.weightAndReps);
    });
  });

  group('what the set row renders', () {
    testWidgets('a time exercise has no repetitions column', (tester) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'time')),
      );

      // 45 seconds, not 8 reps.
      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('8'), findsNothing,
          reason: 'a plank was showing a repetitions column');
      // And no weight either.
      expect(find.text('40 kg'), findsNothing);
    });

    testWidgets('a weight_reps exercise shows both numbers', (tester) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'weight_reps')),
      );

      expect(find.text('8'), findsOneWidget);
      expect(find.text('00:45'), findsNothing);
    });

    testWidgets('a bodyweight exercise keeps its repetitions column',
        (tester) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'bodyweight_reps')),
      );

      expect(find.text('8'), findsOneWidget);
      expect(find.text('00:45'), findsNothing);
    });

    testWidgets('a distance_time exercise shows distance and duration',
        (tester) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'distance_time')),
      );

      expect(find.text('2.5'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('8'), findsNothing);
    });

    testWidgets('a distance_only exercise has no second column',
        (tester) async {
      await _pumpRow(
        tester,
        ExerciseLogMask.forExercise(_exercise(trackingType: 'distance_only')),
      );

      expect(find.text('2.5'), findsOneWidget);
      expect(find.text('00:45'), findsNothing);
      expect(find.text('8'), findsNothing);
    });
  });
}
