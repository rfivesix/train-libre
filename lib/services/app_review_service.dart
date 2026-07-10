import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  AppReviewService._privateConstructor();
  static final AppReviewService instance =
      AppReviewService._privateConstructor();

  static const String _firstLaunchDateKey = 'first_app_launch_date';
  static const String _hasRequestedReviewKey = 'has_requested_app_review';

  Future<void> checkAndRequestReview() async {
    try {
      if (!Platform.isIOS) return;

      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool(_hasRequestedReviewKey) ?? false;

      if (hasRequested) return;

      final firstLaunchString = prefs.getString(_firstLaunchDateKey);
      if (firstLaunchString == null) {
        await prefs.setString(
            _firstLaunchDateKey, DateTime.now().toIso8601String());
        return;
      }

      final firstLaunchDate = DateTime.parse(firstLaunchString);
      final daysSinceLaunch = DateTime.now().difference(firstLaunchDate).inDays;

      if (daysSinceLaunch >= 7) {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
          await prefs.setBool(_hasRequestedReviewKey, true);
        }
      }
    } catch (e) {
      debugPrint("AppReviewService error: $e");
    }
  }
}
