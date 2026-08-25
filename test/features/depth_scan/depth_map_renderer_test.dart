// test/features/depth_scan/depth_map_renderer_test.dart

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/depth_scan/data/depth_map_renderer.dart';

/// Band index the pixel at [i] was painted with, or null when it was drawn as
/// an unmeasured pixel.
int? _bandAt(Uint8List rgba, int i, {int bands = 8}) {
  final rgb = [rgba[i * 4], rgba[i * 4 + 1], rgba[i * 4 + 2]];
  final palette = DepthMapRenderer.paletteFor(bands);
  for (var band = 0; band < palette.length; band++) {
    if (rgb[0] == palette[band][0] &&
        rgb[1] == palette[band][1] &&
        rgb[2] == palette[band][2]) {
      return band;
    }
  }
  return null;
}

void main() {
  group('DepthMapRenderer bands absolute distance', () {
    /// Distances in metres, one pixel each.
    /// Eight bands, so one band is a round ten centimetres over the 0-80 range
    /// and the expectations below stay readable.
    Uint8List renderDistances(List<double> metres, {double maxCm = 80}) {
      return DepthMapRenderer.renderToRgba(
        depthBuffer: Float32List.fromList(metres),
        width: metres.length,
        height: 1,
        minDistanceCm: 0,
        maxDistanceCm: maxCm,
        bandCount: 8,
      );
    }

    test('the nearest band is the brightest one', () {
      final rgba = renderDistances([0.05001, 0.09]);
      expect(_bandAt(rgba, 0), 7);
      expect(_bandAt(rgba, 1), 7);
    });

    test('walks down the ramp one band per step', () {
      // 80 cm over 8 bands is a 10 cm step.
      final rgba = renderDistances([0.05001, 0.15, 0.25, 0.35]);
      expect(_bandAt(rgba, 0), 7); // 0-10 cm
      expect(_bandAt(rgba, 1), 6); // 10-20 cm
      expect(_bandAt(rgba, 2), 5); // 20-30 cm
      expect(_bandAt(rgba, 3), 4); // 30-40 cm
    });

    test('everything at or beyond the far end shares the darkest band', () {
      final rgba = renderDistances([0.80, 1.5, 3.0]);
      expect(_bandAt(rgba, 0), 0);
      expect(_bandAt(rgba, 1), 0);
      expect(_bandAt(rgba, 2), 0);
    });

    test('a shorter range spreads the same subject over more bands', () {
      // The case the fixed scale flattened: a plate at 22-37 cm. Values are
      // picked mid-band on purpose — Float32 rounds 0.35 down to 34.9999 cm,
      // and a test sitting exactly on a boundary would assert on that noise
      // rather than on the banding.
      final near = DepthMapRenderer.renderToRgba(
        depthBuffer: Float32List.fromList([0.22, 0.37]),
        width: 2,
        height: 1,
        minDistanceCm: 0,
        maxDistanceCm: 40,
        bandCount: 8,
      );
      expect(_bandAt(near, 0), 3); // 20-25 cm
      expect(_bandAt(near, 1), 0); // 35-40 cm
    });

    test('unmeasured pixels stay neutral gray', () {
      final rgba = renderDistances([double.nan, 0.0, 12.0]);
      for (var i = 0; i < 3; i++) {
        expect(_bandAt(rgba, i), isNull);
        expect(rgba[i * 4], DepthMapRenderer.invalidPixelRgb[0]);
        expect(rgba[i * 4 + 3], 255);
      }
    });

    test('reports the measured range and what fell outside it', () {
      final render = DepthMapRenderer.renderBands(
        depthBuffer: Float32List.fromList([0.20, 0.40, 2.00, double.nan]),
        width: 4,
        height: 1,
        minDistanceCm: 0,
        maxDistanceCm: 80,
        bandCount: 8,
      );

      expect(render.nearestCm, closeTo(20, 0.01));
      expect(render.farthestCm, closeTo(200, 0.01));
      expect(render.outsideRangeFraction, closeTo(1 / 3, 0.01));
      expect(render.invalidFraction, closeTo(0.25, 0.01));
      expect(render.stepCm, 10);
    });

    test('band ranges read from nearest to farthest', () {
      final render = DepthMapRenderer.renderBands(
        depthBuffer: Float32List.fromList([0.20]),
        width: 1,
        height: 1,
        minDistanceCm: 0,
        maxDistanceCm: 80,
        bandCount: 8,
      );

      expect(render.rangeOf(7).fromCm, 0);
      expect(render.rangeOf(7).toCm, 10);
      expect(render.rangeOf(0).fromCm, 70);
    });

    test('auto range fits the eight bands to what the frame contains', () {
      // A plate between 24 and 32 cm. On the fixed 0-80 scale every one of
      // these lands in the same band and the picture says nothing.
      final metres = List<double>.generate(200, (i) => 0.24 + (i % 80) * 0.001);
      final render = DepthMapRenderer.renderBands(
        depthBuffer: Float32List.fromList(metres),
        width: metres.length,
        height: 1,
        bandCount: 8,
      );

      expect(render.autoRanged, isTrue);
      expect(render.minDistanceCm, closeTo(24, 0.5));
      expect(render.maxDistanceCm, closeTo(32, 0.5));
      expect(render.stepCm, closeTo(1.0, 0.15));

      // And the bands are actually used rather than collapsing onto one.
      final used = <int?>{};
      for (var i = 0; i < metres.length; i++) {
        used.add(_bandAt(render.rgba, i));
      }
      expect(used.length, greaterThan(5));
    });

    test('auto range widens when everything sits at one distance', () {
      final metres = List<double>.filled(100, 0.30);
      final render = DepthMapRenderer.renderBands(
        depthBuffer: Float32List.fromList(metres),
        width: metres.length,
        height: 1,
      );

      // Bands finer than the sensor's noise would render noise, not food.
      expect(
        render.maxDistanceCm - render.minDistanceCm,
        closeTo(DepthMapRenderer.minAutoSpanCm, 0.01),
      );
    });

    test('too few readings to measure a range falls back to the fixed one', () {
      final render = DepthMapRenderer.renderBands(
        depthBuffer: Float32List.fromList([0.2, 0.3, 0.4]),
        width: 3,
        height: 1,
      );

      expect(render.autoRanged, isFalse);
      expect(render.minDistanceCm, 0);
      expect(render.maxDistanceCm, DepthMapRenderer.defaultMaxDistanceCm);
    });

    test('twenty bands resolve a plate at millimetre scale', () {
      // 24 to 32 cm across twenty bands is four millimetres per step. At eight
      // bands the same plate got one centimetre, which could not tell heaped
      // rice from flat rice.
      final metres = List<double>.generate(400, (i) => 0.24 + (i % 80) * 0.001);
      final render = DepthMapRenderer.renderBands(
        depthBuffer: Float32List.fromList(metres),
        width: metres.length,
        height: 1,
      );

      expect(render.bandCount, DepthMapRenderer.defaultBandCount);
      expect(render.stepCm, lessThan(0.3));

      final used = <int?>{};
      for (var i = 0; i < metres.length; i++) {
        used.add(_bandAt(render.rgba, i, bands: render.bandCount));
      }
      expect(used.length, greaterThan(25));
    });

    test('the palette runs dark to bright and matches the band count', () {
      final palette = DepthMapRenderer.paletteFor(20);
      expect(palette, hasLength(20));
      // Farthest is the darkest, nearest the brightest.
      final firstSum = palette.first.reduce((a, b) => a + b);
      final lastSum = palette.last.reduce((a, b) => a + b);
      expect(firstSum, lessThan(lastSum));
      expect(palette.first, DepthMapRenderer.viridisAnchors.first);
      expect(palette.last, DepthMapRenderer.viridisAnchors.last);
    });

    test('emits four bytes per pixel', () {
      final rgba = renderDistances([0.2, 0.3, 0.4, 0.5]);
      expect(rgba.length, 4 * 4);
    });
  });
}
