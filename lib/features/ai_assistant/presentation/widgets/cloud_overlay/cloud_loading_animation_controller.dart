import 'package:flutter/material.dart';

/// Manages entering, waiting, and reversing the loading cloud orb animation.
class CloudLoadingAnimationController {
  final AnimationController animation;
  bool isVisible = false;
  Future<void>? _enterFuture;

  CloudLoadingAnimationController({required this.animation});

  Future<void> show() {
    isVisible = true;
    _enterFuture = animation.forward(from: 0.0);
    return _enterFuture!;
  }

  Future<void> hide({bool waitForEnter = true}) async {
    if (!isVisible) return;
    try {
      if (animation.value > 0.001) {
        if (waitForEnter && _enterFuture != null) await _enterFuture;
        await animation.reverse();
      } else {
        animation.stop();
        animation.value = 0;
      }
    } catch (_) {}
    isVisible = false;
  }

  void reset() {
    _enterFuture = null;
    animation.stop();
    animation.value = 0;
    isVisible = false;
  }

  void dispose() {
    animation.dispose();
  }
}
