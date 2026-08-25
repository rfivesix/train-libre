// lib/core/infrastructure/icloud_sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import '../../data/drift_database.dart';
import '../../services/telemetry/telemetry_service.dart';
import '../media/app_media_store.dart';
import 'basis_data_manager.dart';
import 'icloud_backup_archive.dart';

/// The filename of the iCloud backup: a zip carrying the database snapshot and
/// the meal previews. See [ICloudBackupArchive].
const _kICloudBackupFileName = 'icloud_backup.zip';

/// What the backup was called before the previews travelled with it: the bare
/// SQLite snapshot. Still restored from, and removed from the container once a
/// zip has taken its place, so a stale copy can never be picked over a current
/// backup.
const _kICloudLegacyBackupFileName = 'icloud_backup.sqlite';

/// The SharedPreferences key for toggling automated iCloud sync.
const String kICloudSyncEnabledKey = 'is_icloud_sync_enabled';

/// The SharedPreferences key for the last successful backup timestamp.
const String kICloudLastSyncTimestampKey = 'icloud_last_sync_timestamp';

/// Service responsible for snapshotting the active Drift database and syncing
/// the snapshot to and from the user's iCloud Drive container.
///
/// Architecture:
///  - Upload: uses SQLite `VACUUM INTO` to create a non-locked copy of the DB,
///    zips it together with the meal previews, then uploads the zip to iCloud
///    via [ICloudStorage].
///  - Download: downloads from iCloud into a temp path, unpacks the snapshot
///    and the previews, then replaces the active DB file before the Drift
///    connection is opened.
class ICloudSyncService {
  ICloudSyncService._();
  static final ICloudSyncService instance = ICloudSyncService._();

  // The iCloud container ID must match what is configured in Xcode.
  // See: Signing & Capabilities → iCloud → Containers.
  static const _containerId = 'iCloud.com.rfivesix.trainlibre';

  // ── Paths ────────────────────────────────────────────────────────────────

