import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralized sound service for playing audio effects (e.g. workout timer completion).
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('SoundService audio context initialization info: $e');
    }
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
