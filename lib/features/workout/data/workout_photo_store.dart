import 'dart:io';

import '../../../core/media/app_media_store.dart';

/// Relative locations of a stored workout photo.
class WorkoutPhotoPaths {
  /// Full-size photo, relative to the application support directory.
  final String photoPath;

  /// Downscaled preview, relative to the same directory. Null when the
  /// platform could not produce one — callers fall back to [photoPath].
  final String? thumbPath;

  const WorkoutPhotoPaths({required this.photoPath, this.thumbPath});
}

/// Workout photos, as the workout feature sees them.
///
/// The files themselves belong to [AppMediaStore], which owns every feature's
/// images under one set of rules. This stays as the workout-shaped face of it.
class WorkoutPhotoStore {
  static final WorkoutPhotoStore instance = WorkoutPhotoStore._();
  WorkoutPhotoStore._();

  static const int maxPhotos = 4;
  static const MediaDomain _domain = MediaDomain.workouts;

  /// The photo folder, relative to the application support directory.
  static String get folderName => _domain.folder;

  /// Resolves and caches the support directory. Cheap to call repeatedly.
  Future<String> ensureInitialized() =>
      AppMediaStore.instance.ensureInitialized();

  /// Copies [source] into durable storage and creates a preview.
  ///
  /// Returns null when the copy fails; callers must then store no path at all
  /// rather than pointing at the temporary file.
  Future<WorkoutPhotoPaths?> save(File source) async {
    final stored = await AppMediaStore.instance.save(source, domain: _domain);
    if (stored == null) return null;
    return WorkoutPhotoPaths(
      photoPath: stored.path,
      thumbPath: stored.thumbPath,
    );
  }

  /// Turns a stored path into a file. Null before [ensureInitialized] has run
  /// for a relative path.
  File? resolveSync(String? storedPath) =>
      AppMediaStore.instance.resolveSync(storedPath);

  Future<File?> resolve(String? storedPath) =>
      AppMediaStore.instance.resolve(storedPath);

  /// The preview that [save] writes next to [photoPath].
  static String? thumbPathFor(String? photoPath) =>
      AppMediaStore.thumbPathFor(photoPath);

  /// Deletes every file in the photo folder that no workout log refers to.
  Future<int> pruneOrphans(Set<String> referencedPaths) =>
      AppMediaStore.instance.pruneOrphans(
        domain: _domain,
        referencedPaths: referencedPaths,
      );

  /// Best-effort removal of every file behind a workout log.
  ///
  /// [extraPaths] carries the additional photos of a workout log. They must be
  /// passed explicitly so they are not left behind as orphaned files.
  Future<void> delete({
    String? photoPath,
    String? thumbPath,
    List<String> extraPaths = const [],
  }) {
    return AppMediaStore.instance.deleteAll([
      photoPath,
      thumbPath,
      ...extraPaths,
    ]);
  }
}
