// lib/features/diary/data/meal_photo_store.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../depth_scan/platform/depth_scan_channel.dart';

/// Relative locations of a stored meal photo.
class MealPhotoPaths {
  /// Full-size photo, relative to the application support directory.
  final String photoPath;

  /// Downscaled preview, relative to the same directory. Null when the
  /// platform could not produce one — callers fall back to [photoPath].
  final String? thumbPath;

  const MealPhotoPaths({required this.photoPath, this.thumbPath});
}

/// Owns meal photos on disk.
///
/// Two rules matter here and both have bitten this feature before:
///
/// * Photos handed over by the camera or the picker live in a temporary
///   directory that the system purges. They must be copied somewhere durable
///   before their path is written to the database.
/// * Only *relative* paths are persisted. The iOS container path changes with
///   every app update, so an absolute path in the database is guaranteed to
///   break.
class MealPhotoStore {
  static final MealPhotoStore instance = MealPhotoStore._();
  MealPhotoStore._();

  static const String _folder = 'meal_photos';
  static const _uuid = Uuid();

  String? _basePath;

  /// Resolves and caches the support directory. Cheap to call repeatedly.
  Future<String> ensureInitialized() async {
    final cached = _basePath;
    if (cached != null) return cached;
    final dir = await getApplicationSupportDirectory();
    _basePath = dir.path;
    return dir.path;
  }

  /// Copies [source] into durable storage and creates a preview.
  ///
  /// Returns null when the copy fails; callers must then store no path at all
  /// rather than pointing at the temporary file.
  Future<MealPhotoPaths?> save(File source) async {
    if (!await source.exists()) return null;

    try {
      final base = await ensureInitialized();
      final folder = Directory(p.join(base, _folder));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final id = _uuid.v4();
      final photoRelative = p.join(_folder, '$id.jpg');
      final photoAbsolute = p.join(base, photoRelative);
      await source.copy(photoAbsolute);

      final thumbRelative = p.join(_folder, '${id}_thumb.jpg');
      final thumbAbsolute = p.join(base, thumbRelative);
      final thumbCreated = await DepthScanChannel.instance.makeThumbnail(
        sourcePath: photoAbsolute,
        targetPath: thumbAbsolute,
      );

      return MealPhotoPaths(
        photoPath: photoRelative,
        thumbPath: thumbCreated ? thumbRelative : null,
      );
    } catch (e) {
      debugPrint('[MealPhotoStore] save failed: $e');
      return null;
    }
  }

  /// Turns a stored path into a file.
  ///
  /// Absolute paths are passed through unchanged so rows written before this
  /// store existed keep resolving for as long as their file survives.
  File? resolveSync(String? storedPath) {
    if (storedPath == null || storedPath.isEmpty) return null;
    if (p.isAbsolute(storedPath)) return File(storedPath);
    final base = _basePath;
    if (base == null) return null;
    return File(p.join(base, storedPath));
  }

  Future<File?> resolve(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) return null;
    await ensureInitialized();
    return resolveSync(storedPath);
  }

  /// Best-effort removal of both files behind a meal entry.
  Future<void> delete({String? photoPath, String? thumbPath}) async {
    for (final path in [photoPath, thumbPath]) {
      final file = await resolve(path);
      if (file == null) continue;
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('[MealPhotoStore] delete failed for $path: $e');
      }
    }
  }
}
