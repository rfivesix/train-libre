import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';
import 'package:train_libre/features/profile/domain/services/goal_notification_orchestrator.dart';
import 'package:train_libre/features/profile/domain/services/weekly_goal_review_orchestrator.dart';

class _Preferences implements GoalNotificationPreferences {
  bool weekly = true;
  bool target = true;
  final notified = <String>{};

  @override
  Future<void> markReviewNotified(String reviewId) async =>
      notified.add(reviewId);
  @override
  Future<bool> targetDateEnabled() async => target;
  @override
  Future<bool> wasReviewNotified(String reviewId) async =>
      notified.contains(reviewId);
  @override
  Future<bool> weeklyReviewEnabled() async => weekly;
}

class _Scheduler implements GoalNotificationScheduler {
  int reviewCalls = 0;
  int targetCalls = 0;
  int targetCancellations = 0;
  final cancelledGoals = <String>[];
  bool deliverySucceeds = true;

  @override
  Future<void> cancelForGoal(String goalId) async => cancelledGoals.add(goalId);
  @override
  Future<void> cancelTargetDate(String goalId) async => targetCancellations++;
  @override
  Future<bool> scheduleTargetDate({required Goal goal}) async {
    targetCalls++;
    return deliverySucceeds;
  }

  @override
  Future<bool> showWeeklyReview({
    required Goal goal,
    required GoalReviewRecord review,
  }) async {
    reviewCalls++;
    return deliverySucceeds;
  }
}

class _InputSource implements WeeklyGoalReviewInputSource {
  @override
  Future<WeeklyGoalReviewInput> load({required DateTime windowEnd}) async =>
      const WeeklyGoalReviewInput(
        weightObservationCount: 1,
        loggedIntakeDaysCount: 1,
        observedRateKgPerWeek: null,
        tdeeEstimate: null,
        currentCalories: 2000,
        recommendation: null,
      );
}

void main() {
  test('settings, deduplication and permission-free fallback are respected',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = GoalRepositoryImpl(database: database);
    await repository.createGoal(
      preset: GoalPreset.loseWeight,
      title: 'Test',
      startDate: DateTime(2026, 1, 1),
      targetDate: DateTime(2026, 3, 1),
      desiredWeeklyRateKg: -0.5,
    );
    final preferences = _Preferences();
    final scheduler = _Scheduler()..deliverySucceeds = false;
    final orchestrator = GoalNotificationOrchestrator(
      goalRepository: repository,
      reviewOrchestrator: WeeklyGoalReviewOrchestrator(
        goalRepository: repository,
        inputSource: _InputSource(),
      ),
      scheduler: scheduler,
      preferences: preferences,
    );

    final first = await orchestrator.synchronize(now: DateTime(2026, 1, 8));
    await orchestrator.synchronize(now: DateTime(2026, 1, 9));

    expect(first.review, isNotNull);
    expect(scheduler.reviewCalls, 1);
    expect(scheduler.targetCalls, 2);
    expect(preferences.notified, contains(first.review!.id));

    preferences.target = false;
    preferences.weekly = false;
    await orchestrator.synchronize(now: DateTime(2026, 1, 9));
    expect(scheduler.reviewCalls, 1);
    expect(scheduler.targetCancellations, 1);
  });

  test('retirement closes reviews and cancels goal notifications', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = GoalRepositoryImpl(database: database);
    final goal = await repository.createGoal(
      preset: GoalPreset.maintainWeight,
      title: 'Test',
      startDate: DateTime(2026, 1, 1),
    );
    final scheduler = _Scheduler();
    final orchestrator = GoalNotificationOrchestrator(
      goalRepository: repository,
      reviewOrchestrator: WeeklyGoalReviewOrchestrator(
        goalRepository: repository,
        inputSource: _InputSource(),
      ),
      scheduler: scheduler,
      preferences: _Preferences(),
    );
    await orchestrator.synchronize(now: DateTime(2026, 1, 8));
    await orchestrator.goalBecameInactive(goal.id);

    expect(await repository.getPendingReview(goal.id), isNull);
    expect(scheduler.cancelledGoals, [goal.id]);
  });
}
