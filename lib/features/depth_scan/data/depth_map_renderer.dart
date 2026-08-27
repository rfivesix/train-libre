// lib/features/depth_scan/data/depth_map_renderer.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

/// A rendered depth map together with the scale it was drawn at.
class DepthBandRender {
  final Uint8List rgba;

  /// Distance the brightest band starts at; anything closer shares it.
  final double minDistanceCm;

  /// Distance the darkest band starts at; everything beyond shares it.
  final double maxDistanceCm;

  /// Width of one band in cm.
  final double stepCm;

  /// Share of measured pixels that fell outside [minDistanceCm]..[maxDistanceCm]
  /// and were therefore clamped into the end bands.
  final double outsideRangeFraction;

  /// True when the range was derived from the frame rather than given.
  final bool autoRanged;

  /// Closest and farthest measured distance in the frame, in cm.
  final double nearestCm;
  final double farthestCm;

  /// Share of the frame the sensor returned no usable reading for.
  final double invalidFraction;

  const DepthBandRender({
    required this.rgba,
    required this.minDistanceCm,
    required this.maxDistanceCm,
    required this.stepCm,
    required this.outsideRangeFraction,
    required this.nearestCm,
    required this.farthestCm,
    required this.invalidFraction,
    required this.autoRanged,
    required this.palette,
  });

  /// The colours the bands were drawn with, index 0 farthest.
  final List<List<int>> palette;

  int get bandCount => palette.length;

  /// Distance range covered by [index], nearest band last.
  ({double fromCm, double toCm}) rangeOf(int index) {
    final fromCm = minDistanceCm + (bandCount - 1 - index) * stepCm;
    return (fromCm: fromCm, toCm: fromCm + stepCm);
  }
}

/// Renders a raw depth buffer into discrete bands of absolute distance.
///
/// Bands are plain distance from the camera, not height above whatever happens
/// to be behind the subject. The earlier version derived a reference plane from
/// the frame and coloured everything relative to it, which only made sense when
/// the subject really was sitting on a surface that filled the background —
/// point the camera at a room and the "reference" lands on a wall metres away,
/// and the picture stops meaning anything.
///
/// By default the ramp spans what the frame actually contains rather than a
/// fixed window: a plate that sits between 24 and 31 cm gets the whole ramp,
/// where a fixed 0-80 cm scale would have painted it in one colour. See
/// [defaultBandCount] for how finely the ramp is cut. Missing readings are
/// rendered as neutral gray.
class DepthMapRenderer {
  /// Far end used when the frame holds too little to measure a range from.
  static const double defaultMaxDistanceCm = 80.0;

  /// Narrowest auto range. Below this the bands would be finer than the
  /// sensor's own noise and the picture would show that noise, not the food.
  static const double minAutoSpanCm = 4.0;

  /// Percentile the auto range is cut at, at both ends.
  ///
  /// A handful of stray readings — a speck of sensor noise, one pixel of the
  /// window frame behind — would otherwise stretch the ramp over metres and
  /// undo the whole point of fitting it to the subject.
  static const double _autoClipPercentile = 0.02;

  /// How many bands the ramp is cut into.
  ///
  /// Eight was far too coarse to read a portion off: across a plate spanning
  /// eight centimetres each band covered a full centimetre, and rice heaped in
  /// the middle looked the same as rice spread flat.
  ///
  /// Forty puts the steps at two millimetres on that same plate. That is finer
  /// than the sensor's own noise, which is roughly one percent of distance —
  /// so the last few bands describe noise rather than food. They are kept
  /// anyway: at this density the picture stops reading as bands at all and
  /// becomes a smooth relief, and the extra dithering along an edge is a fairer
  /// picture of an uncertain measurement than a hard line would be.
  static const int defaultBandCount = 40;

  /// Viridis control points, farthest (dark) to nearest (bright).
  ///
  /// Sampled rather than listed per band so the band count can change without
  /// anyone hand-picking twenty colours. Viridis is perceptually uniform, so
  /// plain RGB interpolation between neighbouring stops holds up.
  static const List<List<int>> viridisAnchors = [
    [68, 1, 84],
    [72, 40, 120],
    [62, 74, 137],
    [49, 104, 142],
    [38, 130, 142],
    [31, 158, 137],
    [53, 183, 121],
    [109, 205, 89],
    [180, 222, 44],
    [253, 231, 37],
  ];

  /// [count] colours sampled off the ramp, index 0 farthest.
  static List<List<int>> paletteFor(int count, {bool viridis = true}) {
    if (count < 2) return [viridisAnchors.last];
    return List.generate(count, (i) {
      final t = i / (count - 1);
      if (!viridis) {
        final grey = (t * 255).round().clamp(0, 255);
        return [grey, grey, grey];
      }
      final scaled = t * (viridisAnchors.length - 1);
      final low = scaled.floor().clamp(0, viridisAnchors.length - 1);
      final high = (low + 1).clamp(0, viridisAnchors.length - 1);
      final f = scaled - low;
      return List.generate(
        3,
        (c) => (viridisAnchors[low][c] +
                (viridisAnchors[high][c] - viridisAnchors[low][c]) * f)
            .round()
            .clamp(0, 255),
      );
    });
  }

