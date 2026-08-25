// lib/features/diary/data/meal_photo_store.dart

import 'dart:io';

import '../../../core/media/app_media_store.dart';

/// Relative locations of a stored meal photo.
class MealPhotoPaths {
  /// Full-size photo, relative to the application support directory.
  final String photoPath;

  /// Downscaled preview, relative to the same directory. Null when the
  /// platform could not produce one — callers fall back to [photoPath].
  final String? thumbPath;

  const MealPhotoPaths({required this.photoPath, this.thumbPath});
}

/// Meal photos, as the diary sees them.
///
/// The files themselves belong to [AppMediaStore], which owns every feature's
/// images under one set of rules. This stays as the meal-shaped face of it so
/// the capture, diary and detail screens keep talking about photos and
/// previews rather than about media domains.
class MealPhotoStore {
  static final MealPhotoStore instance = MealPhotoStore._();
  MealPhotoStore._();

  static const MediaDomain _domain = MediaDomain.meals;

  /// The photo folder, relative to the application support directory.
  static String get folderName => _domain.folder;

  /// Resolves and caches the support directory. Cheap to call repeatedly.
  Future<String> ensureInitialized() =>
      AppMediaStore.instance.ensureInitialized();

  /// Copies [source] into durable storage and creates a preview.
  ///
  /// Returns null when the copy fails; callers must then store no path at all
  /// rather than pointing at the temporary file.
  Future<MealPhotoPaths?> save(File source) async {
    final stored = await AppMediaStore.instance.save(source, domain: _domain);
    if (stored == null) return null;
    return MealPhotoPaths(
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

  /// Deletes every file in the photo folder that no meal entry refers to.
  Future<int> pruneOrphans(Set<String> referencedPaths) =>
      AppMediaStore.instance.pruneOrphans(
        domain: _domain,
        referencedPaths: referencedPaths,
      );

  /// Best-effort removal of every file behind a meal entry.
  ///
  /// [extraPaths] carries the additional photos of a multi-shot capture. They
  /// used to be left behind, which meant every deleted multi-photo meal leaked
  /// its extras with nothing left in the database pointing at them.
  Future<void> delete({
    String? photoPath,
    String? thumbPath,
    List<String> extraPaths = const [],
  }) {
    // `deleteAll` removes each path's preview by convention; `thumbPath` is
    // passed as well because a row may name a preview that does not follow it.
    return AppMediaStore.instance.deleteAll([
      photoPath,
      thumbPath,
      ...extraPaths,
    ]);
  }
}
