// test/features/depth_scan/depth_scale_calculator_test.dart

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/depth_scan/data/depth_scale_calculator.dart';

void main() {
  group('DepthScaleCalculator', () {
    test('calculates accurate distance and dimensions for known synthetic buffer', () {
      const width = 100;
      const height = 100;
      final buffer = Float32List(width * height);

      // Fill buffer with flat surface at 0.50 meters (50 cm)
      for (int i = 0; i < buffer.length; i++) {
        buffer[i] = 0.50;
      }

      final intrinsics = CameraIntrinsics(
        fx: 1000.0,
        fy: 1000.0,
        cx: 500.0,
        cy: 500.0,
        refWidth: 1000,
        refHeight: 1000,
      );

      final facts = DepthScaleCalculator.calculate(
        depthBuffer: buffer,
        width: width,
        height: height,
        intrinsics: intrinsics,
        accuracy: 'absolute',
      );

      expect(facts.isValid, isTrue);
      expect(facts.subjectDistanceCm, closeTo(50.0, 0.1));
      expect(facts.nearCm, closeTo(50.0, 0.1));
      expect(facts.farCm, closeTo(50.0, 0.1));
      expect(facts.validSampleRatio, equals(1.0));
      expect(facts.accuracy, equals('absolute'));
      // frameWidthCm = (1000 / 1000) * 50 = 50 cm
      expect(facts.frameWidthCm, closeTo(50.0, 0.1));
      expect(facts.frameHeightCm, closeTo(50.0, 0.1));
    });

    test('rejects buffers with distance outside quality gate (< 15cm or > 120cm)', () {
      const width = 10;
      const height = 10;
      final buffer = Float32List(width * height);

      // Too close: 0.10 meters (10 cm)
      for (int i = 0; i < buffer.length; i++) {
        buffer[i] = 0.10;
      }

      final intrinsics = CameraIntrinsics(
        fx: 1000.0,
        fy: 1000.0,
        cx: 500.0,
        cy: 500.0,
        refWidth: 1000,
        refHeight: 1000,
      );

      final factsTooClose = DepthScaleCalculator.calculate(
        depthBuffer: buffer,
        width: width,
        height: height,
        intrinsics: intrinsics,
      );
      expect(factsTooClose.isValid, isFalse);

      // Too far: 2.00 meters (200 cm)
      for (int i = 0; i < buffer.length; i++) {
        buffer[i] = 2.00;
      }

      final factsTooFar = DepthScaleCalculator.calculate(
        depthBuffer: buffer,
        width: width,
        height: height,
        intrinsics: intrinsics,
      );
      expect(factsTooFar.isValid, isFalse);
    });
  });
}
