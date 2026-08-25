// lib/core/media/meal_image_processor.dart

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A photo made ready for an AI request: the downscaled file plus its base64
/// payload, so neither has to be produced twice for the same source.
class PreparedImage {
  final File file;
  final String base64;

  const PreparedImage({required this.file, required this.base64});
}

/// Scales meal photos down before they are stored or sent anywhere.
///
/// The camera hands over full sensor resolution — 3–8 MB per shot. Kept as-is
/// that is both the file that lives on the device forever *and*, once base64
/// has added its third, an 11 MB request body over mobile data. The models
/// resize to about 1024 px on their side regardless, so everything above that
/// is paid for and thrown away.
///
/// Scaling happens natively: Flutter ships no JPEG encoder, and doing it in
/// Dart would mean decoding a 12 MP bitmap on the UI isolate.
class MealImageProcessor {
  static final MealImageProcessor instance = MealImageProcessor._();
  MealImageProcessor._();

  @visibleForTesting
  static const MethodChannel channel =
      MethodChannel('com.trainlibre.app/image_ops');

  /// Long edge sent to the AI provider. Above this the models downscale
  /// themselves, so the extra pixels only cost latency and mobile data.
  static const int analysisMaxEdge = 1024;
  static const double analysisQuality = 0.8;

  /// Long edge kept on disk. Large enough that the detail view and a future
  /// re-analysis still look right, small enough to stay around 150 KB.
  static const int storageMaxEdge = 1600;
  static const double storageQuality = 0.85;

  /// Long edge of the diary list preview.
  static const int thumbMaxEdge = 320;
  static const double thumbQuality = 0.8;

  /// In flight or finished analysis copies, keyed by source path. The capture
  /// screen warms this while the user is still typing; the request itself then
  /// finds the work already done.
  final Map<String, Future<PreparedImage>> _analysisCache = {};

  String? _analysisDir;

  /// Writes a scaled JPEG copy of [sourcePath] to [targetPath].
  ///
  /// Returns false when the platform has no implementation or the encode
  /// failed; every caller has to keep working from the original in that case.
  Future<bool> downscale({
    required String sourcePath,
    required String targetPath,
    required int maxEdge,
    required double quality,
  }) async {
    try {
      return await channel.invokeMethod<bool>('downscale', {
            'sourcePath': sourcePath,
            'targetPath': targetPath,
            'maxSize': maxEdge.toDouble(),
            'quality': quality,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[MealImageProcessor] downscale failed: $e');
      return false;
    }
  }

  /// The version of [source] that goes to the AI provider, with its base64
  /// payload. Falls back to the untouched file when scaling is unavailable.
  Future<PreparedImage> prepareForAnalysis(File source) {
    return _analysisCache.putIfAbsent(
      source.path,
      () => _prepareForAnalysis(source),
    );
  }

  Future<PreparedImage> _prepareForAnalysis(File source) async {
    final scaled = await _scaledCopy(source);
    final file = scaled ?? source;
    final bytes = await file.readAsBytes();
    return PreparedImage(
      file: file,
      base64: await compute(base64Encode, bytes),
    );
  }

  /// Best effort: any failure here degrades to sending the original.
  Future<File?> _scaledCopy(File source) async {
    try {
      final dir = _analysisDir ??= p.join(
        (await getTemporaryDirectory()).path,
        'ai_analysis',
      );
      final folder = Directory(dir);
      if (!await folder.exists()) await folder.create(recursive: true);

      final name = md5.convert(utf8.encode(source.path)).toString();
      final target = File(p.join(dir, '$name.jpg'));
      final ok = await downscale(
        sourcePath: source.path,
        targetPath: target.path,
        maxEdge: analysisMaxEdge,
        quality: analysisQuality,
      );
      if (!ok || !await target.exists()) return null;

      // A photo that was already small can come out *larger* after a re-encode.
      if (await target.length() >= await source.length()) {
        await target.delete();
        return null;
      }
      return target;
    } catch (e) {
      debugPrint('[MealImageProcessor] analysis copy failed: $e');
      return null;
    }
  }

  /// Drops a photo the user removed again before sending.
  void evict(File source) => _analysisCache.remove(source.path);

  /// Forgets every prepared copy. The files themselves live in the system
  /// temporary directory and are reclaimed with it.
  void clearCache() => _analysisCache.clear();
}
