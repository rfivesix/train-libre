// lib/features/depth_scan/platform/depth_scan_channel.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/depth_scale_calculator.dart';
import '../domain/models/depth_scale_facts.dart';

/// Result from a native depth camera snapshot.
class DepthCaptureResult {
  final File imageFile;
  final Float32List? depthBuffer;
  final int depthWidth;
  final int depthHeight;
  final CameraIntrinsics? intrinsics;
  final String accuracy; // 'absolute' or 'relative'
  final DepthScaleFacts? scaleFacts;

  const DepthCaptureResult({
    required this.imageFile,
    this.depthBuffer,
    this.depthWidth = 0,
    this.depthHeight = 0,
    this.intrinsics,
    this.accuracy = 'relative',
    this.scaleFacts,
  });
}

/// Interface for native depth scan capability and capture.
abstract class IDepthScanService {
  Future<bool> isLiDARSupported();
  Future<DepthCaptureResult?> capture();
}

/// Production implementation communicating with native iOS AVFoundation LiDAR session.
class DepthScanChannel implements IDepthScanService {
  static const MethodChannel _channel = MethodChannel('com.trainlibre.app/depth_scan');

  static final DepthScanChannel instance = DepthScanChannel._();
  DepthScanChannel._();

  bool? _cachedSupported;

  @override
  Future<bool> isLiDARSupported() async {
    if (_cachedSupported != null) return _cachedSupported!;
    if (!Platform.isIOS) {
      _cachedSupported = false;
      return false;
    }

    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('capability');
      final supported = (res?['supported'] as bool?) ?? false;
      _cachedSupported = supported;
      return supported;
    } catch (e) {
      debugPrint('[DepthScanChannel] capability check failed: $e');
      _cachedSupported = false;
      return false;
    }
  }

  @override
  Future<DepthCaptureResult?> capture() async {
    if (!Platform.isIOS) return null;

    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('capture');
      if (res == null) return null;

      final imagePath = res['imagePath'] as String?;
      if (imagePath == null || !File(imagePath).existsSync()) return null;

      final imageFile = File(imagePath);
      final depthMap = res['depth'] as Map<String, dynamic>?;
      final intrinsicsMap = res['intrinsics'] as Map<String, dynamic>?;

      Float32List? depthBuffer;
      int width = 0;
      int height = 0;
      String accuracy = 'relative';

      if (depthMap != null) {
        width = (depthMap['width'] as num?)?.toInt() ?? 0;
        height = (depthMap['height'] as num?)?.toInt() ?? 0;
        accuracy = depthMap['accuracy'] as String? ?? 'relative';
        final rawBytes = depthMap['values'] as Uint8List?;
        if (rawBytes != null && rawBytes.isNotEmpty) {
          depthBuffer = rawBytes.buffer.asFloat32List(
            rawBytes.offsetInBytes,
            rawBytes.lengthInBytes ~/ 4,
          );
        }
      }

      CameraIntrinsics? intrinsics;
      if (intrinsicsMap != null) {
        intrinsics = CameraIntrinsics.fromMap(intrinsicsMap);
      }

      DepthScaleFacts? scaleFacts;
      if (depthBuffer != null && intrinsics != null && width > 0 && height > 0) {
        scaleFacts = DepthScaleCalculator.calculate(
          depthBuffer: depthBuffer,
          width: width,
          height: height,
          intrinsics: intrinsics,
          accuracy: accuracy,
        );
      }

      return DepthCaptureResult(
        imageFile: imageFile,
        depthBuffer: depthBuffer,
        depthWidth: width,
        depthHeight: height,
        intrinsics: intrinsics,
        accuracy: accuracy,
        scaleFacts: scaleFacts,
      );
    } catch (e) {
      debugPrint('[DepthScanChannel] capture error: $e');
      return null;
    }
  }
}
