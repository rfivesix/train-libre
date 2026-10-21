import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../services/haptic_feedback_service.dart';

/// Manages idle waiting haptics and word-by-word streaming haptics for the AI cloud overlay.
class CloudWaitingHapticsHandler {
  static final RegExp _wordPattern = RegExp(r'\S+');

  final ValueGetter<bool> isExpandedGetter;

  Timer? _collapsedWaitingHapticTimer;
  bool _expandedWaitingHapticsActive = false;
  int _lastHapticWordCount = 0;
  DateTime? _lastWordHapticAt;

  CloudWaitingHapticsHandler({required this.isExpandedGetter});

  void resetWordHaptics() {
    _lastHapticWordCount = 0;
    _lastWordHapticAt = null;
  }

  void sync({required bool isGenerating}) {
    final haptics = HapticFeedbackService.instance;
    final isExpanded = isExpandedGetter();

    if (!isGenerating || isExpanded) {
      _collapsedWaitingHapticTimer?.cancel();
      _collapsedWaitingHapticTimer = null;
      if (_expandedWaitingHapticsActive) {
        _expandedWaitingHapticsActive = false;
        haptics.stopAiWaiting();
      }
      return;
    }

    if (_expandedWaitingHapticsActive) {
      _expandedWaitingHapticsActive = false;
      haptics.stopAiWaiting();
    }
    if (_collapsedWaitingHapticTimer == null) {
      unawaited(haptics.lightImpact());
      _collapsedWaitingHapticTimer = Timer.periodic(
        const Duration(milliseconds: 1450),
        (_) => unawaited(haptics.lightImpact()),
      );
    }
  }

  void triggerWordHapticIfNeeded(String responseText) {
    final wordCount = _wordPattern.allMatches(responseText).length;
    if (wordCount <= _lastHapticWordCount) return;
    _lastHapticWordCount = wordCount;
    if (!isExpandedGetter()) return;
    final now = DateTime.now();
    final last = _lastWordHapticAt;
    if (last != null && now.difference(last).inMilliseconds < 28) {
      return;
    }
    _lastWordHapticAt = now;
    unawaited(HapticFeedbackService.instance.selectionFeedback());
  }

  void dispose() {
    _collapsedWaitingHapticTimer?.cancel();
    if (_expandedWaitingHapticsActive) {
      HapticFeedbackService.instance.stopAiWaiting();
    }
  }
}
