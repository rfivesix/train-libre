import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/app/presentation/widgets/glass_bottom_menu.dart';
import '../generated/app_localizations.dart';

class AppReviewService {
  AppReviewService._privateConstructor();
  static final AppReviewService instance =
      AppReviewService._privateConstructor();

  static const String _firstLaunchDateKey = 'first_app_launch_date';
  static const String _hasRequestedReviewKey = 'has_requested_app_review';
  static const String _snoozedUntilKey = 'app_review_snoozed_until';

  Future<void> checkAndRequestReview(BuildContext context) async {
    try {
      if (!Platform.isIOS) return;

      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool(_hasRequestedReviewKey) ?? false;

      if (hasRequested) return;

      // Check snooze
      final snoozedUntilString = prefs.getString(_snoozedUntilKey);
      if (snoozedUntilString != null) {
        final snoozedUntil = DateTime.tryParse(snoozedUntilString);
        if (snoozedUntil != null && DateTime.now().isBefore(snoozedUntil)) {
          return;
        }
      }

      final firstLaunchString = prefs.getString(_firstLaunchDateKey);
      if (firstLaunchString == null) {
        await prefs.setString(
            _firstLaunchDateKey, DateTime.now().toIso8601String());
        return;
      }

      final firstLaunchDate = DateTime.parse(firstLaunchString);
      final daysSinceLaunch =
          DateTime.now().difference(firstLaunchDate).inDays;

      if (daysSinceLaunch >= 3) {
        if (!context.mounted) return;
        await _showRatingPromptMenu(context, prefs);
      }
    } catch (e) {
      debugPrint("AppReviewService error: $e");
    }
  }

  Future<void> _showRatingPromptMenu(
      BuildContext context, SharedPreferences prefs) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    await showGlassBottomMenu(
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
            await prefs.setBool(_hasRequestedReviewKey, true);
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.thumbs_down,
          label: l10n.reviewPromptNo,
          onTap: () async {
            await prefs.setBool(_hasRequestedReviewKey, true);
          },
        ),
        GlassMenuAction(
          icon: LucideIcons.clock,
          label: l10n.reviewPromptLater,
          onTap: () async {
            final snoozeDate = DateTime.now().add(const Duration(days: 7));
            await prefs.setString(
                _snoozedUntilKey, snoozeDate.toIso8601String());
          },
        ),
      ],
    );
  }
}

