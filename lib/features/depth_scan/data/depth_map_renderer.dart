// lib/features/depth_scan/data/depth_map_renderer.dart

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// A rendered depth map together with the scale it was drawn at.
///
/// The bands are returned rather than assumed, because they are not always the
/// default table scale — see [DepthMapRenderer.renderBands].
class DepthBandRender {
  final Uint8List rgba;

  /// Lower bound of each of the eight bands, in cm above [referenceCm].
  final List<double> bandsCm;

  /// Distance of the reference surface from the camera, in cm.
  final double referenceCm;

  /// True when the subject stood too far off the reference surface for the
  /// fixed table scale, and the bands were stretched to fit it instead.
  final bool adaptive;

  /// Highest elevation actually measured, in cm above the reference.
  final double peakElevationCm;

  const DepthBandRender({
    required this.rgba,
    required this.bandsCm,
    required this.referenceCm,
    required this.adaptive,
    required this.peakElevationCm,
  });
}

/// Renders a raw LiDAR Float32 depth buffer into an 8-band discrete relative depth map.
///
/// Darkest band represents the reference surface or below; brightest band
/// represents the highest point. Missing/invalid pixels are rendered as neutral
/// gray.
class DepthMapRenderer {
  /// 8 discrete band thresholds in cm above the reference surface.
  ///
  /// Tuned for food on a plate, which is the case that matters — a portion is
  /// a couple of centimetres tall and the interesting detail is all near the
  /// bottom of the range.
  static const List<double> defaultBandsCm = [
    0.0, // Band 1: At or below the reference surface
    1.0, // Band 2: 0-1 cm
    2.0, // Band 3: 1-2 cm
    3.0, // Band 4: 2-3 cm
    4.0, // Band 5: 3-4 cm
    5.5, // Band 6: 4-5.5 cm
    7.0, // Band 7: 5.5-7 cm
    10.0, // Band 8: >7 cm (brightest)
  ];

  /// 8 discrete Viridis-like RGB palette steps (monotonic brightness).
  static const List<List<int>> bandPaletteRgb = [
    [68, 1, 84], // 1: Deep purple / surface
    [72, 40, 120], // 2
    [62, 74, 137], // 3
    [49, 104, 142], // 4
    [38, 130, 142], // 5
    [31, 158, 137], // 6
    [53, 183, 121], // 7
    [253, 231, 37], // 8: Vibrant yellow / peak
  ];

  static const List<int> invalidPixelRgb = [140, 140, 140]; // Neutral Gray

  /// Beyond this much elevation the fixed table scale has nothing left to say —
  /// every pixel of the subject lands in the top band and the map goes flat.
  static const double _adaptiveThresholdCm = 12.0;

  static bool _isUsable(double v) =>
      v.isFinite && !v.isNaN && v > 0.05 && v < 4.0;

