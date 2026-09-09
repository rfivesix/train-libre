import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/domain/progression/double_progression_engine.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/features/workout/domain/services/workout_progression_service.dart';
import 'package:train_libre/services/unit_service.dart';

class _FakeWorkoutRepository implements IWorkoutRepository {
  List<SetLog> historySets = [];

  @override
  Future<List<SetLog>> getLastSetsForExercise({
    String? exerciseId,
    String? exerciseNameSnapshot,
  }) async {
    return historySets;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 7, 12, 0);

  late _FakeWorkoutRepository fakeRepo;
  late UnitService unitService;
  late WorkoutProgressionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    fakeRepo = _FakeWorkoutRepository();
    unitService = UnitService();
    await unitService.setUnitSystem(UnitSystem.metric);
    service = WorkoutProgressionService(
      repository: fakeRepo,
      unitService: unitService,
    );
  });

  Exercise createTestExercise({
    String? equipment = 'barbell',
    String? loadMode = 'external',
    String? trackingType = 'weight_reps',
  }) {
    return Exercise.single(
      uuid: 'ex-123',
      languageCode: 'en',
      name: 'Bench Press',
      categoryName: 'Chest',
      primaryMuscles: ['Chest'],
      secondaryMuscles: ['Triceps'],
      trackingType: trackingType,
      loadMode: loadMode,
      primaryEquipment: equipment,
    );
  }

  SetTemplate createTestTemplate({
    double? targetWeight,
    int? targetRepMin = 8,
    int? targetRepMax = 12,
    String? targetReps,
    String setType = 'normal',
  }) {
    return SetTemplate(
      id: 1,
      setType: setType,
      targetWeight: targetWeight,
      targetRepMin: targetRepMin,
      targetRepMax: targetRepMax,
      targetReps: targetReps,
    );
  }

  SetLog createTestSetLog({
    required int id,
    required int workoutLogId,
    required double? weightKg,
    required int? reps,
    required DateTime performedAt,
    String setType = 'normal',
    bool isCompleted = true,
  }) {
    return SetLog(
      id: id,
      workoutLogId: workoutLogId,
      exerciseId: 'ex-123',
      exerciseName: 'Bench Press',
      setType: setType,
      weightKg: weightKg,
      reps: reps,
      isCompleted: isCompleted,
      performedAt: performedAt,
    );
  }

  group('WorkoutProgressionService', () {
    test('history remains the first-set source when a routine has a seed load',
        () async {
      fakeRepo.historySets = [
        createTestSetLog(
          id: 1,
          workoutLogId: 10,
          weightKg: 80.0,
          reps: 12,
          performedAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final exercise = createTestExercise();
      final templateWithExplicitWeight = createTestTemplate(targetWeight: 85.0);

      final result = await service.getProgressionSuggestion(
        exercise: exercise,
        template: templateWithExplicitWeight,
        now: now,
      );

      expect(result?.targetWeight, 82.5);
      expect(result?.targetReps, 8);
    });

    test('metric-specific tracking types never enter load-rep progression',
        () async {
      fakeRepo.historySets = [
        createTestSetLog(
          id: 1,
          workoutLogId: 10,
          weightKg: 80,
          reps: 12,
          performedAt: now.subtract(const Duration(days: 2)),
        ),
      ];
      final template = createTestTemplate();

      for (final trackingType in [
        'time',
        'time_weight',
        'distance_time',
        'distance_only',
      ]) {
        final exercise = createTestExercise(trackingType: trackingType);
        expect(
          await service.getProgressionSuggestion(
            exercise: exercise,
            template: template,
            now: now,
          ),
          isNull,
          reason: trackingType,
        );
        expect(
          await service.getProgressionSuggestions(
            exercise: exercise,
            workingTemplates: [template],
            now: now,
          ),
          isEmpty,
          reason: trackingType,
        );
      }

      final variable = createTestExercise(loadMode: 'variable');
      expect(
        await service.getProgressionSuggestion(
          exercise: variable,
          template: template,
          now: now,
        ),
        isNull,
      );
      expect(
        await service.getProgressionSuggestions(
          exercise: variable,
          workingTemplates: [template],
          now: now,
        ),
        isEmpty,
      );
    });

    test('Translates SetLogs and raises load when topped out', () async {
      final date = now.subtract(const Duration(days: 2));
      fakeRepo.historySets = [
        createTestSetLog(
          id: 1,
          workoutLogId: 10,
          weightKg: 80.0,
          reps: 12,
          performedAt: date,
        ),
        createTestSetLog(
          id: 2,
          workoutLogId: 10,
          weightKg: 80.0,
          reps: 12,
          performedAt: date,
        ),
      ];

      final exercise = createTestExercise(equipment: 'barbell');
      final template = createTestTemplate(targetRepMin: 8, targetRepMax: 12);

      final result = await service.getProgressionSuggestion(
        exercise: exercise,
        template: template,
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(82.5));
      expect(result.targetReps, equals(8));
      expect(result.reason, equals(ProgressionReason.rangeToppedOut));
    });

    test(
        'Two workouts on the same calendar day are treated as two distinct sessions via sessionId',
        () async {
      // Both workouts happened on the same calendar day (e.g. morning and afternoon)
      final sameDayMorning = DateTime(2026, 9, 5, 9, 0);
      final sameDayAfternoon = DateTime(2026, 9, 5, 16, 0);

      // In the morning workout (workoutLogId: 101), only 10 reps were done (not topped out)
      // In the afternoon workout (workoutLogId: 102), 12 reps were done (topped out)
      fakeRepo.historySets = [
        createTestSetLog(
          id: 1,
          workoutLogId: 101,
          weightKg: 80.0,
          reps: 10,
          performedAt: sameDayMorning,
        ),
        createTestSetLog(
          id: 2,
          workoutLogId: 102,
          weightKg: 80.0,
          reps: 12,
          performedAt: sameDayAfternoon,
        ),
      ];

      final exercise = createTestExercise(equipment: 'barbell');
      final template = createTestTemplate(targetRepMin: 8, targetRepMax: 12);

      final result = await service.getProgressionSuggestion(
        exercise: exercise,
        template: template,
        now: now,
      );

      // The latest session is workoutLogId 102 (topped out with 12 reps).
      // Because sessionId keeps them distinct, 102 is evaluated on its own without
      // being contaminated by the morning set of workout 101.
      expect(result, isNotNull);
      expect(result!.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(82.5));
      expect(result.targetReps, equals(8));
    });

    test('Equipment increment table handles dumbbells (2.0kg)', () async {
      final date = now.subtract(const Duration(days: 2));
      fakeRepo.historySets = [
        createTestSetLog(
          id: 1,
          workoutLogId: 10,
          weightKg: 20.0,
          reps: 12,
          performedAt: date,
        ),
      ];

      final exercise = createTestExercise(equipment: 'dumbbell');
      final template = createTestTemplate(targetRepMin: 8, targetRepMax: 12);

      final result = await service.getProgressionSuggestion(
        exercise: exercise,
        template: template,
        now: now,
      );

      expect(result, isNotNull);
      expect(result!.outcome, equals(ProgressionOutcome.raise));
      expect(result.targetWeight, equals(22.0)); // 20.0 + 2.0 kg
    });

    test('recalculates a later set from today while preserving its back-off',
        () async {
      final date = now.subtract(const Duration(days: 2));
      fakeRepo.historySets = [
        createTestSetLog(
          id: 1,
          workoutLogId: 10,
          weightKg: 35,
          reps: 8,
          performedAt: date,
        ).copyWith(logOrder: 1),
        createTestSetLog(
          id: 2,
          workoutLogId: 10,
          weightKg: 30,
          reps: 12,
          performedAt: date,
        ).copyWith(logOrder: 2),
      ];
      final templates = [
        createTestTemplate(),
        createTestTemplate().copyWith(id: 2),
      ];
      final currentSets = [
        createTestSetLog(
          id: 11,
          workoutLogId: 99,
          weightKg: 40,
          reps: 8,
          performedAt: now,
        ),
        createTestSetLog(
          id: 12,
          workoutLogId: 99,
          weightKg: null,
          reps: null,
          performedAt: now,
          isCompleted: false,
        ),
      ];

      final result = await service.getInWorkoutSuggestion(
        exercise: createTestExercise(),
        workingTemplates: templates,
        currentWorkingSets: currentSets,
        targetTemplateId: 2,
        currentWorkoutLogId: 99,
      );

      expect(result?.targetWeight, equals(37.5));
      expect(result?.targetReps, equals(8));
      expect(result?.reason,
          equals(ProgressionReason.inWorkoutProjectedBelowRange));
    });

    test('uses today\'s preceding working set when a position has no history',
        () async {
      fakeRepo.historySets = [];
      final templates = [
        createTestTemplate(),
        createTestTemplate().copyWith(id: 2),
      ];
      final currentSets = [
        createTestSetLog(
          id: 11,
          workoutLogId: 99,
          weightKg: 40,
          reps: 9,
          performedAt: now,
        ),
        createTestSetLog(
          id: 12,
          workoutLogId: 99,
          weightKg: null,
          reps: null,
          performedAt: now,
          isCompleted: false,
        ),
      ];

      final result = await service.getInWorkoutSuggestion(
        exercise: createTestExercise(),
        workingTemplates: templates,
        currentWorkingSets: currentSets,
        targetTemplateId: 2,
        currentWorkoutLogId: 99,
      );

      expect(result?.targetWeight, equals(37.5));
      expect(result?.targetReps, equals(8));
      expect(result?.reason,
          equals(ProgressionReason.inWorkoutProjectedBelowRange));
    });
  });
}
