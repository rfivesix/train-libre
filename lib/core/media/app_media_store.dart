import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/drift_database.dart';
import '../../features/diary/domain/models/meal_capture_meta.dart';
import 'meal_image_processor.dart';

/// The feature an image belongs to.
///
/// Every domain gets its own folder under `media/`, on disk and inside a
/// backup archive alike.
enum MediaDomain {
  meals,
  workouts;

  /// Folder of this domain, relative to the application support directory.
  String get folder => p.join(AppMediaStore.mediaRoot, name);
}

/// Where a stored image and its preview ended up, relative to the application
/// support directory.
class StoredMedia {
  /// The stored image itself.
  final String path;

  /// Its downscaled preview, or null when the platform could not produce one —
  /// callers fall back to [path].
  final String? thumbPath;

  const StoredMedia({required this.path, this.thumbPath});
}

/// Owns the app's image files on disk.
///
/// Three rules matter here and all three have bitten this app before:
///
/// * Files handed over by the camera or the picker live in a temporary
///   directory that the system purges. They must be copied somewhere durable
///   before their path is written to the database.
/// * Only *relative* paths are persisted. The iOS container path changes with
///   every app update, so an absolute path in the database is guaranteed to
///   break.
/// * The database and the files are backed up together but restored
///   separately, so after a restore the folder holds images no row refers to
///   any more. [pruneOrphans] is what keeps that from growing forever.
class AppMediaStore {
  static final AppMediaStore instance = AppMediaStore._();
  AppMediaStore._();

  /// Root of the per-feature media folders, relative to application support.
  static const String mediaRoot = 'media';

  /// Where meal photos lived before the media root existed. Still swept by
  /// [pruneOrphans] so an app updated over such a build does not keep them
  /// forever; relative paths pointing into it keep resolving on their own,
  /// because resolution never assumes a folder.
  static const String legacyMealFolder = 'meal_photos';

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

  /// Forgets the cached support directory. Tests point `path_provider` at a
  /// fresh temporary directory per case and would otherwise inherit the
  /// previous one.
  @visibleForTesting
  void resetForTesting() => _basePath = null;

