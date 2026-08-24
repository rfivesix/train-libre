// test/features/depth_scan/depth_map_renderer_test.dart

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/depth_scan/data/depth_map_renderer.dart';

void main() {
  group('DepthMapRenderer', () {
    test('renders discrete 8-band RGBA pixels properly', () {
      const width = 4;
      const height = 4;
      final depthBuffer = Float32List(width * height);

      // Half at 0.50m (table), half elevated
      for (int i = 0; i < 8; i++) {
        depthBuffer[i] = 0.50; // table level -> elevation 0 -> band 0
      }
      for (int i = 8; i < 16; i++) {
        depthBuffer[i] = 0.46; // elevated 4cm closer -> band 4 (3-4cm) or band 5
      }

      final rgba = DepthMapRenderer.renderToRgba(
        depthBuffer: depthBuffer,
        width: width,
        height: height,
        referenceMedianMeters: 0.50,
        useViridis: true,
      );

      expect(rgba.length, equals(width * height * 4));

      // Check first pixel RGBA matches band 0
      final expectedBand0 = DepthMapRenderer.bandPaletteRgb[0];
      expect(rgba[0], equals(expectedBand0[0]));
      expect(rgba[1], equals(expectedBand0[1]));
      expect(rgba[2], equals(expectedBand0[2]));
      expect(rgba[3], equals(255));
    });
  });
}
