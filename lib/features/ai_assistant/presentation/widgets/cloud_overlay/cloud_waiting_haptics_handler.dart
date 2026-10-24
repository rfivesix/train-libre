import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../services/haptic_feedback_service.dart';

/// Manages idle waiting haptics and word-by-word streaming haptics for the AI cloud overlay.
class CloudWaitingHapticsHandler {
  static final RegExp _wordPattern = RegExp(r'\S+');

  final ValueGetter<bool> isExpandedGetter;

  bool _collapsedWaitingHapticsActive = false;
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
      if (_collapsedWaitingHapticsActive) {
        _collapsedWaitingHapticsActive = false;
        haptics.stopAiWaiting();
      }
      return;
    }

    if (!_collapsedWaitingHapticsActive) {
      _collapsedWaitingHapticsActive = true;
      haptics.startAiWaiting();
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
    if (_collapsedWaitingHapticsActive) {
      _collapsedWaitingHapticsActive = false;
      HapticFeedbackService.instance.stopAiWaiting();
    }
  }
}
