import 'dart:convert';

import '../features/profile/domain/models/goal_model.dart';
import '../features/profile/domain/repositories/goal_repository.dart';

enum AppNotificationType {
  weeklyGoalReview,
  goalTargetDate,
  adaptiveRecommendation,
  workoutPlan,
}

class AppNotificationPayload {
  final AppNotificationType type;
  final String? goalId;
  final String? reviewId;
  final String? planId;

  const AppNotificationPayload({
    required this.type,
    this.goalId,
    this.reviewId,
    this.planId,
  });

  String encode() => jsonEncode({
        'v': 1,
        'type': type.name,
        if (goalId != null) 'goalId': goalId,
        if (reviewId != null) 'reviewId': reviewId,
        if (planId != null) 'planId': planId,
      });

  static AppNotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      final type = AppNotificationType.values
          .where((value) => value.name == map['type'])
          .firstOrNull;
      if (type == null) return null;
      return AppNotificationPayload(
        type: type,
        goalId: map['goalId'] as String?,
        reviewId: map['reviewId'] as String?,
        planId: map['planId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

sealed class NotificationDestination {
  const NotificationDestination();
}

class NutritionHubNotificationDestination extends NotificationDestination {
  const NutritionHubNotificationDestination();
}

class WorkoutPlanNotificationDestination extends NotificationDestination {
  const WorkoutPlanNotificationDestination();
}

class GoalDetailNotificationDestination extends NotificationDestination {
  final Goal goal;
  const GoalDetailNotificationDestination(this.goal);
}

class WeeklyReviewNotificationDestination extends NotificationDestination {
  final Goal goal;
  final GoalReviewRecord review;
  const WeeklyReviewNotificationDestination(this.goal, this.review);
}

/// Resolves plugin-independent payload data into a safe application target.
class AppNotificationRouter {
  final IGoalRepository _goalRepository;

  const AppNotificationRouter(this._goalRepository);

  Future<NotificationDestination> resolve(
    AppNotificationPayload? payload,
  ) async {
    if (payload?.type == AppNotificationType.workoutPlan) {
      return const WorkoutPlanNotificationDestination();
    }
    if (payload == null ||
        payload.type == AppNotificationType.adaptiveRecommendation) {
      return const NutritionHubNotificationDestination();
    }

    final goalId = payload.goalId;
    if (goalId == null) return const NutritionHubNotificationDestination();
    final goal = await _goalRepository.getGoalById(goalId);
    if (goal == null) return const NutritionHubNotificationDestination();

    if (payload.type == AppNotificationType.weeklyGoalReview &&
        goal.isActive &&
        payload.reviewId != null) {
      final review = await _goalRepository.getReviewById(payload.reviewId!);
      if (review != null &&
          review.goalId == goal.id &&
          review.status == 'pending') {
        return WeeklyReviewNotificationDestination(goal, review);
      }
    }
    return GoalDetailNotificationDestination(goal);
  }
}
