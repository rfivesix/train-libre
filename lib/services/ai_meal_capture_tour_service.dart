import 'package:shared_preferences/shared_preferences.dart';

/// Service managing the completion status of the AI Meal Capture interactive tour.
class AiMealCaptureTourService {
  AiMealCaptureTourService._();

  static final AiMealCaptureTourService instance = AiMealCaptureTourService._();

  static const String tourCompletedKey = 'ai_meal_capture_tour_completed';

  /// Returns true if the user has already completed or dismissed the AI capture tour.
  Future<bool> isTourCompleted({SharedPreferences? prefs}) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    return resolvedPrefs.getBool(tourCompletedKey) ?? false;
  }

  /// Marks the AI capture tour as completed.
  Future<void> markTourCompleted({SharedPreferences? prefs}) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await resolvedPrefs.setBool(tourCompletedKey, true);
  }

  /// Resets the tour state so it can be re-shown as first-time on demand.
  Future<void> resetTour({SharedPreferences? prefs}) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await resolvedPrefs.setBool(tourCompletedKey, false);
  }
}
