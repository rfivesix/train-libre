import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/app_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../features/nutrition_recommendation/data/recommendation_repository.dart';
import '../features/nutrition_recommendation/domain/adaptive_recommendation_snapshot.dart';
import '../features/profile/data/goal_repository_impl.dart';
import '../features/profile/domain/models/goal_model.dart';
import 'notification_navigation.dart';

/// Handles local notification setup and rest timer notifications.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const int restTimerNotificationId = 8801;
  static const int adaptiveRecommendationDueNotificationId = 8802;
  static const int tdeeRecalculationNotificationId = 8803;
  static const int weeklyGoalReviewNotificationId = 8804;
  static const int goalTargetDateNotificationId = 8805;
  static const String _restChannelId = 'rest_timer_channel';
  static const String _adaptiveRecommendationChannelId =
      'adaptive_recommendation_channel';
  static const String _tdeeRecalculationChannelId =
      'tdee_recalculation_channel';
  static const String _weeklyGoalReviewChannelId = 'weekly_goal_review_channel';
  static const String _goalTargetDateChannelId = 'goal_target_date_channel';

  StreamSubscription<AdaptiveRecommendationSnapshot>? _tdeeSubscription;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  final StreamController<AppNotificationPayload> _notificationTapController =
      StreamController<AppNotificationPayload>.broadcast();
  AppNotificationPayload? _pendingNotificationTap;

  Stream<AppNotificationPayload> get notificationTaps =>
      _notificationTapController.stream;

  AppNotificationPayload? takePendingNotificationTap() {
    final value = _pendingNotificationTap;
    _pendingNotificationTap = null;
    return value;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings();
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _recordNotificationTap(
          launchDetails?.notificationResponse?.payload,
        );
      }
      await _requestPermissions();
      tz.initializeTimeZones();

      // Subscribe to TDEE updates stream!
      final repository = RecommendationRepository();
      _tdeeSubscription?.cancel();
      _tdeeSubscription = repository.onRecommendationUpdated.listen((snapshot) {
        showTdeeRecalculationNotification(
          calories: snapshot.recommendation.recommendedCalories,
          protein: snapshot.recommendation.recommendedProteinGrams,
          carbs: snapshot.recommendation.recommendedCarbsGrams,
          fat: snapshot.recommendation.recommendedFatGrams,
        );
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService failed to initialize: $e');
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    _recordNotificationTap(response.payload);
  }

  void _recordNotificationTap(String? rawPayload) {
    final payload = AppNotificationPayload.tryParse(rawPayload);
    if (payload == null) return;
    _pendingNotificationTap = payload;
    _notificationTapController.add(payload);
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails _restNotificationDetails(bool hapticsEnabled) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _restChannelId,
        'Rest Timer',
        channelDescription: 'Alerts when the workout rest timer is finished.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: hapticsEnabled,
      ),
      iOS: const DarwinNotificationDetails(
          presentAlert: true, presentSound: true),
      macOS: const DarwinNotificationDetails(
          presentAlert: true, presentSound: true),
    );
  }

  NotificationDetails _adaptiveRecommendationNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _adaptiveRecommendationChannelId,
        'Adaptive nutrition',
        channelDescription: 'Alerts when a new adaptive recommendation is due.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  ({String title, String body}) _localizedRestTexts() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);
    return (
      title: l10n.restTimerNotificationTitle,
      body: l10n.restTimerNotificationBody,
    );
  }

  ({String title, String body}) _localizedAdaptiveRecommendationDueTexts() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);
    return (
      title: l10n.adaptiveRecommendationDueNowShort,
      body: l10n.adaptiveRecommendationDueNowLine,
    );
  }

  Future<void> scheduleRestTimerDoneNotification({
    required int secondsFromNow,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;
    final texts = _localizedRestTexts();

    final prefs = await SharedPreferences.getInstance();
    final hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;

    final when = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: secondsFromNow.clamp(0, 24 * 60 * 60)));

    try {
      await _plugin.zonedSchedule(
        id: restTimerNotificationId,
        title: texts.title,
        body: texts.body,
        scheduledDate: when,
        notificationDetails: _restNotificationDetails(hapticsEnabled),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Fallback for devices that do not allow exact alarms.
      await _plugin.zonedSchedule(
        id: restTimerNotificationId,
        title: texts.title,
        body: texts.body,
        scheduledDate: when,
        notificationDetails: _restNotificationDetails(hapticsEnabled),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> showRestTimerDoneNotification({bool foreground = false}) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;
    final texts = _localizedRestTexts();

    final prefs = await SharedPreferences.getInstance();
    final hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;

    final details = foreground
        ? NotificationDetails(
            android: AndroidNotificationDetails(
              'rest_timer_foreground_v4',
              'Rest Timer (Foreground)',
              channelDescription:
                  'Alerts when the rest timer finishes while in the foreground.',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: hapticsEnabled,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: false,
              presentBanner: true,
              presentList: true,
            ),
            macOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: false,
            ),
          )
        : _restNotificationDetails(hapticsEnabled);

    await _plugin.show(
      id: restTimerNotificationId,
      title: texts.title,
      body: texts.body,
      notificationDetails: details,
    );

    if (foreground) {
      // Auto-cancel the notification after a short delay so it doesn't linger in the status bar/drawer
      Future.delayed(const Duration(seconds: 10), () async {
        try {
          await _plugin.cancel(id: restTimerNotificationId);
        } catch (_) {}
      });
    }
  }

  Future<void> cancelRestTimerNotification() async {
    if (!_isInitialized) return;
    await _plugin.cancel(id: restTimerNotificationId);
  }

  Future<void> showAdaptiveRecommendationDueNotification() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notify_adaptive_recommendation') ?? true)) return;
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;
    final texts = _localizedAdaptiveRecommendationDueTexts();
    final activeGoal = await GoalRepositoryImpl().getActiveGoal();

    await _plugin.show(
      id: adaptiveRecommendationDueNotificationId,
      title: texts.title,
      body: texts.body,
      notificationDetails: _adaptiveRecommendationNotificationDetails(),
      payload: AppNotificationPayload(
        type: AppNotificationType.adaptiveRecommendation,
        goalId: activeGoal?.id,
      ).encode(),
    );
  }

  NotificationDetails _tdeeRecalculationNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _tdeeRecalculationChannelId,
        'TDEE Recalculation',
        channelDescription:
            'Alerts when a new TDEE recalculation is completed.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  ({String title, String body}) _localizedTdeeRecalculationTexts({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);
    return (
      title: l10n.tdeeRecalculationNotificationTitle,
      body:
          l10n.tdeeRecalculationNotificationBody(calories, protein, carbs, fat),
    );
  }

  Future<void> showTdeeRecalculationNotification({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notify_adaptive_recommendation') ?? true)) return;
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;
    final texts = _localizedTdeeRecalculationTexts(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
    final activeGoal = await GoalRepositoryImpl().getActiveGoal();

    await _plugin.show(
      id: tdeeRecalculationNotificationId,
      title: texts.title,
      body: texts.body,
      notificationDetails: _tdeeRecalculationNotificationDetails(),
      payload: AppNotificationPayload(
        type: AppNotificationType.adaptiveRecommendation,
        goalId: activeGoal?.id,
      ).encode(),
    );
  }

  NotificationDetails _weeklyGoalReviewNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _weeklyGoalReviewChannelId,
        'Weekly Goal Review',
        channelDescription: 'Alerts when a weekly trajectory review is ready.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  Future<bool> showWeeklyGoalReviewNotification({
    required String goalId,
    required String reviewId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notify_weekly_goal_review') ?? true;
    if (!enabled) return false;

    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;

    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);

    try {
      await _plugin.show(
        id: notificationIdForReview(reviewId),
        title: l10n.weeklyGoalReviewNotificationTitle,
        body: l10n.weeklyGoalReviewNotificationBody,
        notificationDetails: _weeklyGoalReviewNotificationDetails(),
        payload: AppNotificationPayload(
          type: AppNotificationType.weeklyGoalReview,
          goalId: goalId,
          reviewId: reviewId,
        ).encode(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _goalTargetDateNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _goalTargetDateChannelId,
        'Goal Target Date',
        channelDescription:
            'Calm reminder when a goal target date approaches or is reached.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  Future<void> showGoalTargetDateReminderNotification({
    required String goalId,
    required String goalTitle,
    bool isDueToday = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notify_goal_target_date') ?? false;
    if (!enabled) return;

    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);

    await _plugin.show(
      id: notificationIdForGoalTargetDate(goalId, isDueToday: isDueToday),
      title: l10n.goalTargetDateReminderTitle,
      body: isDueToday
          ? l10n.goalTargetDateReachedBody(goalTitle)
          : l10n.goalTargetDateApproachingBody(goalTitle),
      notificationDetails: _goalTargetDateNotificationDetails(),
      payload: AppNotificationPayload(
        type: AppNotificationType.goalTargetDate,
        goalId: goalId,
      ).encode(),
    );
  }

  Future<bool> scheduleGoalTargetDateNotifications({
    required Goal goal,
  }) async {
    final targetDate = goal.targetDate;
    if (!goal.isActive || targetDate == null) {
      await cancelGoalTargetDateNotifications(goalId: goal.id);
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notify_goal_target_date') ?? false)) {
      await cancelGoalTargetDateNotifications(goalId: goal.id);
      return false;
    }
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;

    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);
    final payload = AppNotificationPayload(
      type: AppNotificationType.goalTargetDate,
      goalId: goal.id,
    ).encode();
    final targetDay =
        DateTime(targetDate.year, targetDate.month, targetDate.day);
    final reminders = <({DateTime when, bool dueToday})>[
      (when: targetDay.subtract(const Duration(days: 7)), dueToday: false),
      (when: targetDay, dueToday: true),
    ];
    var scheduled = false;
    for (final reminder in reminders) {
      final localWhen = DateTime(
        reminder.when.year,
        reminder.when.month,
        reminder.when.day,
        9,
      );
      final id = notificationIdForGoalTargetDate(
        goal.id,
        isDueToday: reminder.dueToday,
      );
      await _plugin.cancel(id: id);
      if (!localWhen.isAfter(DateTime.now())) continue;
      final when = tz.TZDateTime.from(localWhen.toUtc(), tz.local);
      try {
        await _scheduleGoalNotification(
          id: id,
          when: when,
          title: l10n.goalTargetDateReminderTitle,
          body: reminder.dueToday
              ? l10n.goalTargetDateReachedBody(goal.title)
              : l10n.goalTargetDateApproachingBody(goal.title),
          payload: payload,
        );
        scheduled = true;
      } catch (_) {
        // Permission denial and unsupported exact alarms must never prevent
        // goal/review persistence or app startup.
      }
    }
    return scheduled;
  }

  Future<void> _scheduleGoalNotification({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _goalTargetDateNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _goalTargetDateNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  Future<void> cancelGoalNotifications({required String goalId}) async {
    if (!_isInitialized) return;
    await cancelGoalTargetDateNotifications(goalId: goalId);
    try {
      final active = await _plugin.getActiveNotifications();
      for (final notification in active) {
        final id = notification.id;
        if (AppNotificationPayload.tryParse(notification.payload)?.goalId ==
                goalId &&
            id != null) {
          await _plugin.cancel(id: id);
        }
      }
    } catch (_) {
      // Active-notification enumeration is not implemented by every desktop
      // platform. Stable target-date IDs are still cancelled.
    }
  }

  Future<void> cancelGoalTargetDateNotifications({
    required String goalId,
  }) async {
    if (!_isInitialized) return;
    await _plugin.cancel(
      id: notificationIdForGoalTargetDate(goalId, isDueToday: false),
    );
    await _plugin.cancel(
      id: notificationIdForGoalTargetDate(goalId, isDueToday: true),
    );
    try {
      final scheduled = await _plugin.pendingNotificationRequests();
      for (final notification in scheduled) {
        final payload = AppNotificationPayload.tryParse(notification.payload);
        if (payload?.goalId == goalId &&
            payload?.type == AppNotificationType.goalTargetDate) {
          await _plugin.cancel(id: notification.id);
        }
      }
    } catch (_) {
      // Pending-request enumeration is not implemented by every platform.
    }
  }

  Future<void> cancelAdaptiveRecommendationNotifications() async {
    if (!_isInitialized) return;
    await _plugin.cancel(id: adaptiveRecommendationDueNotificationId);
    await _plugin.cancel(id: tdeeRecalculationNotificationId);
  }

  Future<void> cancelWeeklyReviewNotifications({required String goalId}) async {
    if (!_isInitialized) return;
    try {
      final active = await _plugin.getActiveNotifications();
      for (final notification in active) {
        final id = notification.id;
        final payload = AppNotificationPayload.tryParse(notification.payload);
        if (payload?.goalId == goalId &&
            payload?.type == AppNotificationType.weeklyGoalReview &&
            id != null) {
          await _plugin.cancel(id: id);
        }
      }
    } catch (_) {}
  }

  static int notificationIdForReview(String reviewId) =>
      100000000 + (_stableHash(reviewId) % 100000000);

  static int notificationIdForGoalTargetDate(
    String goalId, {
    required bool isDueToday,
  }) =>
      (isDueToday ? 300000000 : 200000000) + (_stableHash(goalId) % 100000000);

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
