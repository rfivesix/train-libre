// lib/services/voice/voice_dictation_settings.dart

import 'package:shared_preferences/shared_preferences.dart';

/// User-facing switches for meal dictation.
class VoiceDictationSettings {
  static final VoiceDictationSettings instance = VoiceDictationSettings._();
  VoiceDictationSettings._();

  static const String localeKey = 'voice_dictation_locale_id';
  static const String aiTidyKey = 'voice_dictation_ai_tidy_enabled';

  bool _localeLoaded = false;
  String? _localeId;
  bool? _aiTidy;

  /// The language dictation listens in.
  ///
  /// Kept apart from the app's display language on purpose: people run their
  /// phone in one language and talk in another, and forcing them to describe a
  /// meal in the interface language is the fastest way to make dictation
  /// useless. Null follows the device.
  Future<String?> localeId() async {
    if (_localeLoaded) return _localeId;
    final prefs = await SharedPreferences.getInstance();
    _localeId = prefs.getString(localeKey);
    _localeLoaded = true;
    return _localeId;
  }

  Future<void> setLocaleId(String? id) async {
    _localeId = id;
    _localeLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(localeKey);
    } else {
      await prefs.setString(localeKey, id);
    }
  }

  /// Whether the finished transcript is sent for an AI clean-up pass.
  ///
  /// On by default: it is what turns a misheard "Sir Ratscher" back into
  /// Sriracha, and no local rule can do that. Switchable because it costs a
  /// request and a few seconds after every dictation, and someone on a slow
  /// provider should not have to pay that to use their voice.
  Future<bool> isAiTidyEnabled() async {
    final cached = _aiTidy;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(aiTidyKey) ?? true;
    _aiTidy = value;
    return value;
  }

  Future<void> setAiTidyEnabled(bool enabled) async {
    _aiTidy = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(aiTidyKey, enabled);
  }
}
