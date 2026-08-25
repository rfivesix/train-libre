// lib/features/depth_scan/data/depth_map_attachment.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../platform/depth_scan_channel.dart';
import 'depth_map_renderer.dart';

/// A depth map written out as a PNG, ready to be sent alongside the photo.
class DepthMapAttachment {
  final File file;
  final DepthBandRender render;

  const DepthMapAttachment({required this.file, required this.render});

  /// The legend the model needs to read the picture.
  ///
  /// A false-colour image is meaningless without its scale — without this the
  /// model sees a pattern, not a measurement.
  String describeForPrompt() {
    final nearest = render.rangeOf(render.bandCount - 1);
    final farthest = render.rangeOf(0);
    return '''
- The colours encode distance from the camera, in ${render.bandCount} steps of ${render.stepCm.toStringAsFixed(1)} cm.
- Brightest yellow is the closest band, ${nearest.fromCm.toStringAsFixed(1)}-${nearest.toCm.toStringAsFixed(1)} cm from the camera.
- The ramp runs yellow -> green -> teal -> blue -> dark purple as distance grows.
- Darkest purple is the farthest band, ${farthest.fromCm.toStringAsFixed(1)} cm and beyond.
- Flat mid-grey areas are pixels the sensor could not measure. Ignore them.''';
  }
}

/// Renders the depth buffer of [result] to a PNG file next to the photo.
///
/// Returns null when the capture carried no depth map, or when encoding failed
/// — the analysis has to go ahead with the photo alone in that case.
Future<DepthMapAttachment?> buildDepthMapAttachment(
  DepthCaptureResult result, {
  int bandCount = DepthMapRenderer.defaultBandCount,
}) async {
  final buffer = result.depthBuffer;
  final width = result.depthWidth;
  final height = result.depthHeight;
  if (buffer == null || width <= 0 || height <= 0) return null;

  try {
    final rendered = await DepthMapRenderer.createUiImage(
      depthBuffer: buffer,
      width: width,
      height: height,
      bandCount: bandCount,
    );

    final png = await rendered.image.toByteData(format: ui.ImageByteFormat.png);
    rendered.image.dispose();
    if (png == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/depth_map_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png.buffer.asUint8List(), flush: true);

    return DepthMapAttachment(file: file, render: rendered.render);
  } catch (e) {
    debugPrint('[DepthMap] could not build attachment: $e');
    return null;
  }
}
