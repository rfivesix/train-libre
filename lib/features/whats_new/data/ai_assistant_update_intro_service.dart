import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/whats_new_release.dart';

/// Tracks the one-time AI chat introduction independently of release notes.
class AiAssistantUpdateIntroService {
  AiAssistantUpdateIntroService._();

  static final AiAssistantUpdateIntroService instance =
      AiAssistantUpdateIntroService._();
  static const String _seenVersionKey = 'ai_assistant_intro_seen_version';
  static const String _introVersion = '1.7.0';

  Future<bool> isDue() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (AppVersion.parse(info.version) < AppVersion.parse('1.7.0-beta.1')) {
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_seenVersionKey) != _introVersion;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seenVersionKey, _introVersion);
    } catch (_) {
      // A presentation preference must never block startup.
    }
  }

  Future<void> seedForFreshInstall() => markSeen();
}
