import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/whats_new_content.g.dart';
import '../domain/whats_new_release.dart';

/// TEMPORARY TESTING SWITCH — set back to `false` before releasing.
///
/// While `true`, the "What's New" sheet is shown on every single app start,
/// regardless of the stored version, so the layout can be inspected without
/// reinstalling over an older build. It also stops [WhatsNewService.markSeen]
/// from having any lasting effect, so the sheet keeps coming back.
const bool kDebugAlwaysShowWhatsNew = true;

/// Decides whether the "What's New" sheet is due after an update, and
/// remembers which version the user has already seen.
///
/// Deliberately mirrors the shape of `AppTourService`: a singleton over
/// `SharedPreferences`, with every failure swallowed — nothing here may be able
/// to block app startup.
class WhatsNewService {
  WhatsNewService._();

  static final WhatsNewService instance = WhatsNewService._();

  /// Marketing version (`1.0.2`) of the last release whose notes were shown.
  static const String lastSeenVersionKey = 'whats_new_last_seen_version';

  /// Overridable for tests, which must not touch the platform channel.
  @visibleForTesting
  Future<String> Function()? versionLoaderOverride;

  /// Overridable for tests, so they assert the selection logic rather than
  /// whatever happens to be in `metadata/whats_new/` today.
  @visibleForTesting
  Map<String, List<WhatsNewRelease>>? catalogOverride;

  /// Runtime mirror of [kDebugAlwaysShowWhatsNew]; tests turn it off so they
  /// exercise the real behaviour regardless of the shipped default.
  @visibleForTesting
  bool alwaysShow = kDebugAlwaysShowWhatsNew;

  /// Restores the defaults between tests.
  @visibleForTesting
  void resetForTesting() {
    versionLoaderOverride = null;
    catalogOverride = null;
    alwaysShow = kDebugAlwaysShowWhatsNew;
  }

  Future<String> _currentVersion() async {
    final override = versionLoaderOverride;
    if (override != null) return override();
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Releases the user has not seen yet, newest first.
  ///
  /// Rules:
  /// * Nothing stored yet (existing installs upgrading into this feature, or a
  ///   restored backup from before it): show the current version's notes only.
  /// * Already seen the current version: nothing.
  /// * Otherwise: every release above the stored version and at most the
  ///   current one — the upper bound keeps notes for an unreleased version that
  ///   is already prepared in the Markdown out of TestFlight builds.
  Future<List<WhatsNewRelease>> pendingReleases(String languageCode) async {
    try {
      final version = await _currentVersion();
      final releases = releasesForLanguage(languageCode);
      if (releases.isEmpty) return const [];

      if (alwaysShow) {
        final current = AppVersion.parse(version);
        final forCurrent = releases
            .where((r) => AppVersion.parse(r.version) <= current)
            .toList();
        return forCurrent.isEmpty ? releases : forCurrent;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(lastSeenVersionKey);
      final current = AppVersion.parse(version);

      if (lastSeen == null) {
        return releases.where((r) => r.version == version).toList();
      }
      if (lastSeen == version) return const [];

      final seen = AppVersion.parse(lastSeen);
      return releases.where((r) {
        final v = AppVersion.parse(r.version);
        return v > seen && v <= current;
      }).toList();
    } catch (e) {
      debugPrint('WhatsNewService.pendingReleases failed: $e');
      return const [];
    }
  }

  /// Every release on record for [languageCode], newest first. Used by the
  /// manual entry point in "About", which shows the full history.
  List<WhatsNewRelease> releasesForLanguage(String languageCode) {
    final catalog = catalogOverride ?? kWhatsNewContent;
    return catalog[languageCode] ??
        catalog[kWhatsNewFallbackLanguage] ??
        const [];
  }

  /// Records the running version as seen. Called after the sheet is dismissed,
  /// never before, so a force-quit mid-read does not swallow the notes.
  Future<void> markSeen() async {
    if (alwaysShow) return;
    try {
      final version = await _currentVersion();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastSeenVersionKey, version);
    } catch (e) {
      debugPrint('WhatsNewService.markSeen failed: $e');
    }
  }

  /// Marks the current version as seen without ever showing the sheet.
  ///
  /// Used for fresh installs: a new user has just been through onboarding and
  /// the app tour and does not need a changelog for features they have never
  /// seen the previous version of.
  Future<void> seedForFreshInstall() => markSeen();
}
