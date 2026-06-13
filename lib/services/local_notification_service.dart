import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/app_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../features/nutrition_recommendation/data/recommendation_repository.dart';
import '../features/nutrition_recommendation/domain/adaptive_recommendation_snapshot.dart';

/// Handles local notification setup and rest timer notifications.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const int restTimerNotificationId = 8801;
  static const int adaptiveRecommendationDueNotificationId = 8802;
  static const int tdeeRecalculationNotificationId = 8803;
  static const String _restChannelId = 'rest_timer_channel';
  static const String _adaptiveRecommendationChannelId =
      'adaptive_recommendation_channel';
  static const String _tdeeRecalculationChannelId =
      'tdee_recalculation_channel';

  StreamSubscription<AdaptiveRecommendationSnapshot>? _tdeeSubscription;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

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

      await _plugin.initialize(settings: settings);
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
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
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
              'rest_timer_foreground_channel_v3',
              'Rest Timer (Foreground)',
              channelDescription: 'Alerts when the rest timer finishes while in the foreground.',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              playSound: true,
              enableVibration: hapticsEnabled,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: false,
              presentSound: true,
              presentBadge: false,
            ),
            macOS: const DarwinNotificationDetails(
              presentAlert: false,
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
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;
    final texts = _localizedAdaptiveRecommendationDueTexts();

    await _plugin.show(
      id: adaptiveRecommendationDueNotificationId,
      title: texts.title,
      body: texts.body,
      notificationDetails: _adaptiveRecommendationNotificationDetails(),
    );
  }

  NotificationDetails _tdeeRecalculationNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _tdeeRecalculationChannelId,
        'TDEE Recalculation',
        channelDescription: 'Alerts when a new TDEE recalculation is completed.',
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
      body: l10n.tdeeRecalculationNotificationBody(calories, protein, carbs, fat),
    );
  }

  Future<void> showTdeeRecalculationNotification({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;
    final texts = _localizedTdeeRecalculationTexts(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );

    await _plugin.show(
      id: tdeeRecalculationNotificationId,
      title: texts.title,
      body: texts.body,
      notificationDetails: _tdeeRecalculationNotificationDetails(),
    );
  }
}