  static const List<int> invalidPixelRgb = [140, 140, 140]; // Neutral Gray

  static bool _isUsable(double v) =>
      v.isFinite && !v.isNaN && v > 0.05 && v < 6.0;

  /// The span the frame's own readings occupy, clipped at both ends.
  static ({double minCm, double maxCm})? _autoRange(Float32List depthBuffer) {
    final valid = <double>[];
    for (final value in depthBuffer) {
      if (_isUsable(value)) valid.add(value * 100.0);
    }
    if (valid.length < 32) return null;

    valid.sort();
    final lowIndex = (valid.length * _autoClipPercentile).floor();
    final highIndex = (valid.length * (1 - _autoClipPercentile))
        .ceil()
        .clamp(0, valid.length - 1);

    var minCm = valid[lowIndex];
    var maxCm = valid[highIndex];
    if (maxCm - minCm < minAutoSpanCm) {
      final centre = (minCm + maxCm) / 2;
      minCm = centre - minAutoSpanCm / 2;
      maxCm = centre + minAutoSpanCm / 2;
    }
    if (minCm < 0) minCm = 0;
    return (minCm: minCm, maxCm: maxCm);
  }

  /// Renders the depth buffer and reports the scale it was drawn at.
  ///
  /// Leaving both bounds null fits the ramp to the frame — see [_autoRange].
  static DepthBandRender renderBands({
    required Float32List depthBuffer,
    required int width,
    required int height,
    double? minDistanceCm,
    double? maxDistanceCm,
    int bandCount = defaultBandCount,
    bool useViridis = true,
  }) {
    final rgba = Uint8List(width * height * 4);
    final palette = paletteFor(bandCount, viridis: useViridis);

    final autoRanged = minDistanceCm == null && maxDistanceCm == null;
    final auto = autoRanged ? _autoRange(depthBuffer) : null;
    final rampMin = auto?.minCm ?? minDistanceCm ?? 0.0;
    final rampMax = auto?.maxCm ?? maxDistanceCm ?? defaultMaxDistanceCm;
    final span = (rampMax - rampMin).abs() < 0.001
        ? defaultMaxDistanceCm
        : rampMax - rampMin;
    final stepCm = span / bandCount;

    var valid = 0;
    var outside = 0;
    var nearest = double.infinity;
    var farthest = 0.0;

    for (int i = 0; i < depthBuffer.length; i++) {
      final value = depthBuffer[i];
      final offset = i * 4;

      if (!_isUsable(value)) {
        rgba[offset] = invalidPixelRgb[0];
        rgba[offset + 1] = invalidPixelRgb[1];
        rgba[offset + 2] = invalidPixelRgb[2];
        rgba[offset + 3] = 255;
        continue;
      }

      final distanceCm = value * 100.0;
      valid++;
      if (distanceCm < nearest) nearest = distanceCm;
      if (distanceCm > farthest) farthest = distanceCm;
      if (distanceCm < rampMin || distanceCm >= rampMax) outside++;

      // Nearest gets the brightest band; both ends absorb whatever lies past
      // them rather than being left unpainted.
      final stepsAway = ((distanceCm - rampMin) / stepCm).floor();
      final bandIndex = (bandCount - 1 - stepsAway).clamp(0, bandCount - 1);

      final color = palette[bandIndex];

      rgba[offset] = color[0];
      rgba[offset + 1] = color[1];
      rgba[offset + 2] = color[2];
      rgba[offset + 3] = 255;
    }

    final total = depthBuffer.isEmpty ? 1 : depthBuffer.length;
    return DepthBandRender(
      rgba: rgba,
      minDistanceCm: rampMin,
      maxDistanceCm: rampMin + span,
      stepCm: stepCm,
      outsideRangeFraction: valid == 0 ? 0 : outside / valid,
      nearestCm: valid == 0 ? 0 : nearest,
      farthestCm: farthest,
      invalidFraction: (total - valid) / total,
      autoRanged: autoRanged && auto != null,
      palette: palette,
    );
  }

  /// Renders the depth buffer to an RGBA byte buffer (width * height * 4 bytes).
  static Uint8List renderToRgba({
    required Float32List depthBuffer,
    required int width,
    required int height,
    double? minDistanceCm,
    double? maxDistanceCm,
    int bandCount = defaultBandCount,
    bool useViridis = true,
  }) =>
      renderBands(
        depthBuffer: depthBuffer,
        width: width,
        height: height,
        minDistanceCm: minDistanceCm,
        maxDistanceCm: maxDistanceCm,
        bandCount: bandCount,
        useViridis: useViridis,
      ).rgba;

  /// Converts the depth buffer into a [ui.Image] plus the scale it was drawn at.
  static Future<({ui.Image image, DepthBandRender render})> createUiImage({
    required Float32List depthBuffer,
    required int width,
    required int height,
    double? minDistanceCm,
    double? maxDistanceCm,
    int bandCount = defaultBandCount,
    bool useViridis = true,
  }) async {
    final render = renderBands(
      depthBuffer: depthBuffer,
      width: width,
      height: height,
      minDistanceCm: minDistanceCm,
      maxDistanceCm: maxDistanceCm,
      bandCount: bandCount,
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