  /// The active Drift SQLite file path.
  Future<String> get _activeDatabasePath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'app_hybrid.sqlite');
  }

  Future<Directory> get _localBackupDir async {
    final dir = await getApplicationSupportDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return backupDir;
  }

  /// The `VACUUM INTO` snapshot. Only an intermediate — what goes to iCloud is
  /// the archive built around it.
  Future<String> get _localSnapshotPath async =>
      p.join((await _localBackupDir).path, _kICloudLegacyBackupFileName);

  /// The local archive that will be uploaded to iCloud.
  Future<String> get _localArchivePath async =>
      p.join((await _localBackupDir).path, _kICloudBackupFileName);

  // ── Preference helpers ────────────────────────────────────────────────────

  /// Returns whether automated iCloud sync is currently enabled.
  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kICloudSyncEnabledKey) ?? false;
  }

  /// Persists the enabled/disabled state for automated sync.
  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kICloudSyncEnabledKey, enabled);

    unawaited(TelemetryService.instance.trackSettingToggled(
      settingKey: 'icloud_sync_enabled',
      value: enabled,
    ));
    if (enabled) {
      unawaited(TelemetryService.instance
          .trackFeatureUsed(featureKey: FeatureKey.icloudSyncTriggered));
    }
  }

  /// Returns the last successful sync timestamp, or null if never synced.
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(kICloudLastSyncTimestampKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Persists the last successful sync timestamp.
  Future<void> _setLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        kICloudLastSyncTimestampKey, timestamp.millisecondsSinceEpoch);
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  /// Checks if sync is enabled, then snapshots and uploads the database.
  ///
  /// Safe to call in the background (e.g. on app pause).
  /// Returns `true` if the upload was performed successfully, `false` otherwise.
  Future<bool> syncIfEnabled(AppDatabase db) async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    final enabled = await isSyncEnabled();
    if (!enabled) return false;
    return _snapshotAndUpload(db);
  }

  Future<bool> backupNow(
    AppDatabase db, {
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;

    // For manual alpha-debugging, we execute this inline without a silent catch
    // block to allow the UI to catch and inspect PlatformExceptions.
    final archive = await _buildArchive(db);
    await _uploadWithProgress(archive.path, _kICloudBackupFileName, onProgress);
    await _dropLegacyRemoteBackup();

    await _setLastSyncTimestamp(DateTime.now());

    unawaited(TelemetryService.instance
        .trackFeatureUsed(featureKey: FeatureKey.icloudSyncTriggered));

    return true;
  }

  Future<bool> _snapshotAndUpload(AppDatabase db) async {
    try {
      final archive = await _buildArchive(db);

      final archiveSizeBytes = await archive.length();
      debugPrint(
        'iCloud backup: archive created ($archiveSizeBytes bytes, ${(archiveSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MiB), starting upload',
      );

      await _uploadWithProgress(archive.path, _kICloudBackupFileName, null);
      await _dropLegacyRemoteBackup();

      debugPrint(
        'iCloud backup: upload completed successfully for $_kICloudBackupFileName',
      );

      await _setLastSyncTimestamp(DateTime.now());

      return true;
    } catch (e, st) {
      debugPrint('iCloud backup: failed with error: $e');
      debugPrint("iCloud StackTrace: $st");
      // Swallow errors silently — backup failures should not crash the app.
      return false;
    }
  }

  /// Snapshots the live database and packs it with the meal previews.
  Future<File> _buildArchive(AppDatabase db) async {
    final snapshotPath = await _localSnapshotPath;
    debugPrint('iCloud backup: preparing snapshot at $snapshotPath');

    // Delete a stale snapshot if it exists, so VACUUM INTO starts fresh.
    final snapshotFile = File(snapshotPath);
    if (await snapshotFile.exists()) await snapshotFile.delete();

    await _bundleSharedPreferences(db);
    // VACUUM INTO creates a defragmented, non-locked copy of the live DB.
    await db.customStatement('VACUUM INTO ?', [snapshotPath]);

    final thumbnails = await AppMediaStore.instance.collectMealThumbnails(db);
    debugPrint('iCloud backup: bundling ${thumbnails.length} meal preview(s)');

    final archive = await ICloudBackupArchive.pack(
      targetPath: await _localArchivePath,
      database: snapshotFile,
      thumbnails: thumbnails,
    );

    // The snapshot is now inside the archive; keeping it would double what the
    // backup costs on the device.
    try {
      if (await snapshotFile.exists()) await snapshotFile.delete();
    } catch (e) {
      debugPrint('iCloud backup: could not drop the snapshot copy: $e');
    }

    return archive;
  }

  /// Removes the bare-SQLite backup an older build left in the container.
  ///
  /// Without this it would sit there forever next to the archive, and every
  /// later restore would have to guess which of the two is the current one.
  Future<void> _dropLegacyRemoteBackup() async {
    try {
      final files = await ICloudStorage.gather(
        containerId: _containerId,
        onUpdate: null,
      );
      final hasLegacy =
          files.any((f) => f.relativePath == _kICloudLegacyBackupFileName);
      if (!hasLegacy) return;
      await ICloudStorage.delete(
        containerId: _containerId,
        relativePath: _kICloudLegacyBackupFileName,
      );
      debugPrint('iCloud backup: removed the legacy snapshot from iCloud');
    } catch (e) {
      // Best effort: the archive is uploaded either way, and the restore
      // prefers it over the legacy file.
      debugPrint('iCloud backup: could not remove the legacy snapshot: $e');
    }
  }

  // ── Discovery ─────────────────────────────────────────────────────────────

  /// Returns `true` if this account has a backup in its iCloud container.
  Future<bool> hasICloudBackup() async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    try {
      return await _remoteBackupName() != null;
    } catch (_) {
      return false;
    }
  }

  /// The backup to restore from: the archive when there is one, otherwise the
  /// bare snapshot an older build uploaded. Null when the container is empty.
  Future<String?> _remoteBackupName() async {
    final files = await ICloudStorage.gather(
      containerId: _containerId,
      onUpdate: null,
    );
    for (final name in const [
      _kICloudBackupFileName,
      _kICloudLegacyBackupFileName,
    ]) {
      if (files.any((f) => f.relativePath == name)) return name;
    }
    return null;
  }

  // ── Download & Restore ────────────────────────────────────────────────────

  /// Downloads the iCloud backup and overwrites the active database.
  ///
  /// The caller does not have to close the database first — this method closes
  /// the active Drift connection itself, because the file swap is only safe
  /// once no connection holds the old file. The app must be restarted
  /// afterwards so every provider is rebuilt against the restored database.
  ///
  /// Returns `true` on success.
  Future<bool> downloadAndRestore({
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    try {
      final remoteName = await _remoteBackupName();
      if (remoteName == null) return false;

      final activePath = await _activeDatabasePath;
      final downloadPath = '$activePath.restore_download';
      final tempPath = '$activePath.restore_tmp';

      // Ensure a clean start.
      final downloadFile = File(downloadPath);
      final tempFile = File(tempPath);
      if (downloadFile.existsSync()) downloadFile.deleteSync();
      if (tempFile.existsSync()) tempFile.deleteSync();

      // Download from iCloud into a temp file.
      await _downloadWithProgress(remoteName, downloadPath, onProgress);

      // Verify the downloaded file exists and is non-empty.
      if (!downloadFile.existsSync() || downloadFile.lengthSync() == 0) {
        if (downloadFile.existsSync()) downloadFile.deleteSync();
        return false;
      }

      // Sniffed rather than taken from the name: whichever file the container
      // held, what matters is whether it is an archive or a bare snapshot.
      final isArchive =
          await ICloudBackupArchive.looksLikeArchive(downloadFile);
      if (isArchive) {
        final extracted = await ICloudBackupArchive.extractDatabase(
          archivePath: downloadPath,
          targetPath: tempPath,
        );
        if (!extracted) {
          // An archive without a database is not a restore. Swapping the live
          // file for it would empty the app.
          if (tempFile.existsSync()) tempFile.deleteSync();
          downloadFile.deleteSync();
          return false;
        }
      } else {
        downloadFile.renameSync(tempPath);
      }

      // Release the live connection before swapping the file underneath it.
      // Replacing an open SQLite file leaves the old connection writing to an
      // unlinked inode and hands every later caller a closed database.
      await DatabaseHelper.closeAndResetDriftDb();

      // Atomically replace the active database.
      await tempFile.rename(activePath);

      // Drop journal sidecars belonging to the *previous* database — SQLite
      // would otherwise try to recover the restored file from them.
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        final sidecar = File('$activePath$suffix');
        if (sidecar.existsSync()) {
          try {
            sidecar.deleteSync();
          } catch (e) {
            debugPrint('iCloud restore: could not delete $suffix sidecar: $e');
          }
        }
      }

      // Previews only after the swap: the rows that name them are in place by
      // then, so a failure earlier leaves no files behind with nothing
      // pointing at them.
      if (isArchive) {
        try {
          final written = await ICloudBackupArchive.extractThumbnails(
            archivePath: downloadPath,
            directory:
                await AppMediaStore.instance.directoryOf(MediaDomain.meals),
          );
          if (written > 0) {
            debugPrint('iCloud restore: restored $written meal preview(s)');
          }
        } catch (e) {
          // The meals themselves are back; missing previews are not worth
          // failing the restore over.
          debugPrint('iCloud restore: extracting previews failed: $e');
        }
      }

      // Restore shared preferences from the new database snapshot.
      final restoredDb = AppDatabase();
      await _extractSharedPreferences(restoredDb);
      await _pruneOrphanMedia(restoredDb);
      await restoredDb.close();

      if (downloadFile.existsSync()) downloadFile.deleteSync();

      // Catalog presence was memoized against the database we just replaced.
      BasisDataManager.instance.invalidateCatalogPresenceCache();

      return true;
    } catch (e) {
      debugPrint('iCloud restore failed: $e');
      rethrow;
    }
  }

  /// Removes the images the restored database no longer refers to.
  ///
  /// The restore replaces the rows but not the folder, so without this every
  /// photo of every meal that was just overwritten stays on disk forever — on
  /// a device that restores repeatedly they are the largest thing the app
  /// leaves behind.
  Future<void> _pruneOrphanMedia(AppDatabase db) async {
    try {
      final referenced = await AppMediaStore.referencedMealPaths(db);
      final removed = await AppMediaStore.instance.pruneOrphans(
        domain: MediaDomain.meals,
        referencedPaths: referenced,
      );
      if (removed > 0) {
        debugPrint('iCloud restore: pruned $removed orphaned meal photo(s)');
      }
    } catch (e) {
      debugPrint('iCloud restore: pruning orphaned meal photos failed: $e');
    }
  }

  // ── Progress Wrapping Helpers ─────────────────────────────────────────────

  Future<void> _uploadWithProgress(
    String localPath,
    String destPath,
    void Function(double progress)? onProgress,
  ) async {
    final completer = Completer<void>();
    StreamSubscription<double>? subscription;

    try {
      await ICloudStorage.upload(
        containerId: _containerId,
        filePath: localPath,
        destinationRelativePath: destPath,
        onProgress: (stream) {
          subscription = stream.listen(
            (progress) {
              if (onProgress != null) {
                onProgress(progress);
              }
            },
            onDone: () {
              if (!completer.isCompleted) completer.complete();
            },
            onError: (err) {
              if (!completer.isCompleted) completer.completeError(err);
            },
            cancelOnError: true,
          );
        },
      );
      await completer.future;
    } finally {
      await subscription?.cancel();
    }
  }

  Future<void> _downloadWithProgress(
    String relativePath,
    String localPath,
    void Function(double progress)? onProgress,
  ) async {
    final completer = Completer<void>();
    StreamSubscription<double>? subscription;

    try {
      await ICloudStorage.download(
        containerId: _containerId,
        relativePath: relativePath,
        destinationFilePath: localPath,
        onProgress: (stream) {
          subscription = stream.listen(
            (progress) {
              if (onProgress != null) {
                onProgress(progress);
              }
            },
            onDone: () {
              if (!completer.isCompleted) completer.complete();
            },
            onError: (err) {
              if (!completer.isCompleted) completer.completeError(err);
            },
            cancelOnError: true,
          );
        },
      );
      await completer.future;
    } finally {
      await subscription?.cancel();
    }
  }

  // ── SharedPreferences Synchronization ───────────────────────────────────────

  Future<void> _bundleSharedPreferences(AppDatabase db) async {
    await db.customStatement(
        'CREATE TABLE IF NOT EXISTS system_preferences (key TEXT PRIMARY KEY, value TEXT)');
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      String? strValue;
      if (value is bool) {
        strValue = 'b:$value';
      } else if (value is int) {
        strValue = 'i:$value';
      } else if (value is double) {
        strValue = 'd:$value';
      } else if (value is String) {
        strValue = 's:$value';
      } else if (value is List<String>) {
        strValue = 'l:${jsonEncode(value)}';
      }

      if (strValue != null) {
        await db.customStatement(
            'INSERT OR REPLACE INTO system_preferences (key, value) VALUES (?, ?)',
            [key, strValue]);
      }
    }
  }

  Future<void> _extractSharedPreferences(AppDatabase db) async {
    try {
      final rows = await db
          .customSelect('SELECT key, value FROM system_preferences')
          .get();
      final prefs = await SharedPreferences.getInstance();
      for (final row in rows) {
        final key = row.read<String>('key');
        final valStr = row.read<String>('value');
        if (valStr.startsWith('b:')) {
          await prefs.setBool(key, valStr.substring(2) == 'true');
        } else if (valStr.startsWith('i:')) {
          await prefs.setInt(key, int.parse(valStr.substring(2)));
        } else if (valStr.startsWith('d:')) {
          await prefs.setDouble(key, double.parse(valStr.substring(2)));
        } else if (valStr.startsWith('s:')) {
          await prefs.setString(key, valStr.substring(2));
        } else if (valStr.startsWith('l:')) {
          final list = jsonDecode(valStr.substring(2)) as List;
          await prefs.setStringList(key, list.cast<String>());
        }
      }

      if (prefs.getString('unit_system') == null) {
        final settings = await db.select(db.appSettings).getSingleOrNull();
        if (settings != null && settings.unitSystem.isNotEmpty) {
          await prefs.setString('unit_system', settings.unitSystem);
        }
      }
    } catch (e) {
      // Table might not exist in older backups
      debugPrint('Failed to extract shared preferences from backup: $e');
    }
  }
}
