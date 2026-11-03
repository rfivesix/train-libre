import 'package:shared_preferences/shared_preferences.dart';

/// Preferences for rest-timer alerts during a live workout.
class LiveWorkoutNotificationPreferences {
  static const restNotificationsKey = 'live_workout_rest_notifications';
  static const ignoreSilentModeKey = 'live_workout_ignore_silent_mode';

  static Future<bool> restNotificationsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(restNotificationsKey) ??
      true;

  static Future<bool> ignoreSilentMode() async =>
      (await SharedPreferences.getInstance()).getBool(ignoreSilentModeKey) ??
      true;
}
