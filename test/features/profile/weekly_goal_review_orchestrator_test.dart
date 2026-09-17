import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';
import 'package:train_libre/features/profile/domain/services/weekly_goal_review_orchestrator.dart';

class _InputSource implements WeeklyGoalReviewInputSource {
  final WeeklyGoalReviewInput value;
  int calls = 0;

  _InputSource(this.value);

  @override
  Future<WeeklyGoalReviewInput> load({required DateTime windowEnd}) async {
    calls++;
    return value;
  }
}

void main() {
  late AppDatabase database;
  late GoalRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = GoalRepositoryImpl(database: database);
  });

  tearDown(() => database.close());

  Future<Goal> createGoal() => repository.createGoal(
        preset: GoalPreset.loseWeight,
        title: 'Test',
        startDate: DateTime(2026, 1, 1),
        baselineValueKg: 80,
        baselineDate: DateTime(2026, 1, 1),
        targetDate: DateTime(2026, 4, 1),
        targetMetric: 'weight',
        targetValue: 75,
        targetUnit: 'kg',
        desiredWeeklyRateKg: -0.5,
      );

  test('persists one calibrating review for an insufficient completed window',
      () async {
    final goal = await createGoal();
    final source = _InputSource(const WeeklyGoalReviewInput(
      weightObservationCount: 2,
      loggedIntakeDaysCount: 3,
      observedRateKgPerWeek: null,
      tdeeEstimate: null,
      currentCalories: 2000,
      recommendation: null,
    ));
    final service = WeeklyGoalReviewOrchestrator(
      goalRepository: repository,
      inputSource: source,
    );

    final first = await service.generateIfDue(now: DateTime(2026, 1, 8));
    final second = await service.generateIfDue(now: DateTime(2026, 1, 10));

    expect(first.wasCreated, isTrue);
    expect(first.review?.trajectoryStatus, 'calibrating');
    expect(first.review?.status, 'pending');
    expect(second.review?.id, first.review?.id);
    expect(source.calls, 1);
    expect(await database.select(database.goalReviews).get(), hasLength(1));
    expect((await repository.getPendingReview(goal.id))?.id, first.review?.id);
  });

  test('uses existing thresholds and persists a sufficient slower review',
      () async {
    await createGoal();
    await database.into(database.measurements).insert(
          MeasurementsCompanion.insert(
            type: 'weight',
            value: 80,
            unit: 'kg',
            date: DateTime(2026, 1, 1),
          ),
        );
    final source = _InputSource(const WeeklyGoalReviewInput(
      weightObservationCount: 3,
      loggedIntakeDaysCount: 4,
      observedRateKgPerWeek: -0.2,
      operatingRateKgPerWeek: -0.2,
      currentSmoothedWeightKg: 80.5,
      averageLoggedCalories: 2000,
      tdeeEstimate: 2300,
      currentCalories: 2000,
      recommendation: null,
    ));

    final result = await WeeklyGoalReviewOrchestrator(
      goalRepository: repository,
      inputSource: source,
    ).generateIfDue(now: DateTime(2026, 1, 8));

    expect(result.review?.trajectoryStatus, 'slower');
    expect(result.review?.assessment?.overallStatus, 'behind');
    expect(result.review?.confidenceLevel, 'low');
  });

  test('a backdated goal creates only the current scheduler window', () async {
    final goal = await createGoal();
    final source = _InputSource(const WeeklyGoalReviewInput(
      weightObservationCount: 0,
      loggedIntakeDaysCount: 0,
      observedRateKgPerWeek: null,
      tdeeEstimate: null,
      currentCalories: null,
      recommendation: null,
    ));
    final service = WeeklyGoalReviewOrchestrator(
      goalRepository: repository,
      inputSource: source,
    );

    await service.generateIfDue(now: DateTime(2026, 1, 22));
    await service.generateIfDue(now: DateTime(2026, 1, 22));

    final reviews = await database.select(database.goalReviews).get();
    expect(reviews, hasLength(1));
    expect(reviews.where((review) => review.status == 'pending'), hasLength(1));
    expect((await repository.getPendingReview(goal.id))?.windowStart,
        DateTime(2026, 1, 15));
    expect(source.calls, 1);
  });

  test('a new week defers the previous pending review', () async {
    final goal = await createGoal();
    final source = _InputSource(const WeeklyGoalReviewInput(
      weightObservationCount: 0,
      loggedIntakeDaysCount: 0,
      observedRateKgPerWeek: null,
      tdeeEstimate: null,
      currentCalories: null,
      recommendation: null,
    ));
    final service = WeeklyGoalReviewOrchestrator(
      goalRepository: repository,
      inputSource: source,
    );

    final first = await service.generateIfDue(now: DateTime(2026, 1, 8));
    final second = await service.generateIfDue(now: DateTime(2026, 1, 15));

    expect(
      (await repository.getReviewById(first.review!.id))!.status,
      'deferred',
    );
    expect(second.review!.status, 'pending');
    expect(
      (await repository.getPendingReview(goal.id))!.id,
      second.review!.id,
    );
  });

  test('revising a plan preserves goal identity, start, and baseline',
      () async {
    final goal = await createGoal();
    await database.into(database.measurements).insert(
          MeasurementsCompanion.insert(
            type: 'weight',
            value: 80,
            unit: 'kg',
            date: DateTime(2026, 1, 1),
          ),
        );
    final before = await repository.getGoalProgress(goal);

    final revised = await repository.reviseGoal(
      currentGoal: goal,
      targetValue: 74,
      targetDate: DateTime(2026, 5, 1),
      desiredWeeklyRateKg: -0.35,
      reason: 'Review adjustment',
    );
    final after = await repository.getGoalProgress(revised);

    expect(revised.id, goal.id);
    expect(revised.startDate, goal.startDate);
    expect(revised.targetValue, 74);
    expect(before!.baselineValue, 80);
    expect(after!.baselineValue, before.baselineValue);
    expect(
      (await repository.getGoalEvents(goal.id))
          .where((event) => event.eventType == 'plan_revised'),
      hasLength(1),
    );
  });

  test('status transitions and goal retirement remove pending review',
      () async {
    final goal = await createGoal();
    final source = _InputSource(const WeeklyGoalReviewInput(
      weightObservationCount: 0,
      loggedIntakeDaysCount: 0,
      observedRateKgPerWeek: null,
      tdeeEstimate: null,
      currentCalories: null,
      recommendation: null,
    ));
    final result = await WeeklyGoalReviewOrchestrator(
      goalRepository: repository,
      inputSource: source,
    ).generateIfDue(now: DateTime(2026, 1, 8));

    await repository.updateReviewStatus(result.review!.id, 'deferred');
    expect(await repository.getPendingReview(goal.id), isNull);

    await repository.updateReviewStatus(result.review!.id, 'pending');
    await repository.retireGoal(goal.id);
    expect(await repository.getPendingReview(goal.id), isNull);
    expect((await repository.getReviewById(result.review!.id))?.status,
        'goal_changed');
  });

  test('a resumed goal starts a new seven-day review anchor', () async {
    final goal = await createGoal();
    await repository.retireGoal(goal.id);
    await repository.resumeGoal(goal.id);
    final source = _InputSource(const WeeklyGoalReviewInput(
      weightObservationCount: 0,
      loggedIntakeDaysCount: 0,
      observedRateKgPerWeek: null,
      tdeeEstimate: null,
      currentCalories: null,
      recommendation: null,
    ));

    final result = await WeeklyGoalReviewOrchestrator(
      goalRepository: repository,
      inputSource: source,
    ).generateIfDue(now: DateTime.now().add(const Duration(days: 6)));

    expect(result.review, isNull);
  });
}
