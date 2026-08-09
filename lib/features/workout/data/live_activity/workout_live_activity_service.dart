import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/live_activity/workout_live_activity_content.dart';

/// Thin wrapper around the ActivityKit bridge in `AppDelegate`.
///
/// Deliberately no plugin dependency: the payload is specific to this feature,
/// and an offline-first app should not take on a package for ~100 lines of
/// Swift.
class WorkoutLiveActivityService {
  static const MethodChannel _channel =
      MethodChannel('trainlibre.workout/live_activity');

  static WorkoutLiveActivityService instance = WorkoutLiveActivityService();

  @visibleForTesting
  WorkoutLiveActivityService();

  bool get isPlatformSupported => !kIsWeb && Platform.isIOS;

  WorkoutLiveActivityContent? _lastContent;

  Future<bool> isSupported() async {
    if (!isPlatformSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> start({
    required WorkoutLiveActivityAttributes attributes,
    required WorkoutLiveActivityContent content,
  }) async {
    if (!isPlatformSupported) return;
    _lastContent = content;
    await _invoke('start', {...attributes.toMap(), ...content.toMap()});
  }

  /// No-op when nothing visible changed — every push costs a system refresh,
  /// and the timer fields animate on their own.
  Future<void> update(WorkoutLiveActivityContent content) async {
    if (!isPlatformSupported) return;
    if (_lastContent == content) return;
    _lastContent = content;
    await _invoke('update', content.toMap());
  }

  /// Schedules the "rest is over" sound natively.
  ///
  /// Native rather than through `LocalNotificationService` so the Live
  /// Activity's App Intents can move it when the pause is extended or skipped
  /// while the app is suspended.
  Future<void> scheduleRestSound({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    if (!isPlatformSupported) return;
    await _invoke('scheduleRestSound', {
      'endsAtEpochMs': endsAt.millisecondsSinceEpoch,
      'title': title,
      'body': body,
    });
  }

  Future<void> cancelRestSound() async {
    if (!isPlatformSupported) return;
    await _invoke('cancelRestSound', null);
  }

  Future<void> end() async {
    if (!isPlatformSupported) return;
    _lastContent = null;
    await _invoke('end', null);
  }

  /// Commands produced by Live Activity buttons while the app was suspended or
  /// terminated. Consuming clears the queue, so the caller must apply them.
  Future<List<Map<String, Object?>>> consumePendingCommands() async {
    if (!isPlatformSupported) return const [];
    try {
      final raw = await _channel
          .invokeListMethod<Map<Object?, Object?>>('consumePendingCommands');
      if (raw == null) return const [];
      return raw
          .map((entry) => entry.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    } on PlatformException catch (error) {
      debugPrint('Live Activity: consumePendingCommands failed: $error');
      return const [];
    }
  }

  Future<void> _invoke(String method, Object? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (error) {
      // A failing Live Activity must never take the workout down with it.
      debugPrint('Live Activity: $method failed: $error');
    } on MissingPluginException {
      // Older build without the extension embedded.
    }
  }
}
