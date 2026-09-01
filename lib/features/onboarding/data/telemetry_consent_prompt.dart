import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decides whether the telemetry question may be asked a second time, and
/// remembers that it was.
///
/// The question is asked once right after the initial consent. If the user
/// declines there, it may be asked exactly once more — never a third time,
/// whatever the second answer is. The switch in Settings stays available
/// either way, which is what makes a single follow-up defensible: it is one
/// reminder that the option exists, not a campaign to wear the user down.
///
/// Two conditions gate the follow-up, and both have to hold:
///
/// * **[minimumDays] of calendar time** since the anchor, so the question is
///   clearly separated from onboarding and does not read as pressing again.
/// * **[minimumLaunches] app starts** since then, so it reaches someone who
///   actually uses the app rather than someone opening it for the second time
///   after two idle weeks.
///
/// Every failure is swallowed. Nothing here may be able to block a launch, and
/// the safe direction on error is always "not due" — a prompt that silently
/// fails to appear costs nothing; one that appears when it should not is the
/// thing this class exists to prevent.
///
/// Deliberately mirrors the shape of `WhatsNewService`: a singleton over
/// `SharedPreferences`, injectable clock for tests.
///
/// The keys live in `SharedPreferences`, which the backup includes, so a
/// restored backup carries the "already asked" state with it and a user who
/// moves to a new device is not asked again.
class TelemetryConsentPrompt {
  TelemetryConsentPrompt._();

  static final TelemetryConsentPrompt instance = TelemetryConsentPrompt._();

  /// Set once the follow-up has been shown, whatever the answer was. Also set
  /// when the user opts in at any point, because there is then nothing left to
  /// ask about.
  static const String followUpDoneKey = 'telemetry_follow_up_done';

  /// ISO-8601 timestamp the waiting period counts from: the moment the user
  /// declined during onboarding, or — for installations that predate this
  /// prompt — their first launch after updating into it.
  static const String anchorKey = 'telemetry_follow_up_anchor';

  /// Launches counted since [anchorKey] was set.
  static const String launchCountKey = 'telemetry_follow_up_launches';

  /// Calendar days that must pass before the follow-up may be shown.
  static const int minimumDays = 14;

  /// App starts that must happen in that time before the follow-up may be
  /// shown. The launch that crosses the threshold is itself eligible.
  static const int minimumLaunches = 5;

  /// Overridable for tests, which must not depend on the wall clock.
  @visibleForTesting
  DateTime Function()? clockOverride;

  DateTime get _now => (clockOverride ?? DateTime.now)();

  @visibleForTesting
  void resetForTesting() => clockOverride = null;

  /// Records that the user has answered the question during onboarding.
  ///
  /// A yes closes the subject for good. A no starts the waiting period for the
  /// single follow-up.
  Future<void> recordOnboardingAnswer({required bool optedIn}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (optedIn) {
        await prefs.setBool(followUpDoneKey, true);
        return;
      }
      await prefs.setString(anchorKey, _now.toIso8601String());
      await prefs.setInt(launchCountKey, 0);
    } catch (e) {
      debugPrint('TelemetryConsentPrompt.recordOnboardingAnswer failed: $e');
    }
  }

  /// Counts this launch towards [minimumLaunches], and anchors installations
  /// that predate the prompt.
  ///
  /// Call once per app start, before [isFollowUpDue].
  Future<void> registerLaunch({required bool isOptedIn}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isOptedIn) {
        // Opted in at some point — through onboarding, through Settings, or
        // through a restored backup. There is nothing left to ask.
        await prefs.setBool(followUpDoneKey, true);
        return;
      }
      if (prefs.getBool(followUpDoneKey) ?? false) return;

      if (prefs.getString(anchorKey) == null) {
        // An installation from before this prompt existed. It never saw the
        // question, so it gets the same waiting period as everyone else rather
        // than being asked on the spot.
        await prefs.setString(anchorKey, _now.toIso8601String());
        await prefs.setInt(launchCountKey, 0);
        return;
      }

      final launches = prefs.getInt(launchCountKey) ?? 0;
      if (launches < minimumLaunches) {
        await prefs.setInt(launchCountKey, launches + 1);
      }
    } catch (e) {
      debugPrint('TelemetryConsentPrompt.registerLaunch failed: $e');
    }
  }

  /// Whether the one follow-up is due on this launch.
  Future<bool> isFollowUpDue({required bool isOptedIn}) async {
    if (isOptedIn) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(followUpDoneKey) ?? false) return false;

      final rawAnchor = prefs.getString(anchorKey);
      if (rawAnchor == null) return false;
      final anchor = DateTime.tryParse(rawAnchor);
      if (anchor == null) return false;

      final launches = prefs.getInt(launchCountKey) ?? 0;
      if (launches < minimumLaunches) return false;

      // A clock that has moved backwards (timezone change, manual correction)
      // yields a negative difference and simply keeps the prompt waiting.
      return _now.difference(anchor).inDays >= minimumDays;
    } catch (e) {
      debugPrint('TelemetryConsentPrompt.isFollowUpDue failed: $e');
      return false;
    }
  }

  /// Records that the follow-up has been shown. Called whatever the answer
  /// was, and also when the sheet was dismissed without one — the user has
  /// seen the question, and that is the thing that must not repeat.
  Future<void> markFollowUpShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(followUpDoneKey, true);
    } catch (e) {
      debugPrint('TelemetryConsentPrompt.markFollowUpShown failed: $e');
    }
  }
}
