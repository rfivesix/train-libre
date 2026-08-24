// lib/features/depth_scan/data/depth_scan_settings.dart

import 'package:shared_preferences/shared_preferences.dart';

/// User-facing switches for the LiDAR scale hint.
///
/// The hint exists to make portion estimates better, and whether it actually
/// does is an open question. Keeping it switchable lets the same meal be
/// photographed twice — once with, once without — which is the only way to
/// judge the effect on real food rather than on a hunch.
class DepthScanSettings {
  static final DepthScanSettings instance = DepthScanSettings._();
  DepthScanSettings._();

  static const String scaleHintKey = 'depth_scan_scale_hint_enabled';

  bool? _cached;

  Future<bool> isScaleHintEnabled() async {
    final cached = _cached;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(scaleHintKey) ?? true;
    _cached = value;
    return value;
  }

  Future<void> setScaleHintEnabled(bool enabled) async {
    _cached = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(scaleHintKey, enabled);
  }
}
