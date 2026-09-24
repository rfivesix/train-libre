import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/local_notification_service.dart';
import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';
import 'weekly_goal_review_orchestrator.dart';

abstract interface class GoalNotificationPreferences {
  Future<bool> weeklyReviewEnabled();
  Future<bool> targetDateEnabled();
  Future<bool> wasReviewNotified(String reviewId);
  Future<void> markReviewNotified(String reviewId);
}

class SharedPreferencesGoalNotificationPreferences
    implements GoalNotificationPreferences {
  static const _reviewPrefix = 'goal_notification.review.';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  Future<bool> weeklyReviewEnabled() async =>
      (await _prefs()).getBool('notify_weekly_goal_review') ?? true;

  @override
  Future<bool> targetDateEnabled() async =>
      (await _prefs()).getBool('notify_goal_target_date') ?? false;

  @override
  Future<bool> wasReviewNotified(String reviewId) async =>
      (await _prefs()).getBool('$_reviewPrefix$reviewId') ?? false;

  @override
  Future<void> markReviewNotified(String reviewId) async {
    await (await _prefs()).setBool('$_reviewPrefix$reviewId', true);
  }
}

abstract interface class GoalNotificationScheduler {
  Future<bool> showWeeklyReview({
    required Goal goal,
    required GoalReviewRecord review,
  });
  Future<bool> scheduleTargetDate({required Goal goal});
  Future<void> cancelTargetDate(String goalId);
  Future<void> cancelForGoal(String goalId);
}

class LocalGoalNotificationScheduler implements GoalNotificationScheduler {
  final LocalNotificationService _service;

  LocalGoalNotificationScheduler({LocalNotificationService? service})
      : _service = service ?? LocalNotificationService.instance;

  @override
  Future<bool> showWeeklyReview({
    required Goal goal,
    required GoalReviewRecord review,
  }) =>
      _service.showWeeklyGoalReviewNotification(
        goalId: goal.id,
        reviewId: review.id,
        goalTitle: goal.title,
        recommendedCalories: review.recommendedCalories,
      );

  @override
  Future<bool> scheduleTargetDate({required Goal goal}) =>
      _service.scheduleGoalTargetDateNotifications(goal: goal);

  @override
  Future<void> cancelTargetDate(String goalId) =>
      _service.cancelGoalTargetDateNotifications(goalId: goalId);

  @override
  Future<void> cancelForGoal(String goalId) =>
      _service.cancelGoalNotifications(goalId: goalId);
}

class GoalNotificationOrchestrator {
  final IGoalRepository _goalRepository;
  final WeeklyGoalReviewOrchestrator _reviewOrchestrator;
  final GoalNotificationScheduler _scheduler;
  final GoalNotificationPreferences _preferences;

  GoalNotificationOrchestrator({
    required IGoalRepository goalRepository,
    WeeklyGoalReviewOrchestrator? reviewOrchestrator,
    GoalNotificationScheduler? scheduler,
    GoalNotificationPreferences? preferences,
  })  : _goalRepository = goalRepository,
        _reviewOrchestrator = reviewOrchestrator ??
            WeeklyGoalReviewOrchestrator(goalRepository: goalRepository),
        _scheduler = scheduler ?? LocalGoalNotificationScheduler(),
        _preferences =
            preferences ?? SharedPreferencesGoalNotificationPreferences();

  /// Safe to call at startup, on refresh and from background execution.
  Future<WeeklyGoalReviewGenerationResult> synchronize({DateTime? now}) async {
    final inactiveGoals = await _goalRepository.getRetiredGoals();
    for (final inactiveGoal in inactiveGoals) {
      await _scheduler.cancelForGoal(inactiveGoal.id);
    }
    final result = await _reviewOrchestrator.generateIfDue(now: now);
    final goal = result.goal;
    if (goal == null) return result;

    if (await _preferences.targetDateEnabled()) {
      await _scheduler.scheduleTargetDate(goal: goal);
    } else {
      await _scheduler.cancelTargetDate(goal.id);
    }

    final review = result.review;
    if (review != null &&
        review.status == 'pending' &&
        !await _preferences.wasReviewNotified(review.id)) {
      if (await _preferences.weeklyReviewEnabled()) {
        await _scheduler.showWeeklyReview(
          goal: goal,
          review: review,
        );
      }
      // Disabled settings and denied permissions both consume the due event,
      // so switching notifications on later only affects future reviews.
      await _preferences.markReviewNotified(review.id);
    }
    return result;
  }

  Future<void> goalBecameInactive(String goalId) async {
    await _goalRepository.closePendingReviews(goalId);
    await _scheduler.cancelForGoal(goalId);
  }
}
