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

/// The archive the previous backup is moved to before a new one is uploaded.
/// Never restored from automatically — it is there so a bad backup does not
/// leave the account with nothing.
const _kICloudPreviousBackupFileName = 'icloud_backup.previous.zip';

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
    await _keepPreviousRemoteBackup();
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

      await _keepPreviousRemoteBackup();
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

    final mealThumbnails =
        await AppMediaStore.instance.collectMealThumbnails(db);
    final workoutThumbnails =
        await AppMediaStore.instance.collectWorkoutThumbnails(db);
    debugPrint(
        'iCloud backup: bundling ${mealThumbnails.length} meal preview(s), ${workoutThumbnails.length} workout preview(s)');

    final archive = await ICloudBackupArchive.pack(
      targetPath: await _localArchivePath,
      database: snapshotFile,
      thumbnails: mealThumbnails,
      workoutThumbnails: workoutThumbnails,
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

  /// Moves the current archive aside before a new one takes its place.
  ///
  /// One generation, deliberately: a restore that goes wrong is followed by
  /// the next automatic sync uploading the wrong state over the only copy
  /// there is. Keeping the previous archive is the difference between an
  /// annoyance and lost data, and costs one extra file in the container.
  Future<void> _keepPreviousRemoteBackup() async {
    try {
      final files = await ICloudStorage.gather(
        containerId: _containerId,
        onUpdate: null,
      );
      if (!files.any((f) => f.relativePath == _kICloudBackupFileName)) return;

      if (files.any((f) => f.relativePath == _kICloudPreviousBackupFileName)) {
        await ICloudStorage.delete(
          containerId: _containerId,
          relativePath: _kICloudPreviousBackupFileName,
        );
      }
      await ICloudStorage.move(
        containerId: _containerId,
        fromRelativePath: _kICloudBackupFileName,
        toRelativePath: _kICloudPreviousBackupFileName,
      );
    } catch (e) {
      // Best effort: failing to keep the old copy must not stop the new one.
      debugPrint('iCloud backup: could not keep the previous archive: $e');
    }
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

  /// Downloads the iCloud backup and restores it into the live database.
  ///
  /// The snapshot is copied *into* the open database rather than swapped in as
  /// a file. Swapping meant closing the connection first, and every data
  /// source built in `main` holds that connection object: from the moment of
  /// the swap the diary, the profile and the supplements all threw "the
  /// connection was closed", and only a full restart brought them back. Since
  /// onboarding continues after a restore — region, catalog download,
  /// permissions — a restart in the middle of it is not an option, so nothing
  /// is closed at all.
  ///
  /// Returns `true` on success.
  Future<bool> downloadAndRestore({
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;

    final workDir = await _localBackupDir;
    final downloadPath = p.join(workDir.path, 'icloud_restore_download');
    final snapshotPath = p.join(workDir.path, 'icloud_restore_snapshot.sqlite');
    final downloadFile = File(downloadPath);
    final snapshotFile = File(snapshotPath);

    try {
      final remoteName = await _remoteBackupName();
      if (remoteName == null) return false;

      // Ensure a clean start.
      if (downloadFile.existsSync()) downloadFile.deleteSync();
      if (snapshotFile.existsSync()) snapshotFile.deleteSync();

      await _downloadWithProgress(remoteName, downloadPath, onProgress);

      if (!downloadFile.existsSync() || downloadFile.lengthSync() == 0) {
        return false;
      }

      // Sniffed rather than taken from the name: whichever file the container
      // held, what matters is whether it is an archive or a bare snapshot.
      final isArchive =
          await ICloudBackupArchive.looksLikeArchive(downloadFile);
      if (isArchive) {
        final extracted = await ICloudBackupArchive.extractDatabase(
          archivePath: downloadPath,
          targetPath: snapshotPath,
        );
        if (!extracted) {
          // An archive without a database is not a restore.
          return false;
        }
      } else {
        downloadFile.renameSync(snapshotPath);
      }

      final db = DatabaseHelper.instance.dbInstance;
      await _copySnapshotIntoLiveDatabase(db, snapshotPath);

      // Previews after the rows, so nothing is left on disk with no entry
      // pointing at it if the copy fails.
      if (isArchive) {
        try {
          final mealPlacement = await AppMediaStore.instance.mealThumbPlacement(db);
          final mealWritten = await ICloudBackupArchive.extractThumbnails(
            archivePath: downloadPath,
            directoryFor: mealPlacement.directoryFor,
            domain: MediaDomain.meals,
          );
          if (mealWritten > 0) {
            debugPrint('iCloud restore: restored $mealWritten meal preview(s)');
          }

          final workoutPlacement =
              await AppMediaStore.instance.workoutThumbPlacement(db);
          final workoutWritten = await ICloudBackupArchive.extractThumbnails(
            archivePath: downloadPath,
            directoryFor: workoutPlacement.directoryFor,
            domain: MediaDomain.workouts,
          );
          if (workoutWritten > 0) {
            debugPrint(
                'iCloud restore: restored $workoutWritten workout preview(s)');
          }
        } catch (e) {
          // The database itself is back; missing previews are not worth
          // failing the restore over.
          debugPrint('iCloud restore: extracting previews failed: $e');
        }
      }

      await _extractSharedPreferences(db);
      await _pruneOrphanMedia(db);

      // Catalog presence was memoized against the rows we just replaced.
      BasisDataManager.instance.invalidateCatalogPresenceCache();

      return true;
    } catch (e) {
      debugPrint('iCloud restore failed: $e');
      rethrow;
    } finally {
      for (final file in [downloadFile, snapshotFile]) {
        try {
          if (file.existsSync()) file.deleteSync();
        } catch (e) {
          debugPrint('iCloud restore: could not clean up ${file.path}: $e');
        }
      }
    }
  }

  /// Replaces the contents of the live database with the snapshot's.
  ///
  /// Table by table, over the connection the app is already using. Only the
  /// columns both sides have are carried across, so a backup written by an
  /// older or newer build restores what it can instead of failing outright,
  /// and a table this build does not know is skipped rather than guessed at.
  ///
  /// Tables the snapshot does not carry are left alone: they belong to a
  /// feature added after the backup was written, and wiping them would lose
  /// data the backup never claimed to replace.
  @visibleForTesting
  Future<void> copySnapshotIntoLiveDatabaseForTesting(
    AppDatabase db,
    String snapshotPath,
  ) =>
      _copySnapshotIntoLiveDatabase(db, snapshotPath);

  Future<void> _copySnapshotIntoLiveDatabase(
    AppDatabase db,
    String snapshotPath,
  ) async {
    // Foreign keys off for the duration: the tables are copied one at a time,
    // so every order but the last leaves some reference temporarily dangling.
    await db.customStatement('PRAGMA foreign_keys = OFF');
    try {
      await db.customStatement('ATTACH DATABASE ? AS restore', [snapshotPath]);
      try {
        final tables = await db
            .customSelect("SELECT name FROM restore.sqlite_master "
                "WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
            .get();

        var copied = 0;
        await db.transaction(() async {
          for (final row in tables) {
            final table = row.read<String>('name');

            final liveColumns = await _columnNames(db, 'main', table);
            if (liveColumns.isEmpty) continue;
            final snapshotColumns = await _columnNames(db, 'restore', table);
            final shared = liveColumns.where(snapshotColumns.contains).toList();
            if (shared.isEmpty) continue;

            final columnList = shared.map((c) => '"$c"').join(', ');
            await db.customStatement('DELETE FROM main."$table"');
            await db.customStatement(
              'INSERT INTO main."$table" ($columnList) '
              'SELECT $columnList FROM restore."$table"',
            );
            copied++;
          }
        });
        debugPrint('iCloud restore: copied $copied table(s) from the backup');
      } finally {
        await db.customStatement('DETACH DATABASE restore');
      }
    } finally {
      await db.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  Future<List<String>> _columnNames(
    AppDatabase db,
    String schema,
    String table,
  ) async {
    try {
      final rows =
          await db.customSelect('PRAGMA $schema.table_info("$table")').get();
      return [for (final row in rows) row.read<String>('name')];
    } catch (e) {
      // The table does not exist in this schema.
      return const [];
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
      final referencedMeals = await AppMediaStore.referencedMealPaths(db);
      final removedMeals = await AppMediaStore.instance.pruneOrphans(
        domain: MediaDomain.meals,
        referencedPaths: referencedMeals,
      );
      if (removedMeals > 0) {
        debugPrint('iCloud restore: pruned $removedMeals orphaned meal photo(s)');
      }
    } catch (e) {
      debugPrint('iCloud restore: pruning orphaned meal photos failed: $e');
    }

    try {
      final referencedWorkouts =
          await AppMediaStore.referencedWorkoutPaths(db);
      final removedWorkouts = await AppMediaStore.instance.pruneOrphans(
        domain: MediaDomain.workouts,
        referencedPaths: referencedWorkouts,
      );
      if (removedWorkouts > 0) {
        debugPrint(
            'iCloud restore: pruned $removedWorkouts orphaned workout photo(s)');
      }
    } catch (e) {
      debugPrint('iCloud restore: pruning orphaned workout photos failed: $e');
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
