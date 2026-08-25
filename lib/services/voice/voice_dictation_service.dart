// lib/services/voice/voice_dictation_service.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Why dictation is unavailable, so the UI can say something useful instead of
/// a generic failure.
enum VoiceUnavailableReason {
  /// Microphone or speech recognition permission was declined.
  permissionDenied,

  /// The platform reports no usable speech recognizer.
  unsupported,

  /// Initialisation failed for another reason.
  failed,
}

class VoiceAvailability {
  final bool available;
  final VoiceUnavailableReason? reason;

  /// True when the device can transcribe without sending audio anywhere.
  /// Checked up front so the consent copy can be accurate before the user
  /// speaks, not after.
  final bool onDeviceAvailable;

  const VoiceAvailability({
    required this.available,
    this.reason,
    this.onDeviceAvailable = false,
  });
}

/// Wraps the platform speech recognizer for meal dictation.
///
/// Prefers on-device recognition and only falls back to the platform's network
/// recognizer when the device cannot do it locally — [lastRunUsedNetwork] then
/// reports that, so the UI can disclose it.
class VoiceDictationService {
  static final VoiceDictationService instance = VoiceDictationService._();
  VoiceDictationService._();

  final SpeechToText _speech = SpeechToText();

  /// Native probe for what the platform speech recognizer can actually do.
  /// See `SpeechCapabilityPlugin` for why this cannot be asked of the plugin.
  static const MethodChannel _capabilityChannel =
      MethodChannel('trainlibre.speech/capability');

  bool _initialized = false;
  bool _onDeviceAvailable = false;
  bool _lastRunUsedNetwork = false;

  bool get isListening => _speech.isListening;
  bool get onDeviceAvailable => _onDeviceAvailable;
  bool get lastRunUsedNetwork => _lastRunUsedNetwork;

  /// Whether the microphone and speech recognition have already been granted.
  ///
  /// Asked separately from [prepare] because `initialize` is what triggers the
  /// system prompts, and those must not be the first thing the user sees —
  /// they get an explanation first.
  Future<bool> hasPermissions() async {
    if (_initialized && _speech.isAvailable) return true;
    try {
      final microphone = await Permission.microphone.status;
      if (!microphone.isGranted) return false;
      if (Platform.isIOS || Platform.isMacOS) {
        final speech = await Permission.speech.status;
        if (!speech.isGranted) return false;
      }
      return true;
    } catch (e) {
      debugPrint('[VoiceDictation] permission check failed: $e');
      return false;
    }
  }

  /// Initialises the recognizer and requests permission. Safe to call repeatedly.
  Future<VoiceAvailability> prepare() async {
    if (_initialized && _speech.isAvailable) {
      return VoiceAvailability(
        available: true,
        onDeviceAvailable: _onDeviceAvailable,
      );
    }

    try {
      final available = await _speech.initialize(
        onError: (error) =>
            debugPrint('[VoiceDictation] error: ${error.errorMsg}'),
        onStatus: (status) => debugPrint('[VoiceDictation] status: $status'),
        debugLogging: false,
      );

      _initialized = true;

      if (!available) {
        final granted = await _speech.hasPermission;
        return VoiceAvailability(
          available: false,
          reason: granted
              ? VoiceUnavailableReason.unsupported
              : VoiceUnavailableReason.permissionDenied,
        );
      }

      return VoiceAvailability(
        available: true,
        onDeviceAvailable: _onDeviceAvailable,
      );
    } catch (e) {
      debugPrint('[VoiceDictation] initialize failed: $e');
      return const VoiceAvailability(
        available: false,
        reason: VoiceUnavailableReason.failed,
      );
    }
  }

  /// Every locale the platform recognizer offers, sorted by display name.
  ///
  /// Exposed so the user can pick the language they actually speak instead of
  /// inheriting the interface language.
  Future<List<({String id, String name})>> availableLocales() async {
    final availability = await prepare();
    if (!availability.available) return const [];
    try {
      final locales = await _speech.locales();
      final mapped = locales
          .map((l) => (id: l.localeId, name: l.name))
          .toList(growable: false)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return mapped;
    } catch (e) {
      debugPrint('[VoiceDictation] locales failed: $e');
      return const [];
    }
  }

  /// The device's own recognizer locale, used when the user has not picked one.
  Future<String?> systemLocaleId() async {
    try {
      final system = await _speech.systemLocale();
      return system?.localeId;
    } catch (e) {
      debugPrint('[VoiceDictation] systemLocale failed: $e');
      return null;
    }
  }

  /// The recognizer id that really exists for [localeId].
  ///
  /// The app hands us a bare language tag such as `de`, which is not one of the
  /// recognizer's supported locales — asking for it produced a recognizer with
  /// no on-device assets, which is exactly the case that used to crash.
  Future<String?> resolveLocale(String? localeId) => _resolveLocale(localeId);

  Future<String?> _resolveLocale(String? localeId) async {
    if (!Platform.isIOS) return localeId;
    try {
      final resolved = await _capabilityChannel.invokeMethod<String>(
        'resolveLocale',
        {'localeId': localeId},
      );
      return resolved ?? localeId;
    } catch (e) {
      debugPrint('[VoiceDictation] locale resolve failed: $e');
      return localeId;
    }
  }

