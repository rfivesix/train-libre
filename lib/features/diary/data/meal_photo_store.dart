// lib/features/diary/data/meal_photo_store.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/media/meal_image_processor.dart';

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

  /// The photo folder, relative to the application support directory.
  static String get folderName => _folder;
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

      // Scaled rather than copied: a full-resolution camera photo is 3–8 MB,
      // and three meals a day would put several gigabytes of pixels nobody
      // ever looks at on the device. Falls back to the plain copy when the
      // platform has no encoder, because a photo at any size beats none.
      final scaled = await MealImageProcessor.instance.downscale(
        sourcePath: source.path,
        targetPath: photoAbsolute,
        maxEdge: MealImageProcessor.storageMaxEdge,
        quality: MealImageProcessor.storageQuality,
      );
      if (!scaled) {
        await source.copy(photoAbsolute);
      }

      final thumbRelative = p.join(_folder, '${id}_thumb.jpg');
      final thumbAbsolute = p.join(base, thumbRelative);
      final thumbCreated = await MealImageProcessor.instance.downscale(
        sourcePath: photoAbsolute,
        targetPath: thumbAbsolute,
        maxEdge: MealImageProcessor.thumbMaxEdge,
        quality: MealImageProcessor.thumbQuality,
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

  /// The preview that `save` writes next to [photoPath].
  ///
  /// Extra photos of a multi-shot capture only carry their full-size path in
  /// `MealCaptureMeta`, so their preview is found by convention rather than
  /// stored a second time.
  static String? thumbPathFor(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return null;
    final ext = p.extension(photoPath);
    return '${p.withoutExtension(photoPath)}_thumb$ext';
  }

  /// Deletes every file in the photo folder that no meal entry refers to.
  ///
  /// Needed after a backup restore: the restore replaces the database but not
  /// the folder, so the photos of the meals that were just wiped would sit
  /// there forever with nothing left pointing at them.
  Future<int> pruneOrphans(Set<String> referencedPaths) async {
    try {
      final base = await ensureInitialized();
      final folder = Directory(p.join(base, _folder));
      if (!await folder.exists()) return 0;

      final keep = <String>{};
      for (final path in referencedPaths) {
        if (path.isEmpty) continue;
        keep.add(p.basename(path));
        final thumb = thumbPathFor(path);
        if (thumb != null) keep.add(p.basename(thumb));
      }

      var removed = 0;
      await for (final entity in folder.list()) {
        if (entity is! File) continue;
        if (keep.contains(p.basename(entity.path))) continue;
        try {
          await entity.delete();
          removed++;
        } catch (e) {
          debugPrint('[MealPhotoStore] prune failed for ${entity.path}: $e');
        }
      }
      return removed;
    } catch (e) {
      debugPrint('[MealPhotoStore] prune failed: $e');
      return 0;
    }
  }

  /// Best-effort removal of every file behind a meal entry.
  ///
  /// [extraPaths] carries the additional photos of a multi-shot capture. They
  /// used to be left behind, which meant every deleted multi-photo meal leaked
  /// its extras with nothing left in the database pointing at them.
  Future<void> delete({
    String? photoPath,
    String? thumbPath,
    List<String> extraPaths = const [],
  }) async {
    final targets = <String?>[
      photoPath,
      thumbPath,
      for (final extra in extraPaths) ...[extra, thumbPathFor(extra)],
    ];
    for (final path in targets) {
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
