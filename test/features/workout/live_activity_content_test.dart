import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/live_activity/build_workout_live_activity_content.dart';
import 'package:train_libre/features/workout/domain/live_activity/workout_live_activity_content.dart';
import 'package:train_libre/features/workout/domain/live_activity/workout_live_activity_strings.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/services/unit_service.dart';

const _strings = WorkoutLiveActivityStrings(
  setPosition: _setPosition,
  weightUnit: 'kg',
  distanceUnit: 'km',
  repsShort: 'Wdh',
  rirLabel: 'RIR',
  rpeLabel: 'RPE',
  addExercise: 'Übung hinzufügen',
  openApp: 'App öffnen',
  skip: 'Skip',
  overduePrefix: 'überfällig seit',
  restDoneTitle: 'Pause beendet',
  restDoneBody: 'Weiter geht es.',
);

String _setPosition(int index, int total) => 'Satz $index von $total';

Exercise _exercise({required String name, required String category}) =>
    Exercise(
      id: 1,
      nameDe: name,
      nameEn: name,
      descriptionDe: '',
      descriptionEn: '',
      categoryName: category,
      primaryMuscles: const [],
      secondaryMuscles: const [],
    );

SetLog _log({
  required String exerciseName,
  String setType = 'normal',
  bool completed = false,
  double? weightKg,
  int? reps,
  int? rir,
  double? distanceKm,
  int? durationSeconds,
  int? rpe,
}) =>
    SetLog(
      workoutLogId: 1,
      exerciseName: exerciseName,
      setType: setType,
      isCompleted: completed,
      weightKg: weightKg,
      reps: reps,
      rir: rir,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      rpe: rpe,
    );

