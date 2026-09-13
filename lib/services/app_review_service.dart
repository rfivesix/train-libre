import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/app/presentation/widgets/glass_bottom_menu.dart';
import '../generated/app_localizations.dart';
import 'telemetry/telemetry_service.dart';

enum _ReviewPromptResponse { yes, no, later }

class AppReviewService {
  AppReviewService._privateConstructor();
  static final AppReviewService instance =
      AppReviewService._privateConstructor();

  // Deliberately distinct from the retired launch-based prompt, so existing
  // users receive the improved, workout-timed opportunity once as well.
  static const String _hasRequestedReviewKey =
      'has_requested_review_after_workout_summary';

  /// Shows the rating menu exactly once, after the user closes their first
  /// completed-workout summary. The platform owns whether its native review
  /// sheet is actually displayed.
  Future<void> requestAfterFirstWorkoutSummaryClose(
      BuildContext context) async {
    try {
      if (!Platform.isIOS) return;

      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool(_hasRequestedReviewKey) ?? false;
      if (hasRequested) return;

      if (!context.mounted) return;
      final response =
          await _showRatingPromptMenu(context) ?? _ReviewPromptResponse.later;

      // "Later", including a drag or a tap outside the sheet, remains eligible
      // for the next completed workout. Only an explicit yes or no ends it.
      if (response != _ReviewPromptResponse.later) {
        await prefs.setBool(_hasRequestedReviewKey, true);
      }
      await TelemetryService.instance.trackAppReviewPromptResponded(
        response: response.name,
      );
    } catch (e) {
      debugPrint("AppReviewService error: $e");
    }
  }

  Future<_ReviewPromptResponse?> _showRatingPromptMenu(
      BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return null;

    return showGlassBottomMenu<_ReviewPromptResponse>(
      context: context,
      title: l10n.reviewPromptTitle,
      actions: [
        GlassMenuAction(
          icon: LucideIcons.thumbs_up,
          label: l10n.reviewPromptYes,
          subtitle: l10n.reviewPromptSubtitle,
          onTap: () async {
            final InAppReview inAppReview = InAppReview.instance;
            if (await inAppReview.isAvailable()) {
              await inAppReview.requestReview();
            }
          },
          result: _ReviewPromptResponse.yes,
        ),
        GlassMenuAction(
          icon: LucideIcons.thumbs_down,
          label: l10n.reviewPromptNo,
          onTap: () async {
            // The selected result is handled after the sheet closes.
          },
          result: _ReviewPromptResponse.no,
        ),
        GlassMenuAction(
          icon: LucideIcons.clock,
          label: l10n.reviewPromptLater,
          onTap: () async {
            // "Later" keeps the prompt eligible for the next workout.
          },
          result: _ReviewPromptResponse.later,
        ),
      ],
    );
  }
}
