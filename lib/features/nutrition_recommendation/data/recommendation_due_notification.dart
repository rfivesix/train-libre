import '../../../services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AdaptiveRecommendationNotificationPreference {
  Future<bool> isEnabled();
}

class SharedPreferencesAdaptiveRecommendationNotificationPreference
    implements AdaptiveRecommendationNotificationPreference {
  const SharedPreferencesAdaptiveRecommendationNotificationPreference();

  @override
  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance())
          .getBool('notify_adaptive_recommendation') ??
      true;
}

abstract interface class AdaptiveRecommendationDueNotifier {
  Future<void> notifyRecommendationDue({
    required String dueWeekKey,
    required DateTime dueAt,
  });
}

class NoopAdaptiveRecommendationDueNotifier
    implements AdaptiveRecommendationDueNotifier {
  const NoopAdaptiveRecommendationDueNotifier();

  @override
  Future<void> notifyRecommendationDue({
    required String dueWeekKey,
    required DateTime dueAt,
  }) async {}
}

class LocalAdaptiveRecommendationDueNotifier
    implements AdaptiveRecommendationDueNotifier {
  const LocalAdaptiveRecommendationDueNotifier();

  @override
  Future<void> notifyRecommendationDue({
    required String dueWeekKey,
    required DateTime dueAt,
  }) {
    return LocalNotificationService.instance
        .showAdaptiveRecommendationDueNotification();
  }
}