  /// The distance of the surface the subject is sitting in front of.
  ///
  /// Taken from a ring around the edge of the frame rather than the whole
  /// frame: the subject occupies the middle, so a plain median of everything
  /// drifts onto the subject itself as it fills more of the picture.
  static double _referenceMeters(
    Float32List depthBuffer,
    int width,
    int height,
  ) {
    final borderX = math.max(1, (width * 0.12).round());
    final borderY = math.max(1, (height * 0.12).round());

    final ring = <double>[];
    for (int y = 0; y < height; y++) {
      final isEdgeRow = y < borderY || y >= height - borderY;
      for (int x = 0; x < width; x++) {
        if (!isEdgeRow && x >= borderX && x < width - borderX) continue;
        final index = y * width + x;
        if (index >= depthBuffer.length) continue;
        final val = depthBuffer[index];
        if (_isUsable(val)) ring.add(val);
      }
    }

    final samples = ring.length >= 32 ? ring : _allValid(depthBuffer);
    if (samples.isEmpty) return 0.0;
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  static List<double> _allValid(Float32List depthBuffer) {
    final valid = <double>[];
    for (final val in depthBuffer) {
      if (_isUsable(val)) valid.add(val);
    }
    return valid;
  }

  /// Renders the depth buffer and reports the scale it chose.
  static DepthBandRender renderBands({
    required Float32List depthBuffer,
    required int width,
    required int height,
    double? referenceMedianMeters,
    bool useViridis = true,
  }) {
    final rgba = Uint8List(width * height * 4);
    final referenceMeters =
        referenceMedianMeters ?? _referenceMeters(depthBuffer, width, height);

    // How far the subject actually rises off that surface decides the scale.
    // A plate of food stays inside the fixed bands; an object held up in the
    // air is metres away from the wall behind it and would otherwise render as
    // one solid block of the top colour.
    final elevations = <double>[];
    for (final val in depthBuffer) {
      if (!_isUsable(val)) continue;
      final elevationCm = (referenceMeters - val) * 100.0;
      if (elevationCm > 0) elevations.add(elevationCm);
    }
    elevations.sort();
    final peak = elevations.isEmpty
        ? 0.0
        : elevations[((elevations.length * 0.98) - 1)
            .clamp(0, elevations.length - 1)
            .toInt()];

    final adaptive = peak > _adaptiveThresholdCm;
    final bands = adaptive ? _scaledBands(peak) : defaultBandsCm;

    for (int i = 0; i < depthBuffer.length; i++) {
      final val = depthBuffer[i];
      final offset = i * 4;

      if (!_isUsable(val)) {
        rgba[offset] = invalidPixelRgb[0];
        rgba[offset + 1] = invalidPixelRgb[1];
        rgba[offset + 2] = invalidPixelRgb[2];
        rgba[offset + 3] = 255;
        continue;
      }

      // Closer to the camera means a smaller distance, so a higher elevation.
      final elevationCm = (referenceMeters - val) * 100.0;

      int bandIndex = 0;
      for (int b = 0; b < bands.length; b++) {
        if (elevationCm >= bands[b]) bandIndex = b;
      }

      final color = useViridis
          ? bandPaletteRgb[bandIndex.clamp(0, 7)]
          : [
              (bandIndex * 32).clamp(0, 255),
              (bandIndex * 32).clamp(0, 255),
              (bandIndex * 32).clamp(0, 255),
            ];

      rgba[offset] = color[0];
      rgba[offset + 1] = color[1];
      rgba[offset + 2] = color[2];
      rgba[offset + 3] = 255;
    }

    return DepthBandRender(
      rgba: rgba,
      bandsCm: bands,
      referenceCm: referenceMeters * 100.0,
      adaptive: adaptive,
      peakElevationCm: peak,
    );
  }

  /// The default band shape stretched to span [peakCm].
  ///
  /// Keeps the ramp's relative spacing — dense at the bottom, coarse at the
  /// top — so the picture reads the same way at either scale.
  static List<double> _scaledBands(double peakCm) {
    final top = defaultBandsCm.last;
    final factor = peakCm / top;
    return defaultBandsCm
        .map((cm) => double.parse((cm * factor).toStringAsFixed(1)))
        .toList(growable: false);
  }

  /// Renders the depth buffer to an RGBA byte buffer (width * height * 4 bytes).
  static Uint8List renderToRgba({
    required Float32List depthBuffer,
    required int width,
    required int height,
    double? referenceMedianMeters,
    bool useViridis = true,
  }) =>
      renderBands(
        depthBuffer: depthBuffer,
        width: width,
        height: height,
        referenceMedianMeters: referenceMedianMeters,
        useViridis: useViridis,
      ).rgba;

  /// Converts the depth buffer into a [ui.Image] plus the scale it was drawn at.
  static Future<({ui.Image image, DepthBandRender render})> createUiImage({
    required Float32List depthBuffer,
    required int width,
    required int height,
    bool useViridis = true,
  }) async {
    final render = renderBands(
      depthBuffer: depthBuffer,
      width: width,
      height: height,
      useViridis: useViridis,
    );

    final descriptor = ui.ImageDescriptor.raw(
      await ui.ImmutableBuffer.fromUint8List(render.rgba),
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return (image: frame.image, render: render);
  }
}
