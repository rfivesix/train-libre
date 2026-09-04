import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/classification/exercise_log_mask.dart';
import 'package:train_libre/features/workout/domain/detect_personal_record_use_case.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/services/unit_service.dart';

/// Personal records on exercises that log no weight, or log it backwards.
///
/// All three strength records used to sit behind `currentWeight > 0` — did the
/// user type a number into the weight column. A pull-up at body weight leaves
/// that column empty, so it could never set a record however many reps it
/// gained. An assisted pull-up does fill it, with a number that means its
/// opposite: the easiest set of the session read as a weight record, which is
/// exactly what the screenshot showed.
Exercise _exercise({
  required String trackingType,
  required String loadMode,
}) =>
    Exercise(
      texts: const {'en': ExerciseText(name: 'Test')},
      categoryName: 'Back',
      primaryMuscles: const [],
      secondaryMuscles: const [],
      trackingType: trackingType,
      loadMode: loadMode,
    );

final _barbell =
    _exercise(trackingType: 'weight_reps', loadMode: 'external');
final _pullUp =
    _exercise(trackingType: 'bodyweight_reps', loadMode: 'bodyweight');
final _assisted =
    _exercise(trackingType: 'bodyweight_reps', loadMode: 'assisted');

SetLog _set({double? weightKg, int? reps}) => SetLog(
      id: 1,
      workoutLogId: 1,
      exerciseName: 'Test',
      setType: 'normal',
      weightKg: weightKg,
      reps: reps,
      isCompleted: true,
      logOrder: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UnitService unitService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    unitService = UnitService();
    await unitService.reload();
  });

  PRDetectionResult run(
    Exercise exercise, {
    double? weightKg,
    required int reps,
    required Map<String, double> bests,
    double? bodyweightKg = 90,
  }) =>
      DetectPersonalRecordUseCase().execute(
        currentSet: _set(weightKg: weightKg, reps: reps),
        historicalBests: bests,
        unitService: unitService,
        mask: ExerciseLogMask.forExercise(exercise),
        bodyweightKg: bodyweightKg,
      );

  group('body weight is a load', () {
    test('a pull-up with an empty weight column can set records', () {
      // 90 kg of user, 10 reps, against a history of 8 reps at the same body
      // weight. Nothing was typed into the weight column at all.
      final result = run(
        _pullUp,
        weightKg: null,
        reps: 10,
        bests: {'maxWeight': 0, 'maxVolume': 720, 'maxEst1rm': 110},
      );

      expect(result.updatedSetLog.isMaxVolumePR, isTrue,
          reason: '900 kg of volume did not beat 720');
      expect(result.updatedSetLog.isMaxEst1RMPR, isTrue);
      expect(
        result.alerts.map((a) => a.recordType),
        containsAll(['Best Volume Set', 'Best 1-Rep Max']),
      );
    });

    test('and does not claim a weight record it has no number for', () {
      final result = run(
        _pullUp,
        weightKg: null,
        reps: 10,
        bests: {'maxWeight': 0, 'maxVolume': 0, 'maxEst1rm': 0},
      );
      expect(result.updatedSetLog.isMaxWeightPR, isFalse);
    });
  });

  group('assistance is not load', () {
    test('more assistance is not a weight record', () {
      // The screenshot: set two took 10 kg of help, which is the easier set,
      // and was celebrated as a personal best.
      final result = run(
        _assisted,
        weightKg: 10,
        reps: 10,
        bests: {'maxWeight': 5, 'maxVolume': 0, 'maxEst1rm': 0},
      );
      expect(result.updatedSetLog.isMaxWeightPR, isFalse);
      expect(
        result.alerts.map((a) => a.recordType),
        isNot(contains('Best Max Weight')),
      );
    });

    test('the unassisted set still outranks the assisted one', () {
      // Same session, same exercise: 0 kg of help beats 10 kg of help.
      final unassisted = run(
        _assisted,
        weightKg: 0,
        reps: 10,
        bests: {'maxWeight': 0, 'maxVolume': 0, 'maxEst1rm': 1},
      );
      final assisted = run(
        _assisted,
        weightKg: 10,
        reps: 10,
        bests: {'maxWeight': 0, 'maxVolume': 0, 'maxEst1rm': 1},
      );

      expect(unassisted.updatedSetLog.est1rmPRDiff, isNotNull);
      expect(assisted.updatedSetLog.est1rmPRDiff, isNotNull);
      expect(
        unassisted.updatedSetLog.est1rmPRDiff!,
        greaterThan(assisted.updatedSetLog.est1rmPRDiff!),
      );
    });
  });

  group('a loaded barbell is unchanged', () {
    test('all three records still fire', () {
      final result = run(
        _barbell,
        weightKg: 100,
        reps: 5,
        bests: {'maxWeight': 90, 'maxVolume': 450, 'maxEst1rm': 100},
      );
      expect(
        result.alerts.map((a) => a.recordType),
        containsAll(
            ['Best Max Weight', 'Best Volume Set', 'Best 1-Rep Max']),
      );
    });

    test('an isolation lift is not treated differently', () {
      // Briefly it was: the estimated-1RM alert was withheld on single-joint
      // work. Records belong to every exercise.
      final curl = Exercise(
        texts: const {'en': ExerciseText(name: 'Curl')},
        categoryName: 'Arms',
        primaryMuscles: const [],
        secondaryMuscles: const [],
        trackingType: 'weight_reps',
        loadMode: 'external',
        mechanic: 'isolation',
      );
      final result = run(
        curl,
        weightKg: 20,
        reps: 8,
        bests: {'maxWeight': 15, 'maxVolume': 100, 'maxEst1rm': 18},
      );
      expect(
        result.alerts.map((a) => a.recordType),
        contains('Best 1-Rep Max'),
      );
    });
  });

  group('the intensity column', () {
    test('is offered where there are reps, and on cardio', () {
      expect(ExerciseLogMask.forExercise(_barbell).showsIntensity, isTrue);
      expect(ExerciseLogMask.forExercise(_pullUp).showsIntensity, isTrue);
      expect(
        ExerciseLogMask.forExercise(
          _exercise(trackingType: 'distance_time', loadMode: 'bodyweight'),
        ).showsIntensity,
        isTrue,
      );
    });

    test('is absent on a plank, which has no reps to hold in reserve', () {
      expect(
        ExerciseLogMask.forExercise(
          _exercise(trackingType: 'time', loadMode: 'bodyweight'),
        ).showsIntensity,
        isFalse,
      );
      expect(
        ExerciseLogMask.forExercise(
          _exercise(trackingType: 'time_weight', loadMode: 'external'),
        ).showsIntensity,
        isFalse,
      );
    });
  });
}