WorkoutLiveActivityContent _build({
  required List<RoutineExercise> exercises,
  required Map<int, SetLog> setLogs,
  DateTime? restEndsAt,
  DateTime? restStartedAt,
  UnitService? unitService,
}) =>
    buildWorkoutLiveActivityContent(
      exercises: exercises,
      setLogs: setLogs,
      unitService: unitService ?? UnitService(),
      strings: _strings,
      localeName: 'de',
      restEndsAt: restEndsAt,
      restStartedAt: restStartedAt,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // UnitService reads the stored unit system on construction.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final strengthExercise = RoutineExercise(
    id: 10,
    exercise: _exercise(name: 'Bankdrücken', category: 'Strength'),
    pauseSeconds: 140,
    setTemplates: [
      SetTemplate(
        id: 101,
        setType: 'warmup',
        targetReps: '8',
        targetWeight: 72.5,
        targetRir: 2,
      ),
      SetTemplate(id: 102, setType: 'normal', targetReps: '8'),
    ],
  );

  group('S1 — set pending', () {
    test('formats the metrics line and the set-type badge', () {
      final content = _build(
        exercises: [strengthExercise],
        setLogs: {
          101: _log(exerciseName: 'Bankdrücken', setType: 'warmup'),
          102: _log(exerciseName: 'Bankdrücken'),
        },
      );

      expect(content.phase, WorkoutLiveActivityPhase.setPending);
      expect(content.exerciseName, 'Bankdrücken');
      expect(content.setPosition, 'Satz 1 von 2');
      expect(content.badgeText, 'W');
      expect(content.badgeColorHex, '#FF9800');
      expect(content.metricPrimary, '72,5 kg');
      expect(content.metricSecondary, '8 Wdh');
      expect(content.metricTertiary, '(RIR 2)');
      expect(content.metricSeparator, '×');
      expect(content.canCompleteSet, isTrue);
    });

    test('a set without weight or reps cannot be completed', () {
      final bare = RoutineExercise(
        id: 30,
        exercise: _exercise(name: 'Klimmzug', category: 'Strength'),
        pauseSeconds: 90,
        setTemplates: [SetTemplate(id: 301, setType: 'normal')],
      );
      final content = _build(
        exercises: [bare],
        setLogs: {301: _log(exerciseName: 'Klimmzug')},
      );

      expect(content.canCompleteSet, isFalse);
      // No invented numbers — the gaps are shown as dashes.
      expect(content.metricPrimary, '–');
      expect(content.metricSecondary, '–');
    });

    test('weight without reps is still incomplete', () {
      final partial = RoutineExercise(
        id: 31,
        exercise: _exercise(name: 'Klimmzug', category: 'Strength'),
        pauseSeconds: 90,
        setTemplates: [
          SetTemplate(id: 311, setType: 'normal', targetWeight: 40),
        ],
      );
      final content = _build(
        exercises: [partial],
        setLogs: {311: _log(exerciseName: 'Klimmzug')},
      );

      expect(content.canCompleteSet, isFalse);
      expect(content.metricPrimary, '40 kg');
      expect(content.metricSecondary, '–');
    });

    test('normal sets carry N, since the position is already spelled out', () {
      final content = _build(
        exercises: [strengthExercise],
        setLogs: {
          101: _log(
            exerciseName: 'Bankdrücken',
            setType: 'warmup',
            completed: true,
          ),
          102: _log(exerciseName: 'Bankdrücken'),
        },
      );

      expect(content.setPosition, 'Satz 2 von 2');
      expect(content.badgeText, 'N');
      expect(content.badgeColorHex, '#8E8E93');
    });

    test('compact zones stay short enough for the Dynamic Island', () {
      final content = _build(
        exercises: [strengthExercise],
        setLogs: {
          101: _log(exerciseName: 'Bankdrücken', setType: 'warmup'),
          102: _log(exerciseName: 'Bankdrücken'),
        },
      );

      expect(content.compactPrimary, '72,5 kg');
      expect(content.compactSecondary, '× 8');
    });
  });

  group('S2 — resting', () {
    test('is resting while the rest end lies in the future', () {
      final now = DateTime(2026, 8, 9, 18, 0);
      final content = _build(
        exercises: [strengthExercise],
        setLogs: {
          101: _log(exerciseName: 'Bankdrücken', setType: 'warmup'),
          102: _log(exerciseName: 'Bankdrücken'),
        },
        restStartedAt: now.subtract(const Duration(seconds: 20)),
        restEndsAt: now.add(const Duration(seconds: 120)),
      );

      expect(content.phase, WorkoutLiveActivityPhase.resting);
      expect(content.restEndsAt, isNotNull);
      expect(content.restStartedAt, isNotNull);
    });

    test('keeps the rest end after it has passed, so iOS can show S3', () {
      // The overdue state is derived on the iOS side by comparing restEndsAt
      // to the current time. Dropping back to setPending here would erase it.
      final now = DateTime(2026, 8, 9, 18, 0);
      final restEnd = now.subtract(const Duration(seconds: 5));
      final content = _build(
        exercises: [strengthExercise],
        setLogs: {
          101: _log(exerciseName: 'Bankdrücken', setType: 'warmup'),
          102: _log(exerciseName: 'Bankdrücken'),
        },
        restEndsAt: restEnd,
      );

      expect(content.phase, WorkoutLiveActivityPhase.resting);
      expect(content.restEndsAt, restEnd);
    });

    test('reports setPending only when the rest was cancelled or skipped', () {
      final content = _build(
        exercises: [strengthExercise],
        setLogs: {
          101: _log(exerciseName: 'Bankdrücken', setType: 'warmup'),
          102: _log(exerciseName: 'Bankdrücken'),
        },
      );

      expect(content.phase, WorkoutLiveActivityPhase.setPending);
      expect(content.restEndsAt, isNull);
    });
  });

  group('S4 / S5', () {
    test('reports noSetsLeft when every set is completed', () {
      final content = _build(
        exercises: [strengthExercise],
        setLogs: {
          101: _log(
            exerciseName: 'Bankdrücken',
            setType: 'warmup',
            completed: true,
          ),
          102: _log(exerciseName: 'Bankdrücken', completed: true),
        },
      );

      expect(content.phase, WorkoutLiveActivityPhase.noSetsLeft);
    });

    test('reports empty when the workout has no exercises', () {
      final content = _build(exercises: const [], setLogs: const {});
      expect(content.phase, WorkoutLiveActivityPhase.empty);
    });
  });

  group('Cardio', () {
    final cardioExercise = RoutineExercise(
      id: 20,
      exercise: _exercise(name: 'Laufband', category: 'Cardio'),
      pauseSeconds: 0,
      setTemplates: [SetTemplate(id: 201, setType: 'normal')],
    );

    test('uses the duration/distance slots and drops the badge', () {
      final content = _build(
        exercises: [cardioExercise],
        setLogs: {
          201: _log(
            exerciseName: 'Laufband',
            durationSeconds: 1200,
            distanceKm: 5,
            rpe: 7,
          ),
        },
      );

      expect(content.badgeText, isEmpty);
      expect(content.metricPrimary, '20:00');
      expect(content.metricSecondary, '5 km');
      expect(content.metricTertiary, '(RPE 7)');
      expect(content.metricSeparator, '·');
      expect(content.canCompleteSet, isTrue);
    });

    test('shrinks the line from the left when only a distance exists', () {
      final content = _build(
        exercises: [cardioExercise],
        setLogs: {201: _log(exerciseName: 'Laufband', distanceKm: 5)},
      );

      expect(content.metricPrimary, '5 km');
      expect(content.metricSecondary, isEmpty);
      expect(content.metricTertiary, isEmpty);
    });

    test('a fresh cardio set carries no planned values', () {
      // SetTemplate has no duration/distance targets — documented gap.
      final content = _build(
        exercises: [cardioExercise],
        setLogs: {201: _log(exerciseName: 'Laufband')},
      );

      expect(content.phase, WorkoutLiveActivityPhase.setPending);
      expect(content.exerciseName, 'Laufband');
      expect(content.metricPrimary, '–');
      expect(content.canCompleteSet, isFalse);
    });
  });
}
