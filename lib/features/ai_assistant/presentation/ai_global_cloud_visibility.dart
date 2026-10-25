import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Tracks temporary app surfaces that should move the global AI cloud away.
///
/// Callers acquire a lease for the lifetime of a screen or presentation. The
/// cloud is visible again only after every overlapping lease has been released.
class AiGlobalCloudVisibility {
  AiGlobalCloudVisibility._();

  static final ValueNotifier<int> _suppressionCount = ValueNotifier<int>(0);
  static int _suppressionCountValue = 0;
  static bool _notificationScheduled = false;

  static ValueListenable<int> get suppressionCount => _suppressionCount;

  static bool get isVisible => _suppressionCountValue == 0;

  static AiGlobalCloudVisibilityLease suppress() {
    _suppressionCountValue++;
    _publishSuppressionCount();
    return AiGlobalCloudVisibilityLease._();
  }

  static void _release() {
    assert(_suppressionCountValue > 0);
    if (_suppressionCountValue > 0) _suppressionCountValue--;
    _publishSuppressionCount();
  }

  static void _publishSuppressionCount() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_notificationScheduled) return;
      _notificationScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notificationScheduled = false;
        if (_suppressionCount.value != _suppressionCountValue) {
          _suppressionCount.value = _suppressionCountValue;
        }
      });
      return;
    }
    if (_suppressionCount.value != _suppressionCountValue) {
      _suppressionCount.value = _suppressionCountValue;
    }
  }
}

/// A single, idempotently releasable reason for hiding the global AI cloud.
class AiGlobalCloudVisibilityLease {
  AiGlobalCloudVisibilityLease._();

  bool _isReleased = false;

  void dispose() {
    if (_isReleased) return;
    _isReleased = true;
    AiGlobalCloudVisibility._release();
  }
}
