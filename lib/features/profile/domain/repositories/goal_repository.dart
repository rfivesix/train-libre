// lib/features/profile/domain/repositories/goal_repository.dart

import '../models/goal_model.dart';
import '../models/goal_progress.dart';

abstract class IGoalRepository {
  /// Returns the single active goal, or null if no goal is currently active.
  Future<Goal?> getActiveGoal();

  /// Returns all retired and superseded goals for the history view.
  Future<List<Goal>> getRetiredGoals();

  /// Gets a goal by its unique ID.
  Future<Goal?> getGoalById(String id);

  /// Computes progress against the goal by checking the baseline observation
  /// (latest observation on or before startDate) and latest observation.
  Future<GoalProgress?> getGoalProgress(Goal goal);

  /// Creates a new goal. Ensures that only this goal is active.
  Future<Goal> createGoal({
    required GoalPreset preset,
    required String title,
    String? reason,
    required DateTime startDate,
    DateTime? targetDate,
    String? targetMetric,
    double? targetValue,
    String? targetUnit,
    double? desiredWeeklyRateKg,
    bool isNutritionDriver = true,
  });

  /// Supersedes an active goal with a new adjusted goal (3-variable change).
  Future<Goal> supersedeGoal({
    required Goal currentGoal,
    required double? targetValue,
    required DateTime? targetDate,
    required double? desiredWeeklyRateKg,
    String? reason,
  });

  /// Geordnet beendet / archiviert ein Ziel.
  Future<void> retireGoal(String goalId, {String? reason});

  /// Reaktiviert ein beendetes Ziel.
  Future<Goal> resumeGoal(String goalId);

  /// Löscht ein Ziel (nur für leere Entwürfe ohne Historie).
  Future<void> deleteDraftGoal(String goalId);

  /// Gets the pending goal review for the goal, if any.
  Future<GoalReviewRecord?> getPendingReview(String goalId);

  /// Saves a newly evaluated goal review.
  Future<void> saveReview(GoalReviewRecord review);

  /// Updates the status of a review (e.g. 'applied', 'dismissed', 'deferred').
  Future<void> updateReviewStatus(String reviewId, String status, {String? decision});

  /// Updates the target weekly rate of an active goal.
  Future<void> updateGoalWeeklyRate(String goalId, double weeklyRateKg);

  /// Gets the audit log events for a goal.
  Future<List<GoalEvent>> getGoalEvents(String goalId);
}
