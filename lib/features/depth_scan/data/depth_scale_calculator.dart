// lib/features/depth_scan/data/depth_scale_calculator.dart

import 'dart:typed_data';
import '../domain/models/depth_scale_facts.dart';

/// Camera intrinsics parameters from AVFoundation or ARKit.
class CameraIntrinsics {
  final double fx;
  final double fy;
  final double cx;
  final double cy;
  final int refWidth;
  final int refHeight;

  const CameraIntrinsics({
    required this.fx,
    required this.fy,
    required this.cx,
    required this.cy,
    required this.refWidth,
    required this.refHeight,
  });

  factory CameraIntrinsics.fromMap(Map<String, dynamic> map) {
    return CameraIntrinsics(
      fx: (map['fx'] as num).toDouble(),
      fy: (map['fy'] as num).toDouble(),
      cx: (map['cx'] as num).toDouble(),
      cy: (map['cy'] as num).toDouble(),
      refWidth: (map['refWidth'] as num).toInt(),
      refHeight: (map['refHeight'] as num).toInt(),
    );
  }
}

/// Computes calibrated physical dimensions and scale facts from raw LiDAR depth buffers.
class DepthScaleCalculator {
  /// Minimum valid distance for food capture in cm.
  static const double minDistanceCm = 15.0;

  /// Maximum valid distance for food capture in cm.
  static const double maxDistanceCm = 120.0;

  /// Minimum ratio of valid samples required across the frame.
  static const double minValidRatio = 0.5;

  /// Calculates [DepthScaleFacts] from a Float32 depth buffer and camera intrinsics.
  ///
  /// [depthBuffer] is Float32 values in meters (little-endian).
  /// [width] and [height] are depth buffer dimensions (e.g. 320x240).
  /// [accuracy] is 'absolute' or 'relative'.
  static DepthScaleFacts calculate({
    required Float32List depthBuffer,
    required int width,
    required int height,
    required CameraIntrinsics intrinsics,
    String accuracy = 'absolute',
    int imageWidthPx = 1920,
    int imageHeightPx = 1440,
  }) {
    if (depthBuffer.isEmpty || width <= 0 || height <= 0) {
      return const DepthScaleFacts(
        subjectDistanceCm: 0,
        frameWidthCm: 0,
        frameHeightCm: 0,
        nearCm: 0,
        farCm: 0,
        validSampleRatio: 0,
        accuracy: 'invalid',
        isValid: false,
      );
    }

    final totalSamples = width * height;
    final validAll = <double>[];
    final validCenter = <double>[];

    final startX = (width * 0.33).floor();
    final endX = (width * 0.67).ceil();
    final startY = (height * 0.33).floor();
    final endY = (height * 0.67).ceil();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index >= depthBuffer.length) continue;
        final val = depthBuffer[index];

        if (val.isFinite && !val.isNaN && val > 0.05 && val < 5.0) {
          validAll.add(val);
          if (x >= startX && x <= endX && y >= startY && y <= endY) {
            validCenter.add(val);
          }
        }
      }
    }

    final validRatio = validAll.length / totalSamples;

    if (validAll.isEmpty || validRatio < minValidRatio) {
      return DepthScaleFacts(
        subjectDistanceCm: 0,
        frameWidthCm: 0,
        frameHeightCm: 0,
        nearCm: 0,
        farCm: 0,
        validSampleRatio: validRatio,
        accuracy: accuracy,
        isValid: false,
      );
    }

    validAll.sort();
    final targetCenter = validCenter.isNotEmpty ? validCenter : validAll;
    targetCenter.sort();

    final medianMeters = targetCenter[targetCenter.length ~/ 2];
    final nearMeters = validAll[(validAll.length * 0.05).floor()];
    final farMeters = validAll[((validAll.length * 0.95) - 1).clamp(0, validAll.length - 1).toInt()];

    final subjectDistanceCm = medianMeters * 100.0;
    final nearCm = nearMeters * 100.0;
    final farCm = farMeters * 100.0;

    // Scale focal length to the photo pixel dimensions if reference dimension differs
    final scaleX = imageWidthPx / (intrinsics.refWidth > 0 ? intrinsics.refWidth : imageWidthPx);
    final scaleY = imageHeightPx / (intrinsics.refHeight > 0 ? intrinsics.refHeight : imageHeightPx);
    final effectiveFx = intrinsics.fx * scaleX;
    final effectiveFy = intrinsics.fy * scaleY;

    final frameWidthCm = effectiveFx > 0
        ? (imageWidthPx * medianMeters) / effectiveFx * 100.0
        : 0.0;
    final frameHeightCm = effectiveFy > 0
        ? (imageHeightPx * medianMeters) / effectiveFy * 100.0
        : 0.0;

    // Quality gate
    final isDistanceOk = subjectDistanceCm >= minDistanceCm && subjectDistanceCm <= maxDistanceCm;
    final isAccuracyOk = accuracy.toLowerCase() == 'absolute';
    final isValid = isDistanceOk && isAccuracyOk && validRatio >= minValidRatio;

    return DepthScaleFacts(
      subjectDistanceCm: double.parse(subjectDistanceCm.toStringAsFixed(1)),
      frameWidthCm: double.parse(frameWidthCm.toStringAsFixed(1)),
      frameHeightCm: double.parse(frameHeightCm.toStringAsFixed(1)),
      nearCm: double.parse(nearCm.toStringAsFixed(1)),
      farCm: double.parse(farCm.toStringAsFixed(1)),
      validSampleRatio: double.parse(validRatio.toStringAsFixed(2)),
      accuracy: accuracy,
      isValid: isValid,
    );
  }
}
