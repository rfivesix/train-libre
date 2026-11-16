import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralized, settings-aware haptic feedback service.
class HapticFeedbackService {
  HapticFeedbackService._();

  static final HapticFeedbackService instance = HapticFeedbackService._();

  bool _enabled = true;

  Timer? _aiWaitingTimer;
  int _aiWaitingDepth = 0;
  bool _isPulsing = false;
  int _aiPulseGeneration = 0;

  bool get isEnabled => _enabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      stopAllAiWaiting();
    }
  }

  Future<void> selectionFeedback() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> selectionClick() async {
    await instance.selectionFeedback();
  }

  static Future<void> mediumImpact() async {
    await instance.chartSelectionFeedback();
  }

  Future<void> lightImpact() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> chartSelectionFeedback() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> strongImpact() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> confirmationFeedback() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> vibrate() async {
    if (!_enabled) return;
    await HapticFeedback.vibrate();
  }

  /// A short rising rhythm for one completed record set, without audio.
  Future<void> personalRecordFeedback() async {
    if (!_enabled) return;
    try {
      final custom = await Vibration.hasCustomVibrationsSupport();
      if (!_enabled) return;
      if (custom) {
        await Vibration.vibrate(
          pattern: const [35, 85, 35, 80, 45, 100, 110],
          intensities: const [90, 0, 130, 0, 175, 0, 240],
          sharpness: 0.75,
        );
      } else {
        await HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!_enabled) return;
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (_enabled) await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      if (_enabled) await HapticFeedback.heavyImpact();
    }
  }

  void startAiWaiting() {
    _aiWaitingDepth += 1;
    if (!_enabled || _aiWaitingTimer != null) return;

    _emitAiPulsePattern();
    _aiWaitingTimer = Timer.periodic(
      const Duration(milliseconds: 1450),
      (_) => _emitAiPulsePattern(),
    );
  }

  void stopAiWaiting() {
    if (_aiWaitingDepth > 0) {
      _aiWaitingDepth -= 1;
    }
    if (_aiWaitingDepth == 0) {
      _cancelAiWaitingTimer();
    }
  }

  void stopAllAiWaiting() {
    _aiWaitingDepth = 0;
    _cancelAiWaitingTimer();
  }

  void _cancelAiWaitingTimer() {
    _aiWaitingTimer?.cancel();
    _aiWaitingTimer = null;
    _aiPulseGeneration += 1;
    _isPulsing = false;
  }

  void _emitAiPulsePattern() {
    if (!_enabled || _aiWaitingDepth <= 0 || _isPulsing) return;
    _isPulsing = true;
    final int generation = _aiPulseGeneration;
    HapticFeedback.selectionClick().whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 110));
      if (!_enabled ||
          _aiWaitingDepth <= 0 ||
          generation != _aiPulseGeneration) {
        _isPulsing = false;
        return;
      }
      await HapticFeedback.selectionClick();

      await Future<void>.delayed(const Duration(milliseconds: 130));
      if (!_enabled ||
          _aiWaitingDepth <= 0 ||
          generation != _aiPulseGeneration) {
        _isPulsing = false;
        return;
      }
      await HapticFeedback.lightImpact();
      _isPulsing = false;
    });
  }
}
