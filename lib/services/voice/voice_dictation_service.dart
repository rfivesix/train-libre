// lib/services/voice/voice_dictation_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
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

  bool _initialized = false;
  bool _onDeviceAvailable = false;
  bool _lastRunUsedNetwork = false;

  bool get isListening => _speech.isListening;
  bool get onDeviceAvailable => _onDeviceAvailable;
  bool get lastRunUsedNetwork => _lastRunUsedNetwork;

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
        onError: (error) => debugPrint('[VoiceDictation] error: ${error.errorMsg}'),
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

  /// Starts listening. [onPartial] fires continuously, [onFinal] once the
  /// recognizer settles on a result.
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

    void handleResult(SpeechRecognitionResult result) {
      final words = result.recognizedWords.trim();
      if (result.finalResult) {
        onFinal(words);
      } else {
        onPartial(words);
      }
    }

    // The plugin exposes no reliable "is on-device recognition available" query,
    // so availability is established by trying it: with onDevice: true the
    // platform refuses rather than silently going to the network. If that
    // refusal happens we retry over the network and remember it, so the UI can
    // say so.
    Future<bool> attempt({required bool onDevice}) async {
      try {
        await _speech.listen(
          onResult: handleResult,
          onSoundLevelChange: onSoundLevel,
          listenOptions: SpeechListenOptions(
            partialResults: true,
            onDevice: onDevice,
            cancelOnError: true,
            listenMode: ListenMode.dictation,
            localeId: localeId,
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

    if (await attempt(onDevice: true)) {
      _onDeviceAvailable = true;
      _lastRunUsedNetwork = false;
      return true;
    }

    await cancel();
    final started = await attempt(onDevice: false);
    _onDeviceAvailable = false;
    _lastRunUsedNetwork = started;
    return started;
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
