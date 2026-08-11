import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models/home_widget_snapshot.dart';

/// Thin wrapper around the `trainlibre.widgets/home_screen` MethodChannel.
///
/// Deliberately no `home_widget` package: writing a JSON string into an App
/// Group and calling `WidgetCenter.reloadTimelines` is a handful of lines, and
/// the Live Activity already establishes the hand-rolled-channel pattern.
class HomeWidgetChannel {
  static const MethodChannel _channel =
      MethodChannel('trainlibre.widgets/home_screen');

  const HomeWidgetChannel();

  /// Cached so the widget-less majority of platforms pays one channel call per
  /// process rather than one per diary mutation.
  static bool? _isSupported;

  Future<bool> isSupported() async {
    if (!(!kIsWeb && Platform.isIOS)) return false;
    final cached = _isSupported;
    if (cached != null) return cached;
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return _isSupported = result ?? false;
    } on PlatformException catch (e) {
      debugPrint('HomeWidgetChannel.isSupported failed: ${e.message}');
      return _isSupported = false;
    } on MissingPluginException {
      return _isSupported = false;
    }
  }

  Future<bool> writeSnapshot(HomeWidgetSnapshot snapshot) async {
    if (!await isSupported()) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'writeSnapshot',
        {'json': snapshot.encode()},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('HomeWidgetChannel.writeSnapshot failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The App Group file name of the muscle heatmap rendered for [workoutId].
  ///
  /// The id is part of the name so a snapshot can never point the widget at
  /// another session's heatmap; the native side sweeps older files with the same
  /// prefix whenever a new one arrives.
  static String workoutHeatmapFileName(int workoutId) =>
      'last_workout_heatmap_$workoutId.png';

  /// Whether [name] is already in the App Group container.
  ///
  /// Lets the sync service skip a render it has already paid for — the file
  /// outlives the app process, so an in-memory flag would re-render once per
  /// launch for nothing.
  Future<bool> sharedFileExists(String name) async {
    if (!await isSupported()) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'sharedFileExists',
        {'name': name},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('HomeWidgetChannel.sharedFileExists failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Stores a binary asset in the App Group container under [name].
  ///
  /// Passing null [bytes] deletes it.
  Future<bool> writeSharedFile(String name, Uint8List? bytes) async {
    if (!await isSupported()) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'writeSharedFile',
        {'name': name, 'bytes': bytes},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('HomeWidgetChannel.writeSharedFile failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> clearSnapshot() async {
    if (!await isSupported()) return false;
    try {
      final result = await _channel.invokeMethod<bool>('clearSnapshot');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('HomeWidgetChannel.clearSnapshot failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @visibleForTesting
  static void resetSupportCache() => _isSupported = null;
}
