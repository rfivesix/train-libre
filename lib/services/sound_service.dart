import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../features/workout/domain/live_workout_notification_preferences.dart';

/// Centralized sound service for playing audio effects (e.g. workout timer completion).
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool? _ignoreSilentMode;

  @visibleForTesting
  static AudioContext timerAudioContext(bool ignoreSilentMode) => AudioContext(
    android: AudioContextAndroid(
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: ignoreSilentMode
          ? AndroidUsageType.alarm
          : AndroidUsageType.notification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: ignoreSilentMode
          ? AVAudioSessionCategory.playback
          : AVAudioSessionCategory.ambient,
      options: ignoreSilentMode
          ? const {AVAudioSessionOptions.mixWithOthers}
          : const {},
    ),
  );

  Future<void> _ensureInitialized() async {
    final ignoreSilentMode =
        await LiveWorkoutNotificationPreferences.ignoreSilentMode();
    if (_ignoreSilentMode == ignoreSilentMode) return;
    try {
      await _player.setAudioContext(timerAudioContext(ignoreSilentMode));
      _ignoreSilentMode = ignoreSilentMode;
    } catch (e) {
      debugPrint('SoundService audio context initialization info: $e');
    }
  }

  /// Applies the current preference immediately, rather than waiting for the
  /// next timer chime. On iOS this is the global AVAudioSession category, so
  /// leaving it in `playback` after the preference is disabled can make later
  /// background notification sounds ignore the hardware silent switch.
  Future<void> refreshAudioContext() async {
    _ignoreSilentMode = null;
    await _ensureInitialized();
  }

  /// Plays the timer completion chime over active headphones or speaker output.
  Future<void> playTimerDoneSound() async {
    try {
      await _ensureInitialized();
      await _player.stop();
      await _player.play(AssetSource('sounds/timer_done.mp3'));
    } catch (e) {
      debugPrint('SoundService playTimerDoneSound error: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
