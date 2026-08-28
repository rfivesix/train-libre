import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

typedef DeviceLabelLoader = Future<String> Function();

/// Resolves a short, human-readable device name for the performance report.
///
/// "9.7% jank" says little without the hardware that produced it — the same
/// screen behaves differently on an iPhone 12 mini and on a current Pro. The
/// identifier is a model name shared by millions of devices, so it describes
/// hardware rather than a person.
class DeviceLabel {
  const DeviceLabel._();

  static const String unavailable = 'unavailable';

  static String? _cached;

  static Future<String> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final resolved = await _resolve();
    _cached = resolved;
    return resolved;
  }

  @visibleForTesting
  static void clearCacheForTest() => _cached = null;

  static Future<String> _resolve() async {
    if (kIsWeb) return unavailable;

    try {
      final plugin = DeviceInfoPlugin();

      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        // `utsname.machine` is the model identifier (e.g. iPhone14,4); it is
        // what maps to an actual device generation, while `model` only ever
        // says "iPhone".
        final machine = info.utsname.machine.trim();
        final model = info.model.trim();
        if (machine.isNotEmpty) {
          return model.isEmpty ? machine : '$model ($machine)';
        }
        return model.isEmpty ? unavailable : model;
      }

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final manufacturer = info.manufacturer.trim();
        final model = info.model.trim();
        final label = [manufacturer, model]
            .where((part) => part.isNotEmpty)
            .join(' ')
            .trim();
        return label.isEmpty ? unavailable : label;
      }

      return Platform.operatingSystem;
    } catch (error) {
      debugPrint('[perf] reading device model failed: $error');
      return unavailable;
    }
  }
}
