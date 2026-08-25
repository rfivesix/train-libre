// lib/services/voice/voice_dictation_settings.dart

import 'package:shared_preferences/shared_preferences.dart';

/// The language dictation listens in.
///
/// Kept apart from the app's display language on purpose: people run their
/// phone in one language and talk in another, and forcing them to describe a
/// meal in the interface language is the fastest way to make dictation useless.
class VoiceDictationSettings {
  static final VoiceDictationSettings instance = VoiceDictationSettings._();
  VoiceDictationSettings._();

  static const String localeKey = 'voice_dictation_locale_id';

  bool _loaded = false;
  String? _cached;

  /// The chosen recognizer locale, or null to follow the device.
  Future<String?> localeId() async {
    if (_loaded) return _cached;
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(localeKey);
    _loaded = true;
    return _cached;
  }

  Future<void> setLocaleId(String? id) async {
    _cached = id;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(localeKey);
    } else {
      await prefs.setString(localeKey, id);
    }
  }
}
