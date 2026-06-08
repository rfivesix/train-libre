import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Manages dynamic rendering quality of glassmorphic shaders based on real-time performance.
class GlassPerformanceManager with WidgetsBindingObserver {
  static final GlassPerformanceManager _instance =
      GlassPerformanceManager._internal();

  factory GlassPerformanceManager() => _instance;

  GlassPerformanceManager._internal() {
    _init();
  }

  /// Active quality tier notifier.
  final ValueNotifier<GlassQuality> qualityNotifier =
      ValueNotifier<GlassQuality>(GlassQuality.premium);

  /// Precise hardware frame budget dynamically derived
  late Duration _frameBudget;

  /// Sliding window of the last 60 frames (raster durations)
  final List<Duration> _frameTimingsWindow = [];
  static const int _windowSize = 60;

  /// Anti-oscillation cooldown guard
  DateTime _lastAdjustmentTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _cooldownDuration = Duration(seconds: 8);

  /// Viewport idle state guard
  bool _isViewportIdle = true;
  Timer? _idleTimer;
  static const Duration _idleThreshold = Duration(seconds: 3);

  /// App lifecycle persistence
  DateTime? _pausedTimestamp;
  bool _isSubscribed = false;

  void _init() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    double refreshRate = 60.0;
    if (dispatcher.views.isNotEmpty) {
      final viewRefreshRate = dispatcher.views.first.display.refreshRate;
      if (viewRefreshRate > 0) {
        refreshRate = viewRefreshRate;
      }
    }
    _frameBudget = Duration(microseconds: (1e6 / refreshRate).round());

    WidgetsBinding.instance.addObserver(this);
    _attachTimingsCallback();
  }

  void _attachTimingsCallback() {
    if (_isSubscribed) return;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    _isSubscribed = true;
  }

  void _detachTimingsCallback() {
    if (!_isSubscribed) return;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _isSubscribed = false;
  }

  /// Records user interaction to track viewport idle status.
  void recordUserInteraction() {
    _isViewportIdle = false;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleThreshold, () {
      _isViewportIdle = true;
    });
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      // Measure EXCLUSIVELY FrameTiming.rasterDuration (ignore totalSpan to prevent VSync pollution)
      final raster = timing.rasterDuration;
      _frameTimingsWindow.add(raster);
      if (_frameTimingsWindow.length > _windowSize) {
        _frameTimingsWindow.removeAt(0);
      }
    }

    if (_frameTimingsWindow.length < _windowSize) {
      return;
    }

    _evaluateQuality();
  }

  void _evaluateQuality() {
    final now = DateTime.now();
    if (now.difference(_lastAdjustmentTime) < _cooldownDuration) {
      return;
    }

    int slowFramesCount = 0;
    for (final duration in _frameTimingsWindow) {
      if (duration > _frameBudget) {
        slowFramesCount++;
      }
    }

    final slowRatio = slowFramesCount / _windowSize;
    final currentQuality = qualityNotifier.value;

    if (slowRatio > 0.25) {
      // Downgrade quality
      GlassQuality targetQuality;
      if (currentQuality == GlassQuality.premium) {
        targetQuality = GlassQuality.standard;
      } else {
        targetQuality = GlassQuality.minimal;
      }

      if (targetQuality != currentQuality) {
        _setQuality(targetQuality, now);
      }
    } else if (slowRatio < 0.05) {
      // Upgrade quality
      GlassQuality targetQuality;
      if (currentQuality == GlassQuality.minimal) {
        targetQuality = GlassQuality.standard;
      } else if (currentQuality == GlassQuality.standard) {
        if (_isViewportIdle) {
          targetQuality = GlassQuality.premium;
        } else {
          return; // Strictly block upgrades to premium if viewport is not idle
        }
      } else {
        return; // Already premium
      }

      if (targetQuality != currentQuality) {
        _setQuality(targetQuality, now);
      }
    }
  }

  void _setQuality(GlassQuality newQuality, DateTime timestamp) {
    qualityNotifier.value = newQuality;
    _lastAdjustmentTime = timestamp;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _detachTimingsCallback();
      _pausedTimestamp = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTimestamp != null) {
        final staleness = DateTime.now().difference(_pausedTimestamp!);
        if (staleness > const Duration(minutes: 30)) {
          _setQuality(GlassQuality.premium, DateTime.now());
        }
      }
      _attachTimingsCallback();
    }
  }

  /// Cleans up resources.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachTimingsCallback();
    _idleTimer?.cancel();
    qualityNotifier.dispose();
  }
}
