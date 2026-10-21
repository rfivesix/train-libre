import 'package:flutter/material.dart';

/// Manages entering, waiting, and reversing the loading cloud orb animation.
class CloudLoadingAnimationController {
  final AnimationController animation;
  bool isVisible = false;
  Future<void>? _enterFuture;
  Future<void>? _hideFuture;
  int _revision = 0;

  CloudLoadingAnimationController({required this.animation});

  Future<void> show() {
    ++_revision;
    _hideFuture = null;
    isVisible = true;
    _enterFuture = animation.forward(from: 0.0);
    return _enterFuture!;
  }

  Future<void> hide({bool waitForEnter = true}) {
    if (!isVisible) return Future<void>.value();
    final existingHide = _hideFuture;
    if (existingHide != null) return existingHide;

    final revision = _revision;
    late final Future<void> hideFuture;
    hideFuture = _hide(revision, waitForEnter: waitForEnter).whenComplete(() {
      if (identical(_hideFuture, hideFuture)) _hideFuture = null;
    });
    _hideFuture = hideFuture;
    return hideFuture;
  }

  Future<void> _hide(int revision, {required bool waitForEnter}) async {
    try {
      if (animation.value > 0.001) {
        if (waitForEnter && _enterFuture != null) await _enterFuture;
        if (revision != _revision || !isVisible) return;
        await animation.reverse();
      } else {
        animation.stop();
        animation.value = 0;
      }
    } catch (_) {}
    if (revision != _revision) return;
    isVisible = false;
  }

  void reset() {
    ++_revision;
    _hideFuture = null;
    _enterFuture = null;
    animation.stop();
    animation.value = 0;
    isVisible = false;
  }

  void dispose() {
    animation.dispose();
  }
}
