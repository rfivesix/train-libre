import 'dart:async';

import 'package:flutter/foundation.dart';

import 'cloud_loading_animation_controller.dart';

/// Manages simulated demo responses, word tickers, and timer lifecycles for the demo AI flow.
class CloudDemoGenerationRunner {
  static const _demoWords = <String>[
    '**Lorem',
    'ipsum**',
    'dolor',
    'sit',
    '*amet*,',
    'consectetur',
    '`adipiscing`',
    'elit,',
    'sed',
    'do',
    'eiusmod',
    'tempor',
    'incididunt',
    'ut',
    'labore',
    'et',
    'dolore',
    'magna',
    'aliqua.',
  ];

  int _demoWordIndex = 0;
  Timer? _responseTimer;
  Timer? _permissionBadgeDelayTimer;
  Timer? _permissionContinuationTimer;
  bool _isDisposed = false;

  int get demoWordIndex => _demoWordIndex;

  void resetWordIndex() {
    _demoWordIndex = 0;
  }

  void startWordTicker({required void Function(String wordSnippet) onWord}) {
    _responseTimer?.cancel();
    _responseTimer = Timer.periodic(const Duration(milliseconds: 55), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      final word = _demoWords[_demoWordIndex];
      _demoWordIndex = (_demoWordIndex + 1) % _demoWords.length;
      final snippet = _demoWordIndex == 0 ? '$word \n\n' : '$word ';
      onWord(snippet);
    });
  }

  Future<void> startStreamingAfterLoadingCloud({
    required CloudLoadingAnimationController loadingCloud,
    required bool Function() isStillActive,
    required void Function(String wordSnippet) onWord,
  }) async {
    if (!isStillActive()) return;
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!isStillActive()) return;
    await loadingCloud.hide();
    if (!isStillActive()) return;
    startWordTicker(onWord: onWord);
  }

  void stopWordTicker() {
    _responseTimer?.cancel();
    _responseTimer = null;
  }

  void schedulePermissionBadge({required VoidCallback onShowBadge}) {
    _permissionBadgeDelayTimer?.cancel();
    _permissionBadgeDelayTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed) onShowBadge();
    });
  }

  void cancelPermissionBadgeTimer() {
    _permissionBadgeDelayTimer?.cancel();
    _permissionBadgeDelayTimer = null;
  }

  void scheduleContinuationTimer({required VoidCallback onComplete}) {
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDisposed) onComplete();
    });
  }

  void cancelContinuationTimer() {
    _permissionContinuationTimer?.cancel();
    _permissionContinuationTimer = null;
  }

  void cancelAllTimers() {
    stopWordTicker();
    cancelPermissionBadgeTimer();
    cancelContinuationTimer();
  }

  void dispose() {
    _isDisposed = true;
    cancelAllTimers();
  }
}
