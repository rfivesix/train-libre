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

/// What the native capture session can do on this device.
class DepthScanCapability {
  /// A depth map is delivered with each photo.
  final bool depthSupported;

  /// The unified session can run at all. False on Android and in tests, where
  /// the capture screen falls back to the scanner plus image picker.
  final bool cameraAvailable;

  const DepthScanCapability({
    required this.depthSupported,
    required this.cameraAvailable,
  });

  static const none =
      DepthScanCapability(depthSupported: false, cameraAvailable: false);
}

/// Interface for native depth scan capability and capture.
abstract class IDepthScanService {
  Future<bool> isLiDARSupported();
  Future<DepthScanCapability> capability();
  Future<bool> startSession();
  Future<void> stopSession();
  Stream<String> get barcodes;
  Future<DepthCaptureResult?> capture();
}

/// Production implementation communicating with native iOS AVFoundation LiDAR session.
class DepthScanChannel implements IDepthScanService {
  static const MethodChannel _channel =
      MethodChannel('com.trainlibre.app/depth_scan');
  static const EventChannel _barcodeChannel =
      EventChannel('com.trainlibre.app/depth_scan/barcodes');

  /// Platform view id of the live preview. Registered natively alongside the
  /// method channel, so it is only available where [capability] reports a
  /// usable camera.
  static const String previewViewType = 'com.trainlibre.app/depth_scan_preview';

  static final DepthScanChannel instance = DepthScanChannel._();
  DepthScanChannel._();

  DepthScanCapability? _cachedCapability;
  Stream<String>? _barcodeStream;

  @override
  Future<bool> isLiDARSupported() async => (await capability()).depthSupported;

  @override
  Future<DepthScanCapability> capability() async {
    if (_cachedCapability != null) return _cachedCapability!;
    if (!Platform.isIOS) {
      _cachedCapability = DepthScanCapability.none;
      return _cachedCapability!;
    }

    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('capability');
      final capability = DepthScanCapability(
        depthSupported: (res?['supported'] as bool?) ?? false,
        cameraAvailable: (res?['cameraAvailable'] as bool?) ?? false,
      );
      _cachedCapability = capability;
      return capability;
    } catch (e) {
      // Deliberately not cached: a failed check is almost always the native
      // side not being wired up yet, and caching it condemned the rest of the
      // run to the fallback camera with no depth data even after it came up.
      debugPrint('[DepthScanChannel] capability check failed: $e');
      return DepthScanCapability.none;
    }
  }

  /// Starts the shared session. Safe to call repeatedly — the native side
  /// configures once and only restarts when it was stopped.
  @override
  Future<bool> startSession() async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('start') ?? false;
    } catch (e) {
      debugPrint('[DepthScanChannel] start failed: $e');
      return false;
    }
  }

  @override
  Future<void> stopSession() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<bool>('stop');
    } catch (e) {
      debugPrint('[DepthScanChannel] stop failed: $e');
    }
  }

  /// Barcodes seen by the running session. Emits the same code repeatedly while
  /// it stays in frame; de-duplication belongs to the caller, which knows
  /// whether the user already dismissed a suggestion.
  @override
  Stream<String> get barcodes {
    if (!Platform.isIOS) return const Stream<String>.empty();
    _barcodeStream ??= _barcodeChannel
        .receiveBroadcastStream()
        .map((event) => event as String)
        .where((code) => code.isNotEmpty);
    return _barcodeStream!;
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
      // The platform codec hands nested maps back as Map<Object?, Object?>, so
      // a direct cast to Map<String, dynamic> throws — and the throw would be
      // swallowed below, leaving depth silently unavailable forever.
      Map<String, dynamic>? asStringMap(Object? value) =>
          value is Map ? Map<String, dynamic>.from(value) : null;

      final depthMap = asStringMap(res['depth']);
      final intrinsicsMap = asStringMap(res['intrinsics']);

      Float32List? depthBuffer;
      int width = 0;
      int height = 0;
      String accuracy = 'relative';

      if (depthMap != null) {
        width = (depthMap['width'] as num?)?.toInt() ?? 0;
        height = (depthMap['height'] as num?)?.toInt() ?? 0;
        accuracy = depthMap['accuracy'] as String? ?? 'relative';
        final rawBytes = depthMap['values'] as Uint8List?;
        if (rawBytes != null && rawBytes.lengthInBytes >= 4) {
          final floatCount = rawBytes.lengthInBytes ~/ 4;
          if (rawBytes.offsetInBytes % 4 == 0) {
            depthBuffer = rawBytes.buffer
                .asFloat32List(rawBytes.offsetInBytes, floatCount);
          } else {
            // A misaligned view would throw; copying is cheap enough at this
            // size (a 256x192 map is under 200 KB) and always works.
            final data = ByteData.sublistView(rawBytes);
            final copy = Float32List(floatCount);
            for (var i = 0; i < floatCount; i++) {
              copy[i] = data.getFloat32(i * 4, Endian.little);
            }
            depthBuffer = copy;
          }
        }
      }

      CameraIntrinsics? intrinsics;
      if (intrinsicsMap != null) {
        intrinsics = CameraIntrinsics.fromMap(intrinsicsMap);
      }

      DepthScaleFacts? scaleFacts;
      if (depthBuffer != null &&
          intrinsics != null &&
          width > 0 &&
          height > 0) {
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
    } on PlatformException catch (e) {
      debugPrint('[DepthScanChannel] capture failed: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[DepthScanChannel] capture error: $e');
      return null;
    }
  }
}
