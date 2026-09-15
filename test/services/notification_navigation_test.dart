import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';
import 'package:train_libre/services/notification_navigation.dart';
import 'package:train_libre/services/local_notification_service.dart';

void main() {
  test('payload round-trips and rejects unknown input', () {
    const payload = AppNotificationPayload(
      type: AppNotificationType.weeklyGoalReview,
      goalId: 'goal-1',
      reviewId: 'review-1',
    );
    final parsed = AppNotificationPayload.tryParse(payload.encode());
    expect(parsed?.type, AppNotificationType.weeklyGoalReview);
    expect(parsed?.goalId, 'goal-1');
    expect(parsed?.reviewId, 'review-1');
    expect(AppNotificationPayload.tryParse('{"type":"obsolete"}'), isNull);
    expect(AppNotificationPayload.tryParse('not-json'), isNull);
  });

  test('notification IDs are stable and separated by reminder kind', () {
    expect(
      LocalNotificationService.notificationIdForReview('review-1'),
      LocalNotificationService.notificationIdForReview('review-1'),
    );
    expect(
      LocalNotificationService.notificationIdForGoalTargetDate(
        'goal-1',
        isDueToday: false,
      ),
      isNot(LocalNotificationService.notificationIdForGoalTargetDate(
        'goal-1',
        isDueToday: true,
      )),
    );
    expect(
      LocalNotificationService.notificationIdForGoalTargetDate(
        'goal-1',
        isDueToday: false,
      ),
      isNot(LocalNotificationService.notificationIdForGoalTargetDate(
        'goal-2',
        isDueToday: false,
      )),
    );
  });

  test('routes open review, settled review, and deleted IDs safely', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = GoalRepositoryImpl(database: database);
    final goal = await repository.createGoal(
      preset: GoalPreset.maintainWeight,
      title: 'Maintain',
      startDate: DateTime(2026, 1, 1),
    );
    final review = GoalReviewRecord(
      id: 'review-1',
      goalId: goal.id,
      windowStart: DateTime(2026, 1, 1),
      windowEnd: DateTime(2026, 1, 7, 23, 59, 59, 999),
      algorithmVersion: 'test',
      createdAt: DateTime(2026, 1, 8),
    );
    await repository.saveReview(review);
    final router = AppNotificationRouter(repository);
    final payload = AppNotificationPayload(
      type: AppNotificationType.weeklyGoalReview,
      goalId: goal.id,
      reviewId: review.id,
    );

    expect(await router.resolve(payload),
        isA<WeeklyReviewNotificationDestination>());
    await repository.updateReviewStatus(review.id, 'dismissed');
    expect(await router.resolve(payload),
        isA<GoalDetailNotificationDestination>());
    expect(
      await router.resolve(const AppNotificationPayload(
        type: AppNotificationType.goalTargetDate,
        goalId: 'deleted',
      )),
      isA<NutritionHubNotificationDestination>(),
    );
  });
}
