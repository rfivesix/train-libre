// lib/features/depth_scan/data/depth_map_renderer.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

/// Renders a raw LiDAR Float32 depth buffer into an 8-band discrete relative depth map.
///
/// Darkest band represents table surface or below; brightest band represents the highest point.
/// Missing/invalid pixels are rendered as neutral gray.
class DepthMapRenderer {
  /// 8 discrete grayscale/palette band thresholds in cm above table surface.
  static const List<double> defaultBandsCm = [
    0.0,  // Band 1: At or below table level
    1.0,  // Band 2: 0-1 cm
    2.0,  // Band 3: 1-2 cm
    3.0,  // Band 4: 2-3 cm
    4.0,  // Band 5: 3-4 cm
    5.5,  // Band 6: 4-5.5 cm
    7.0,  // Band 7: 5.5-7 cm
    10.0, // Band 8: >7 cm (brightest)
  ];

  /// 8 discrete Viridis-like RGB palette steps (monotonic brightness).
  static const List<List<int>> bandPaletteRgb = [
    [68, 1, 84],     // 1: Deep purple / surface
    [72, 40, 120],   // 2
    [62, 74, 137],   // 3
    [49, 104, 142],  // 4
    [38, 130, 142],  // 5
    [31, 158, 137],  // 6
    [53, 183, 121],  // 7
    [253, 231, 37],  // 8: Vibrant yellow / peak
  ];

  static const List<int> invalidPixelRgb = [140, 140, 140]; // Neutral Gray

  /// Renders the depth buffer to an RGBA byte buffer (width * height * 4 bytes).
  static Uint8List renderToRgba({
    required Float32List depthBuffer,
    required int width,
    required int height,
    double? referenceMedianMeters,
    bool useViridis = true,
  }) {
    final rgba = Uint8List(width * height * 4);

    // Calculate median if not provided
    double medianMeters = referenceMedianMeters ?? 0.0;
    if (referenceMedianMeters == null) {
      final valid = <double>[];
      for (final val in depthBuffer) {
        if (val.isFinite && !val.isNaN && val > 0.05 && val < 4.0) {
          valid.add(val);
        }
      }
      if (valid.isNotEmpty) {
        valid.sort();
        medianMeters = valid[valid.length ~/ 2];
      }
    }

    for (int i = 0; i < depthBuffer.length; i++) {
      final val = depthBuffer[i];
      final offset = i * 4;

      if (!val.isFinite || val.isNaN || val <= 0.05 || val > 4.0) {
        rgba[offset] = invalidPixelRgb[0];
        rgba[offset + 1] = invalidPixelRgb[1];
        rgba[offset + 2] = invalidPixelRgb[2];
        rgba[offset + 3] = 255;
        continue;
      }

      // Height in cm above the median table surface
      // (closer to camera means smaller distance z -> higher relative elevation)
      final elevationCm = (medianMeters - val) * 100.0;

      int bandIndex = 0;
      for (int b = 0; b < defaultBandsCm.length; b++) {
        if (elevationCm >= defaultBandsCm[b]) {
          bandIndex = b;
        }
      }

      final color = useViridis
          ? bandPaletteRgb[bandIndex.clamp(0, 7)]
          : [
              (bandIndex * 32).clamp(0, 255),
              (bandIndex * 32).clamp(0, 255),
              (bandIndex * 32).clamp(0, 255)
            ];

      rgba[offset] = color[0];
      rgba[offset + 1] = color[1];
      rgba[offset + 2] = color[2];
      rgba[offset + 3] = 255;
    }

    return rgba;
  }

  /// Converts RGBA buffer into a [ui.Image] for rendering in UI.
  static Future<ui.Image> createUiImage({
    required Float32List depthBuffer,
    required int width,
    required int height,
  }) async {
    final rgba = renderToRgba(
      depthBuffer: depthBuffer,
      width: width,
      height: height,
    );

    final pixels = rgba.buffer.asUint8List();
    final descriptor = ui.ImageDescriptor.raw(
      await ui.ImmutableBuffer.fromUint8List(pixels),
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
