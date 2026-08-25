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
  static const String depthImageKey = 'depth_scan_depth_image_enabled';

  bool? _cached;
  bool? _depthImageCached;

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

  /// Whether the depth map is sent to the model as a second image next to the
  /// photo, on top of the measured numbers.
  ///
  /// Separate from the scale hint so the two can be judged apart: the numbers
  /// are cheap and certain, the picture costs a second image per analysis and
  /// its worth is exactly the open question.
  Future<bool> isDepthImageEnabled() async {
    final cached = _depthImageCached;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(depthImageKey) ?? true;
    _depthImageCached = value;
    return value;
  }

  Future<void> setDepthImageEnabled(bool enabled) async {
    _depthImageCached = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(depthImageKey, enabled);
  }
}
