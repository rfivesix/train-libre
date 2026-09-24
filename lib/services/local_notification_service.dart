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
import '../features/workout/domain/workout_plan_notification_scheduler.dart';

/// Handles local notification setup and rest timer notifications.
class LocalNotificationService implements WorkoutPlanNotificationScheduler {
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
  static const String _workoutPlanChannelId = 'workout_plan_channel';

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

  Future<bool> requestNotificationPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macOs = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    final macOsGranted = await macOs?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidGranted ?? iosGranted ?? macOsGranted ?? true;
  }

  Future<bool?> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled();
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled;
    }
    final macOs = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macOs != null) {
      final permissions = await macOs.checkPermissions();
      return permissions?.isEnabled;
    }
    return true;
  }

  Future<void> _requestPermissions() async {
    await requestNotificationPermissions();
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
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
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

  Future<bool> showAdaptiveRecommendationDueNotification({
    bool ignorePreferences = false,
    Duration? delay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notify_adaptive_recommendation') ?? true) &&
        !ignorePreferences) {
      return false;
    }
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;
    final texts = _localizedAdaptiveRecommendationDueTexts();
    final activeGoal = await GoalRepositoryImpl().getActiveGoal();

    try {
      final details = _adaptiveRecommendationNotificationDetails();
      final payload = AppNotificationPayload(
        type: AppNotificationType.adaptiveRecommendation,
        goalId: activeGoal?.id,
      ).encode();

      if (delay != null && delay.inSeconds > 0) {
        final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
        try {
          await _plugin.zonedSchedule(
            id: adaptiveRecommendationDueNotificationId,
            title: texts.title,
            body: texts.body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );
        } catch (_) {
          await _plugin.zonedSchedule(
            id: adaptiveRecommendationDueNotificationId,
            title: texts.title,
            body: texts.body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        }
      } else {
        await _plugin.show(
          id: adaptiveRecommendationDueNotificationId,
          title: texts.title,
          body: texts.body,
          notificationDetails: details,
          payload: payload,
        );
      }
      return true;
    } catch (e, st) {
      debugPrint(
          'LocalNotificationService: showAdaptiveRecommendationDueNotification failed: $e\n$st');
      return false;
    }
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
    );
  }

  Future<bool> showWeeklyGoalReviewNotification({
    required String goalId,
    required String reviewId,
    String? goalTitle,
    int? recommendedCalories,
    bool ignorePreferences = false,
    Duration? delay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notify_weekly_goal_review') ?? true;
    if (!enabled && !ignorePreferences) return false;

    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;

    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);
    final body = goalTitle != null && recommendedCalories != null
        ? l10n.weeklyGoalReviewNotificationDetailedBody(
            goalTitle,
            recommendedCalories,
          )
        : l10n.weeklyGoalReviewNotificationBody;

    try {
      final id = notificationIdForReview(reviewId);
      final details = _weeklyGoalReviewNotificationDetails();
      final payload = AppNotificationPayload(
        type: AppNotificationType.weeklyGoalReview,
        goalId: goalId,
        reviewId: reviewId,
      ).encode();

      if (delay != null && delay.inSeconds > 0) {
        final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
        try {
          await _plugin.zonedSchedule(
            id: id,
            title: l10n.weeklyGoalReviewNotificationTitle,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );
        } catch (_) {
          await _plugin.zonedSchedule(
            id: id,
            title: l10n.weeklyGoalReviewNotificationTitle,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        }
      } else {
        await _plugin.show(
          id: id,
          title: l10n.weeklyGoalReviewNotificationTitle,
          body: body,
          notificationDetails: details,
          payload: payload,
        );
      }
      return true;
    } catch (e, st) {
      debugPrint(
          'LocalNotificationService: showWeeklyGoalReviewNotification failed: $e\n$st');
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
        presentList: true,
      ),
    );
  }

  Future<bool> showGoalTargetDateReminderNotification({
    required String goalId,
    required String goalTitle,
    bool isDueToday = false,
    bool ignorePreferences = false,
    Duration? delay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notify_goal_target_date') ?? false;
    if (!enabled && !ignorePreferences) return false;

    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;

    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);

    final title = l10n.goalTargetDateReminderTitle;
    final body = isDueToday
        ? l10n.goalTargetDateReachedBody(goalTitle)
        : l10n.goalTargetDateApproachingBody(goalTitle);

    try {
      final id =
          notificationIdForGoalTargetDate(goalId, isDueToday: isDueToday);
      final details = _goalTargetDateNotificationDetails();
      final payload = AppNotificationPayload(
        type: AppNotificationType.goalTargetDate,
        goalId: goalId,
      ).encode();

      if (delay != null && delay.inSeconds > 0) {
        final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
        try {
          await _plugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );
        } catch (_) {
          await _plugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        }
      } else {
        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: details,
          payload: payload,
        );
      }
      return true;
    } catch (e, st) {
      debugPrint(
          'LocalNotificationService: showGoalTargetDateReminderNotification failed: $e\n$st');
      return false;
    }
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

  NotificationDetails _workoutPlanNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _workoutPlanChannelId,
        'Workout plan',
        channelDescription: 'Optional reminders for planned workout days.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: false,
        presentList: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: false,
        presentList: true,
      ),
    );
  }

  @override
  Future<void> replaceWorkoutPlanReminders(
    List<WorkoutPlanReminder> reminders,
  ) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;
    await cancelWorkoutPlanReminders();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(locale);
    final details = _workoutPlanNotificationDetails();

    for (final reminder in reminders) {
      final local = reminder.scheduledAt;
      final when = tz.TZDateTime(
        tz.local,
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
      );
      final id = notificationIdForWorkoutPlan(
        reminder.planId,
        reminder.scheduledAt,
      );
      final payload = AppNotificationPayload(
        type: AppNotificationType.workoutPlan,
        planId: reminder.planId,
      ).encode();
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: l10n.workoutPlanReminderTitle,
          body: l10n.workoutPlanReminderBody(
            reminder.routineName,
            reminder.planName,
          ),
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } catch (_) {
        try {
          await _plugin.zonedSchedule(
            id: id,
            title: l10n.workoutPlanReminderTitle,
            body: l10n.workoutPlanReminderBody(
              reminder.routineName,
              reminder.planName,
            ),
            scheduledDate: when,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        } catch (_) {
          // A denied permission or unsupported scheduler must not affect plans.
        }
      }
    }
  }

  @override
  Future<void> cancelWorkoutPlanReminders() async {
    if (!_isInitialized) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final notification in pending) {
        if (AppNotificationPayload.tryParse(notification.payload)?.type ==
            AppNotificationType.workoutPlan) {
          await _plugin.cancel(id: notification.id);
        }
      }
    } catch (_) {
      // Pending-request enumeration is unavailable on a few desktop targets.
    }
  }

  static int notificationIdForReview(String reviewId) =>
      100000000 + (_stableHash(reviewId) % 100000000);

  static int notificationIdForGoalTargetDate(
    String goalId, {
    required bool isDueToday,
  }) =>
      (isDueToday ? 300000000 : 200000000) + (_stableHash(goalId) % 100000000);

  static int notificationIdForWorkoutPlan(String planId, DateTime date) =>
      400000000 +
      (_stableHash(
            '${planId}_${date.year}_${date.month}_${date.day}',
          ) %
          100000000);

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
