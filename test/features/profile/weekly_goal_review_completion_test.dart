// test/features/profile/weekly_goal_review_completion_test.dart

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart'
    hide WorkoutLog, SetLog, Routine, Exercise;
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/recommendation_models.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';
import 'package:train_libre/features/profile/presentation/weekly_goal_review_screen.dart';
import 'package:train_libre/features/workout/domain/classification/set_load.dart';
import 'package:train_libre/features/workout/domain/models/routine.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/unit_service.dart';

class _FakeWorkoutRepository implements IWorkoutRepository {
  @override
  Future<BodyweightHistory> getBodyweightHistory() async =>
      BodyweightHistory.empty;
  @override
  Future<WorkoutLog?> getOngoingWorkout() async => null;
  @override
  Future<int> insertSetLog(SetLog log) async => 0;
  @override
  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async => [];
  @override
  Future<Routine?> getRoutineByName(String name) async => null;
  @override
  Future<Exercise?> resolveExerciseForSetLog(SetLog log) async => null;
  @override
  Future<Exercise?> getExerciseByName(String name) async => null;
  @override
  Future<String?> getExerciseUuidByLocalId(int localId) async => null;
  @override
  Future<Map<String, double>> getExerciseBests(String exerciseName,
          {String? altName, String? exerciseUuid}) async =>
      {};
  @override
  Future<void> updateSetLogs(List<SetLog> logs) async {}
  @override
  Future<void> deleteSetLogs(List<int> ids) async {}
  @override
  Future<void> finishWorkout(int logId, {String? title, String? notes}) async {}
  @override
  Future<void> updatePauseTime(int routineExerciseId, int? seconds) async {}
  @override
  Future<void> updateRoutineExerciseNotes(
      int routineExerciseId, String? notes) async {}
  @override
  Future<void> saveWorkoutExerciseNote({
    required int workoutLogId,
    required String exerciseName,
    required String? notes,
  }) async {}
  @override
  Future<Map<String, String>> getWorkoutExerciseNotes(int workoutLogId) async =>
      {};
  @override
  Future<List<SetLog>> getLastSetsForExercise({
    required String? exerciseId,
    required String exerciseNameSnapshot,
  }) async =>
      [];
  @override
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
          DateTime start, DateTime end) async =>
      [];
  @override
  Stream<List<WorkoutLog>> watchFullWorkoutLogs() => const Stream.empty();
  @override
  Stream<List<SetLog>> watchSetLogsForWorkout(int workoutLogId) =>
      const Stream.empty();
  @override
  Stream<List<Routine>> watchAllRoutines() => const Stream.empty();
  @override
  Stream<List<WorkoutLog>> watchWorkoutLogsForDateRange(
          DateTime start, DateTime end) =>
      Stream.value([]);
  @override
  Future<Routine?> getRoutineByUuid(String uuid) async => null;
  @override
  Future<void> syncRoutineWithWorkout({
    required String routineUuid,
    required int workoutLogId,
  }) async {}
  @override
  Future<Routine> createRoutineFromWorkout({
    required int workoutLogId,
    required String name,
  }) async =>
      Routine(id: 1, name: name);
  @override
  Future<void> updateWorkoutLogPhotos(int logId, List<String> paths) async {}
}

class _MockRecommendationService
    extends AdaptiveNutritionRecommendationService {
  int recalculateAndApplyCalls = 0;
  final NutritionRecommendation? resultToReturn;

  _MockRecommendationService({this.resultToReturn});

  @override
  Future<NutritionRecommendation?> recalculateAndApply({DateTime? now}) async {
    recalculateAndApplyCalls++;
    return resultToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late GoalRepositoryImpl repository;
  late Goal testGoal;
  late GoalReviewRecord testReview;
  late NutritionRecommendation dummyRecommendation;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(database);
    repository = GoalRepositoryImpl(database: database);

    testGoal = await repository.createGoal(
      baselineValueKg: 80,
      baselineDate: DateTime(2026, 1, 1),
      preset: GoalPreset.loseWeight,
      title: 'Abnehmen',
      startDate: DateTime(2026, 1, 1),
      targetDate: DateTime(2026, 6, 1),
      targetMetric: 'weight',
      targetValue: 75.0,
      targetUnit: 'kg',
      desiredWeeklyRateKg: -0.5,
    );

    testReview = GoalReviewRecord(
      id: 'review-test-1',
      goalId: testGoal.id,
      windowStart: DateTime(2026, 1, 1),
      windowEnd: DateTime(2026, 1, 7),
      status: 'pending',
      trajectoryStatus: 'on_track',
      recommendedCalories: 2100,
      recommendedProtein: 160,
      recommendedCarbs: 210,
      recommendedFat: 65,
      algorithmVersion: 'weekly_goal_review_2_0',
      createdAt: DateTime(2026, 1, 8),
    );

    dummyRecommendation = NutritionRecommendation(
      recommendedCalories: 2100,
      recommendedProteinGrams: 160,
      recommendedCarbsGrams: 210,
      recommendedFatGrams: 65,
      estimatedMaintenanceCalories: 2600,
      goal: BodyweightGoal.loseWeight,
      targetRateKgPerWeek: -0.5,
      confidence: RecommendationConfidence.medium,
      warningState: RecommendationWarningState.none,
      generatedAt: DateTime.now(),
      windowStart: DateTime.now().subtract(const Duration(days: 7)),
      windowEnd: DateTime.now(),
      algorithmVersion: 'test',
      inputSummary: const RecommendationInputSummary(
        windowDays: 7,
        weightLogCount: 5,
        intakeLoggedDays: 7,
        smoothedWeightSlopeKgPerWeek: -0.5,
        avgLoggedCalories: 2100,
      ),
      baselineCalories: 2600,
      dueWeekKey: '2026-W02',
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget createTestWidget({
    required Widget child,
  }) {
    final unitService = UnitService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: unitService),
        ChangeNotifierProvider.value(
          value: LiveWorkoutViewModel(
            repository: _FakeWorkoutRepository(),
            unitService: unitService,
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: child,
      ),
    );
  }

  testWidgets(
      'WeeklyGoalReviewScreen triggers recalculateAndApply when user keeps current goals',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockService =
        _MockRecommendationService(resultToReturn: dummyRecommendation);

    await tester.pumpWidget(
      createTestWidget(
        child: WeeklyGoalReviewScreen(
          goal: testGoal,
          review: testReview,
          repository: repository,
          recommendationService: mockService,
        ),
      ),
    );

    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final keepCurrentButton =
        find.text('Ziel beibehalten und Tagesziele aktualisieren');
    expect(keepCurrentButton, findsOneWidget);

    await tester.tap(keepCurrentButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Ziel beibehalten und Tagesziele aktualisieren?'),
      findsOneWidget,
    );
    await tester.tap(
      find.text('Ziel beibehalten und Tagesziele aktualisieren').last,
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(mockService.recalculateAndApplyCalls, 1);
  });

  testWidgets(
      'WeeklyGoalReviewScreen triggers recalculateAndApply when user applies recommendation',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockService =
        _MockRecommendationService(resultToReturn: dummyRecommendation);

    await tester.pumpWidget(
      createTestWidget(
        child: WeeklyGoalReviewScreen(
          goal: testGoal,
          review: testReview,
          repository: repository,
          recommendationService: mockService,
        ),
      ),
    );

    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Find the "Empfohlene Tageswerte übernehmen" button
    final applyButton = find.text('Empfohlene Tageswerte übernehmen');
    expect(applyButton, findsOneWidget);

    await tester.tap(applyButton);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(mockService.recalculateAndApplyCalls, 1);
  });
}