  /// Whether local transcription is genuinely possible for [localeId].
  ///
  /// Asked up front rather than by trying: `speech_to_text` answers an
  /// unsupported on-device request by completing the same platform message
  /// twice, which brings the engine down instead of returning an error.
  Future<bool> _canRunOnDevice(String? localeId) async {
    if (!Platform.isIOS) return true;
    try {
      final supported = await _capabilityChannel.invokeMethod<bool>(
        'onDeviceSupported',
        {'localeId': localeId},
      );
      return supported ?? false;
    } catch (e) {
      // No probe means no way to know it is safe, and the failure mode of
      // guessing wrong is a crash rather than a fallback.
      debugPrint('[VoiceDictation] on-device probe failed: $e');
      return false;
    }
  }

  /// Turns the platform's raw sound level into a 0-to-1 loudness.
  ///
  /// The two platforms report on completely different scales and neither is
  /// meaningful to a UI: iOS sends dBFS (`20*log10(rms)`), so silence sits
  /// around -60 and a shout approaches 0, while Android sends roughly -2 to 10.
  /// Treating the iOS numbers as if they were Android's clamped every reading
  /// to the floor, which is why the level looked frozen at zero.
  static double normalizeLevel(double raw) => Platform.isIOS || Platform.isMacOS
      ? normalizeDbLevel(raw)
      : normalizeAndroidLevel(raw);

  /// Apple's scale: dBFS, where 0 is the loudest the microphone can encode.
  ///
  /// The floor is -45 dB, roughly a quiet room — below that there is nothing
  /// worth showing, and mapping from -60 would leave normal speech bunched into
  /// the top third of the range.
  static double normalizeDbLevel(double db) {
    if (db.isNaN || db.isInfinite) return 0;
    const floorDb = -45.0;
    return ((db - floorDb) / -floorDb).clamp(0.0, 1.0);
  }

  /// Android's scale: roughly -2 for silence to 10 for loud.
  static double normalizeAndroidLevel(double raw) {
    if (raw.isNaN || raw.isInfinite) return 0;
    return ((raw + 2) / 12).clamp(0.0, 1.0);
  }

  /// Starts listening. [onPartial] fires continuously, [onFinal] once the
  /// recognizer settles on a result.
  ///
  /// [onSoundLevel] reports loudness already normalised to 0 to 1 — see
  /// [normalizeLevel].
  ///
  /// Returns false when listening could not be started at all.
  Future<bool> start({
    required void Function(String text) onPartial,
    required void Function(String text) onFinal,
    void Function(double level)? onSoundLevel,
    String? localeId,
  }) async {
    final availability = await prepare();
    if (!availability.available) return false;

    // A session already running would be refused by the platform anyway, and
    // starting a second one on top of it is how the audio engine ends up with
    // two taps on the same bus.
    if (_speech.isListening) {
      await cancel();
    }

    void handleResult(SpeechRecognitionResult result) {
      final words = result.recognizedWords.trim();
      if (result.finalResult) {
        onFinal(words);
      } else {
        onPartial(words);
      }
    }

    final resolvedLocale = await _resolveLocale(localeId);

    Future<bool> attempt({required bool onDevice}) async {
      try {
        await _speech.listen(
          onResult: handleResult,
          onSoundLevelChange: onSoundLevel == null
              ? null
              : (level) => onSoundLevel(normalizeLevel(level)),
          listenOptions: SpeechListenOptions(
            partialResults: true,
            onDevice: onDevice,
            cancelOnError: true,
            listenMode: ListenMode.dictation,
            localeId: resolvedLocale,
            // Generous: the user ends dictation by releasing the button.
            listenFor: const Duration(seconds: 60),
            pauseFor: const Duration(seconds: 10),
          ),
        );
      } catch (e) {
        debugPrint('[VoiceDictation] listen(onDevice: $onDevice) failed: $e');
        return false;
      }

      // A refused session reports success from `listen` but never enters the
      // listening state, so confirm before trusting it.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return _speech.isListening;
    }

    // On-device only when the platform says it can — never on spec.
    if (await _canRunOnDevice(resolvedLocale)) {
      if (await attempt(onDevice: true)) {
        _onDeviceAvailable = true;
        _lastRunUsedNetwork = false;
        return true;
      }
      // Unconditional: a session that never reached the listening state still
      // holds the audio engine, and the retry below would be refused.
      await _forceReset();
    }

    final started = await attempt(onDevice: false);
    _onDeviceAvailable = false;
    _lastRunUsedNetwork = started;
    return started;
  }

  /// Tears a half-started session down even when the plugin no longer thinks it
  /// is listening — that flag is set from a callback the refused path skips.
  Future<void> _forceReset() async {
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('[VoiceDictation] reset failed: $e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  /// Stops listening and lets the recognizer deliver its final result.
  Future<void> stop() async {
    if (!_speech.isListening) return;
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('[VoiceDictation] stop failed: $e');
    }
  }

  /// Aborts without waiting for a final result.
  Future<void> cancel() async {
    if (!_speech.isListening) return;
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('[VoiceDictation] cancel failed: $e');
    }
  }
}
