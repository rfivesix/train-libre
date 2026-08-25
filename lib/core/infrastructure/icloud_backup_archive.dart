import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../media/app_media_store.dart';
import 'backup_archive.dart';

/// The container the automatic iCloud backup travels in.
///
/// iCloud used to receive the bare SQLite snapshot, which meant a restored
/// device showed every meal without the photo it was logged with — the rows
/// name their previews, but nothing ever carried the files across. The
/// snapshot now travels inside a zip with the previews next to it, laid out
/// the same way a manual `.trainlibre` backup lays them out:
///
/// ```text
/// icloud_backup.sqlite              the VACUUMed database snapshot
/// thumbs/meals/<name>_thumb.jpg     one preview per meal that has one
/// thumbs/workouts/<name>_thumb.jpg  one preview per workout that has one
/// ```
///
/// Only the previews go in, for the same reason [BackupArchive] gives: they
/// are around 30 KB against 150 KB for the photo itself, and iCloud is a
/// backup of the diary, not a photo library.
///
/// Nothing here is encrypted. A `.trainlibre` file is handed to whatever the
/// user picked from the share sheet and can end up anywhere, which is what its
/// passphrase is for; the iCloud container is reached through the user's own
/// Apple account and is the trust anchor already.
class ICloudBackupArchive {
  /// Name of the database inside the archive. Deliberately the same name the
  /// legacy bare-SQLite backup had in iCloud.
  static const String databaseEntry = 'icloud_backup.sqlite';

  /// Where meal previews sit inside the archive — the same path
  /// [BackupArchive] uses, so the two formats never drift apart.
  static const String mealThumbsFolder = BackupArchive.mealThumbsFolder;

  /// Where workout previews sit inside the archive.
  static const String workoutThumbsFolder = BackupArchive.workoutThumbsFolder;

  /// Deflate level for the snapshot.
  ///
  /// A VACUUMed SQLite file compresses several times over, and the upload is
  /// what the user waits for. Best *speed* rather than best size because this
  /// also runs unattended when the app goes to the background, where a long
  /// CPU burst is the more expensive mistake.
  static const int _databaseLevel = DeflateLevel.bestSpeed;

  /// Previews are already-compressed JPEGs; deflating them again costs CPU and
  /// saves close to nothing.
  static const CompressionType _storeOnly = CompressionType.none;

  /// Writes [database] and [thumbnails] (and optional [workoutThumbnails]) to
  /// an archive at [targetPath].
  ///
  /// A preview that disappeared between being listed and being read is skipped
  /// rather than failing the whole backup.
  static Future<File> pack({
    required String targetPath,
    required File database,
    List<File> thumbnails = const [],
    List<File> workoutThumbnails = const [],
  }) async {
    final existing = File(targetPath);
    if (await existing.exists()) await existing.delete();

    final encoder = ZipFileEncoder();
    encoder.create(targetPath);
    try {
      // Streamed from disk: the snapshot is the largest thing the app owns and
      // must not be held in memory in full to be zipped.
      await encoder.addFile(database, databaseEntry, _databaseLevel);

      final used = <String>{};
      for (final thumb in thumbnails) {
        final name = p.basename(thumb.path);
        final folder = thumb.path.contains('/workouts/') ||
                thumb.path.contains('\\workouts\\')
            ? workoutThumbsFolder
            : mealThumbsFolder;
        if (!used.add('$folder/$name')) continue;
        try {
          final bytes = await thumb.readAsBytes();
          encoder.addArchiveFile(
            ArchiveFile.bytes('$folder/$name', bytes)
              ..compression = _storeOnly,
          );
        } catch (e) {
          debugPrint('[ICloudBackupArchive] skipping ${thumb.path}: $e');
        }
      }

      for (final thumb in workoutThumbnails) {
        final name = p.basename(thumb.path);
        if (!used.add('$workoutThumbsFolder/$name')) continue;
        try {
          final bytes = await thumb.readAsBytes();
          encoder.addArchiveFile(
            ArchiveFile.bytes('$workoutThumbsFolder/$name', bytes)
              ..compression = _storeOnly,
          );
        } catch (e) {
          debugPrint('[ICloudBackupArchive] skipping ${thumb.path}: $e');
        }
      }
    } finally {
      await encoder.close();
    }
    return File(targetPath);
  }

  /// True when [file] starts with the zip magic number.
  ///
  /// Sniffed rather than taken from the name: an account that was backed up by
  /// an older build still has `icloud_backup.sqlite` in its container, and a
  /// half-written download should fail as "not an archive" rather than as a
  /// corrupt database.
  static Future<bool> looksLikeArchive(File file) async {
    try {
      if (!await file.exists() || await file.length() < 4) return false;
      final head = await file.openRead(0, 4).expand((chunk) => chunk).toList();
      return BackupArchive.looksLikeArchive(head);
    } catch (e) {
      debugPrint('[ICloudBackupArchive] sniff failed for ${file.path}: $e');
      return false;
    }
  }

  /// Writes the database inside [archivePath] to [targetPath].
  ///
  /// Returns false when the archive carries no database, which is the one
  /// failure the caller must not treat as a restore: swapping the live file
  /// for nothing would empty the app.
  static Future<bool> extractDatabase({
    required String archivePath,
    required String targetPath,
  }) async {
    final input = InputFileStream(archivePath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      try {
        final entry = archive.findFile(databaseEntry);
        if (entry == null || !entry.isFile) return false;

        final output = OutputFileStream(targetPath);
        try {
          entry.writeContent(output);
        } finally {
          await output.close();
        }
        return await File(targetPath).length() > 0;
      } finally {
        archive.clear();
      }
    } finally {
      await input.close();
    }
  }

  /// Writes the previews inside [archivePath] to disk and reports how
  /// many landed.
  ///
  /// [directoryFor] decides where each one goes from its file name, because
  /// the restored rows — not this device's layout — say where their preview
  /// has to be; see `AppMediaStore.mealThumbPlacement` and
  /// `AppMediaStore.workoutThumbPlacement`.
  ///
  /// Entry names are reduced to their base name before use: a zip may name its
  /// entries anything at all, including `../`, and nothing in a backup has any
  /// business writing outside the photo folder. One unreadable preview must
  /// not cost the user the restore.
  static Future<int> extractThumbnails({
    required String archivePath,
    required Directory Function(String fileName) directoryFor,
    MediaDomain domain = MediaDomain.meals,
  }) async {
    var written = 0;
    final input = InputFileStream(archivePath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      try {
        final prefix = domain == MediaDomain.meals
            ? '$mealThumbsFolder/'
            : '$workoutThumbsFolder/';
        for (final file in archive.files) {
          if (!file.isFile) continue;
          if (!file.name.startsWith(prefix)) continue;

          final name = p.basename(file.name);
          if (name.isEmpty || name == '.' || name == '..') continue;

          try {
            final directory = directoryFor(name);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            await File(p.join(directory.path, name)).writeAsBytes(file.content);
            written++;
          } catch (e) {
            debugPrint('[ICloudBackupArchive] skipping ${file.name}: $e');
          }
        }
      } finally {
        archive.clear();
      }
    } finally {
      await input.close();
    }
    return written;
  }
}
