import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/classification/exercise_log_mask.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/presentation/widgets/log_mask_labels.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

/// Column headings and the "last time" cell, which followed the input fields
/// nowhere: a plank had a column headed "Reps" over a duration picker and a
/// history reading "0kg × 0".
Exercise _exercise({String? trackingType, String? loadMode}) => Exercise(
      texts: const {'en': ExerciseText(name: 'Test')},
      categoryName: 'Abs',
      primaryMuscles: const [],
      secondaryMuscles: const [],
      trackingType: trackingType,
      loadMode: loadMode,
    );

SetLog _set({double? weightKg, int? reps, int? durationSeconds, double? km}) =>
    SetLog(
      id: 1,
      workoutLogId: 1,
      exerciseName: 'Test',
      setType: 'normal',
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      distanceKm: km,
      isCompleted: true,
      logOrder: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;
  late UnitService unitService;

  setUpAll(() async {
    // Pinned to metric: these tests are about which numbers appear and in
    // what shape, not about the unit conversion, and the default follows the
    // host locale.
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    unitService = UnitService();
    await unitService.reload();
  });

  String? primary(String? trackingType, {String? loadMode}) =>
      LogMaskLabels.primaryHeader(
        ExerciseLogMask.forExercise(
            _exercise(trackingType: trackingType, loadMode: loadMode)),
        l10n,
        unitService,
      );

  String? secondary(String? trackingType) => LogMaskLabels.secondaryHeader(
        ExerciseLogMask.forExercise(_exercise(trackingType: trackingType)),
        l10n,
      );

  String last(String? trackingType, SetLog? setLog, {String? loadMode}) =>
      LogMaskLabels.lastPerformance(
        ExerciseLogMask.forExercise(
            _exercise(trackingType: trackingType, loadMode: loadMode)),
        setLog,
        l10n,
        unitService,
      );

  group('column headings', () {
    test('weight_reps is kg over reps', () {
      expect(primary('weight_reps'), 'kg');
      expect(secondary('weight_reps'), l10n.repsLabel);
    });

    test('bodyweight_reps marks its column as added weight', () {
      expect(primary('bodyweight_reps'), '+kg');
      expect(secondary('bodyweight_reps'), l10n.repsLabel);
    });

    test('an assistance machine marks its column as a subtraction', () {
      expect(primary('weight_reps', loadMode: 'assisted'), '−kg');
    });

    test('a time exercise has a duration heading and no reps column', () {
      expect(primary('time'), isNull);
      expect(secondary('time'), l10n.cardioTimeLabel);
      expect(secondary('time'), isNot(l10n.repsLabel));
    });

    test('time_weight keeps a weight heading beside the duration', () {
      expect(primary('time_weight'), 'kg');
      expect(secondary('time_weight'), l10n.cardioTimeLabel);
    });

    test('distance_time heads both columns', () {
      expect(primary('distance_time'), contains('Distance'));
      expect(secondary('distance_time'), l10n.cardioTimeLabel);
    });

    test('distance_only has no second column', () {
      expect(primary('distance_only'), contains('Distance'));
      expect(secondary('distance_only'), isNull);
    });
  });

  group('last time', () {
    test('a lift reads as weight times reps', () {
      expect(last('weight_reps', _set(weightKg: 70, reps: 6)), '70 kg × 6');
    });

    test('a body-weight set with a belt keeps the plus sign', () {
      // The sign is not decoration: losing it is what let assistance be read
      // as load in the first place.
      expect(
        last('bodyweight_reps', _set(weightKg: 10, reps: 10)),
        '+10 kg × 10',
      );
    });

    test('a body-weight set without a belt says reps, not zero kilograms', () {
      expect(last('bodyweight_reps', _set(reps: 10)), '10 ${l10n.repsLabel}');
    });

    test('a timed set is a duration, with no kg and no multiplication sign',
        () {
      final text = last('time', _set(durationSeconds: 120));
      expect(text, '02:00');
      expect(text, isNot(contains('kg')));
      expect(text, isNot(contains('×')));
    });

    test('a run reads as distance and duration, joined by a dot', () {
      final text =
          last('distance_time', _set(km: 5, durationSeconds: 28 * 60 + 14));
      expect(text, contains('5.0'));
      expect(text, contains('28:14'));
      expect(text, contains('·'));
      expect(text, isNot(contains('×')),
          reason: 'distance and time do not multiply');
    });

    test('an assisted set shows the assistance as a subtraction', () {
      expect(
        last('weight_reps', _set(weightKg: 20, reps: 8), loadMode: 'assisted'),
        '−20 kg × 8',
      );
    });

    test('no last set at all is a dash', () {
      expect(last('weight_reps', null), '-');
      expect(last('time', null), '-');
    });

    test('a set with nothing recorded is a dash, not "0kg × 0"', () {
      // The rendered bug.
      expect(last('time', _set()), '-');
      expect(last('weight_reps', _set()), '-');
    });
  });
}