  /// The absolute folder of [domain], created if it does not exist yet.
  Future<Directory> directoryOf(MediaDomain domain) async {
    final base = await ensureInitialized();
    final dir = Directory(p.join(base, domain.folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [source] into durable storage and creates a preview.
  ///
  /// Returns null when the copy fails; callers must then store no path at all
  /// rather than pointing at the temporary file.
  Future<StoredMedia?> save(File source, {required MediaDomain domain}) async {
    if (!await source.exists()) return null;

    try {
      final base = await ensureInitialized();
      await directoryOf(domain);

      final id = _uuid.v4();
      final relative = p.join(domain.folder, '$id.jpg');
      final absolute = p.join(base, relative);

      // Scaled rather than copied: a full-resolution camera photo is 3–8 MB,
      // and three meals a day would put several gigabytes of pixels nobody
      // ever looks at on the device. Falls back to the plain copy when the
      // platform has no encoder, because a photo at any size beats none.
      final scaled = await MealImageProcessor.instance.downscale(
        sourcePath: source.path,
        targetPath: absolute,
        maxEdge: MealImageProcessor.storageMaxEdge,
        quality: MealImageProcessor.storageQuality,
      );
      if (!scaled) {
        await source.copy(absolute);
      }

      final thumbRelative = thumbPathFor(relative)!;
      final thumbCreated = await MealImageProcessor.instance.downscale(
        sourcePath: absolute,
        targetPath: p.join(base, thumbRelative),
        maxEdge: MealImageProcessor.thumbMaxEdge,
        quality: MealImageProcessor.thumbQuality,
      );

      return StoredMedia(
        path: relative,
        thumbPath: thumbCreated ? thumbRelative : null,
      );
    } catch (e) {
      debugPrint('[AppMediaStore] save failed: $e');
      return null;
    }
  }

  /// Turns a stored path into a file.
  ///
  /// Works for any relative path regardless of which folder it names, so paths
  /// written before the media root existed keep resolving. Absolute paths are
  /// passed through unchanged for the same reason.
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

  /// The preview that [save] writes next to [path].
  ///
  /// Extra photos of a multi-shot capture only carry their full-size path in
  /// `MealCaptureMeta` (meals) or `photoExtraPaths` (workouts), so their
  /// preview is found by convention rather than stored a second time.
  static String? thumbPathFor(String? path) {
    if (path == null || path.isEmpty) return null;
    final ext = p.extension(path);
    return '${p.withoutExtension(path)}_thumb$ext';
  }

  /// Best-effort removal of the files behind [paths] and their previews.
  Future<void> deleteAll(Iterable<String?> paths) async {
    for (final path in paths) {
      if (path == null || path.isEmpty) continue;
      for (final target in [path, thumbPathFor(path)]) {
        final file = await resolve(target);
        if (file == null) continue;
        try {
          if (file.existsSync()) file.deleteSync();
        } catch (e) {
          debugPrint('[AppMediaStore] delete failed for $target: $e');
        }
      }
    }
  }

  /// Deletes every file in [domain]'s folder that [referencedPaths] does not
  /// name, and returns how many went.
  ///
  /// Needed after a backup restore: the restore replaces the database but not
  /// the folder, so the images of the entries that were just wiped would sit
  /// there forever with nothing left pointing at them.
  ///
  /// Matching is by file name, not by path: an entry restored from a backup
  /// written by an older build may name the legacy folder while its file now
  /// lives under the media root, and deleting it because the folders differ
  /// would be exactly the wrong outcome.
  Future<int> pruneOrphans({
    required MediaDomain domain,
    required Set<String> referencedPaths,
  }) async {
    try {
      final base = await ensureInitialized();

      final keep = <String>{};
      for (final path in referencedPaths) {
        if (path.isEmpty) continue;
        keep.add(p.basename(path));
        final thumb = thumbPathFor(path);
        if (thumb != null) keep.add(p.basename(thumb));
      }

      final folders = <String>{
        domain.folder,
        if (domain == MediaDomain.meals) legacyMealFolder,
      };

      var removed = 0;
      for (final relative in folders) {
        final folder = Directory(p.join(base, relative));
        if (!await folder.exists()) continue;
        await for (final entity in folder.list()) {
          if (entity is! File) continue;
          if (keep.contains(p.basename(entity.path))) continue;
          try {
            await entity.delete();
            removed++;
          } catch (e) {
            debugPrint('[AppMediaStore] prune failed for ${entity.path}: $e');
          }
        }
      }
      return removed;
    } catch (e) {
      debugPrint('[AppMediaStore] prune failed: $e');
      return 0;
    }
  }

  // ── Meal domain queries ───────────────────────────────────────────────────

  /// Every image path the meal entries in [db] refer to: full-size photos,
  /// their stored previews and the extra shots of a multi-photo capture.
  static Future<Set<String>> referencedMealPaths(AppDatabase db) async {
    final referenced = <String>{};
    final rows = await db
        .customSelect('SELECT photo_path, photo_thumb_path, capture_meta '
            'FROM meal_entries')
        .get();
    for (final row in rows) {
      final photo = row.data['photo_path'];
      final thumb = row.data['photo_thumb_path'];
      if (photo is String && photo.isNotEmpty) referenced.add(photo);
      if (thumb is String && thumb.isNotEmpty) referenced.add(thumb);
      final meta =
          MealCaptureMeta.tryParse(row.data['capture_meta'] as String?);
      if (meta != null) referenced.addAll(meta.extraPhotoPaths);
    }
    return referenced;
  }

  /// Every preview path the meal entries in [db] name, in storage order.
  static Future<List<String>> _mealThumbPaths(AppDatabase db) async {
    final paths = <String>[];
    final seen = <String>{};
    final rows = await db
        .customSelect('SELECT photo_path, photo_thumb_path, capture_meta '
            'FROM meal_entries')
        .get();
    for (final row in rows) {
      final candidates = <String?>[
        row.data['photo_thumb_path'] as String?,
        // A row written before previews existed may still have one on disk
        // under the name `save` would have given it.
        thumbPathFor(row.data['photo_path'] as String?),
        for (final extra in MealCaptureMeta.tryParse(
              row.data['capture_meta'] as String?,
            )?.extraPhotoPaths ??
            const <String>[])
          thumbPathFor(extra),
      ];
      for (final candidate in candidates) {
        if (candidate == null || candidate.isEmpty) continue;
        if (seen.add(candidate)) paths.add(candidate);
      }
    }
    return paths;
  }

  /// The meal previews that go into a backup.
  Future<List<File>> collectMealThumbnails(AppDatabase db) async {
    final files = <File>[];
    try {
      for (final candidate in await _mealThumbPaths(db)) {
        final file = await resolve(candidate);
        if (file != null && await file.exists()) files.add(file);
      }
    } catch (e) {
      debugPrint('[AppMediaStore] collecting meal previews failed: $e');
    }
    return files;
  }

  /// Where the previews of a restored backup have to land.
  Future<MediaThumbPlacement> mealThumbPlacement(AppDatabase db) async {
    final base = await ensureInitialized();
    final directories = <String, String>{};
    try {
      for (final relative in await _mealThumbPaths(db)) {
        directories[p.basename(relative)] = p.dirname(relative);
      }
    } catch (e) {
      debugPrint('[AppMediaStore] reading preview locations failed: $e');
    }
    return MediaThumbPlacement(
      basePath: base,
      directoriesByName: directories,
      defaultDirectory: MediaDomain.meals.folder,
    );
  }

  // ── Workout domain queries ────────────────────────────────────────────────

  /// Every image path the workout logs in [db] refer to: full-size photos,
  /// their stored previews and the extra photos.
  static Future<Set<String>> referencedWorkoutPaths(AppDatabase db) async {
    final referenced = <String>{};
    final rows = await db
        .customSelect('SELECT photo_path, photo_thumb_path, photo_extra_paths '
            'FROM workout_logs')
        .get();
    for (final row in rows) {
      final photo = row.data['photo_path'];
      final thumb = row.data['photo_thumb_path'];
      if (photo is String && photo.isNotEmpty) referenced.add(photo);
      if (thumb is String && thumb.isNotEmpty) referenced.add(thumb);
      final extrasRaw = row.data['photo_extra_paths'] as String?;
      if (extrasRaw != null && extrasRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(extrasRaw);
          if (decoded is List) {
            for (final extra in decoded) {
              if (extra is String && extra.isNotEmpty) referenced.add(extra);
            }
          }
        } catch (_) {}
      }
    }
    return referenced;
  }

  /// Every preview path the workout logs in [db] name, in storage order.
  static Future<List<String>> _workoutThumbPaths(AppDatabase db) async {
    final paths = <String>[];
    final seen = <String>{};
    final rows = await db
        .customSelect('SELECT photo_path, photo_thumb_path, photo_extra_paths '
            'FROM workout_logs')
        .get();
    for (final row in rows) {
      final candidates = <String?>[
        row.data['photo_thumb_path'] as String?,
        thumbPathFor(row.data['photo_path'] as String?),
      ];
      final extrasRaw = row.data['photo_extra_paths'] as String?;
      if (extrasRaw != null && extrasRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(extrasRaw);
          if (decoded is List) {
            for (final extra in decoded) {
              if (extra is String && extra.isNotEmpty) {
                candidates.add(thumbPathFor(extra));
              }
            }
          }
        } catch (_) {}
      }
      for (final candidate in candidates) {
        if (candidate == null || candidate.isEmpty) continue;
        if (seen.add(candidate)) paths.add(candidate);
      }
    }
    return paths;
  }

  /// The workout previews that go into a backup.
  Future<List<File>> collectWorkoutThumbnails(AppDatabase db) async {
    final files = <File>[];
    try {
      for (final candidate in await _workoutThumbPaths(db)) {
        final file = await resolve(candidate);
        if (file != null && await file.exists()) files.add(file);
      }
    } catch (e) {
      debugPrint('[AppMediaStore] collecting workout previews failed: $e');
    }
    return files;
  }

  /// Where the workout previews of a restored backup have to land.
  Future<MediaThumbPlacement> workoutThumbPlacement(AppDatabase db) async {
    final base = await ensureInitialized();
    final directories = <String, String>{};
    try {
      for (final relative in await _workoutThumbPaths(db)) {
        directories[p.basename(relative)] = p.dirname(relative);
      }
    } catch (e) {
      debugPrint('[AppMediaStore] reading workout preview locations failed: $e');
    }
    return MediaThumbPlacement(
      basePath: base,
      directoriesByName: directories,
      defaultDirectory: MediaDomain.workouts.folder,
    );
  }
}

/// Where each restored preview belongs, by file name.
class MediaThumbPlacement {
  const MediaThumbPlacement({
    required this.basePath,
    required this.directoriesByName,
    required this.defaultDirectory,
  });

  /// Absolute application support directory.
  final String basePath;

  /// Preview file name to the folder its row names, relative to [basePath].
  final Map<String, String> directoriesByName;

  /// Where a preview no row claims goes, relative to [basePath].
  final String defaultDirectory;

  Directory directoryFor(String fileName) => Directory(
        p.join(basePath, directoriesByName[fileName] ?? defaultDirectory),
      );
}

typedef MealThumbPlacement = MediaThumbPlacement;
typedef WorkoutThumbPlacement = MediaThumbPlacement;
