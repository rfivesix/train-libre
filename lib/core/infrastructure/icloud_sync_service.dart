// lib/core/infrastructure/icloud_sync_service.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/drift_database.dart';

/// The filename used for the iCloud backup snapshot.
const _kICloudBackupFileName = 'icloud_backup.sqlite';

/// The SharedPreferences key for toggling automated iCloud sync.
const String kICloudSyncEnabledKey = 'is_icloud_sync_enabled';

/// Service responsible for snapshotting the active Drift database and syncing
/// the snapshot to and from the user's iCloud Drive container.
///
/// Architecture:
///  - Upload: uses SQLite `VACUUM INTO` to create a non-locked copy of the DB,
///    then uploads that copy to iCloud via [ICloudStorage].
///  - Download: downloads from iCloud into a temp path, then replaces the
///    active DB file before the Drift connection is opened.
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

  /// The local snapshot copy that will be uploaded to iCloud.
  Future<String> get _localSnapshotPath async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    if (!backupDir.existsSync()) await backupDir.create(recursive: true);
    return p.join(backupDir.path, _kICloudBackupFileName);
  }

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

    // For manual alpha-debugging, we execute this inline without a silent catch block
    // to allow the UI to catch and inspect PlatformExceptions.
    final snapshotPath = await _localSnapshotPath;
    final snapshotFile = File(snapshotPath);
    if (await snapshotFile.exists()) {
      await snapshotFile.delete();
    }

    await db.customStatement('VACUUM INTO ?', [snapshotPath]);

    await _uploadWithProgress(snapshotPath, _kICloudBackupFileName, onProgress);

    return true;
  }

  Future<bool> _snapshotAndUpload(AppDatabase db) async {
    try {
      final snapshotPath = await _localSnapshotPath;
      debugPrint(
        'iCloud backup: preparing snapshot at $snapshotPath for $_kICloudBackupFileName',
      );

      // Delete stale snapshot if it exists, so VACUUM INTO starts fresh.
      final snapshotFile = File(snapshotPath);
      if (await snapshotFile.exists()) {
        await snapshotFile.delete();
      }

      // VACUUM INTO creates a defragmented, non-locked copy of the live DB.
      await db.customStatement('VACUUM INTO ?', [snapshotPath]);

      final snapshotSizeBytes = await snapshotFile.length();
      debugPrint(
        'iCloud backup: snapshot created ($snapshotSizeBytes bytes, ${(snapshotSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MiB), starting upload',
      );

      await _uploadWithProgress(snapshotPath, _kICloudBackupFileName, null);

      debugPrint(
        'iCloud backup: upload completed successfully for $_kICloudBackupFileName',
      );

      return true;
    } catch (e, st) {
      debugPrint('iCloud backup: failed with error: $e');
      debugPrint("iCloud StackTrace: $st");
      // Swallow errors silently — backup failures should not crash the app.
      return false;
    }
  }

  // ── Discovery ─────────────────────────────────────────────────────────────

  /// Returns `true` if a backup file named [_kICloudBackupFileName] exists in
  /// the user's iCloud container.
  Future<bool> hasICloudBackup() async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    try {
      final files = await ICloudStorage.gather(
        containerId: _containerId,
        onUpdate: null,
      );
      return files.any((f) => f.relativePath == _kICloudBackupFileName);
    } catch (_) {
      return false;
    }
  }

  // ── Download & Restore ────────────────────────────────────────────────────

  /// Downloads the iCloud backup file and overwrites the active database.
  ///
  /// **IMPORTANT:** Call this BEFORE the Drift [AppDatabase] connection is
  /// opened (i.e., during the onboarding splash / before `main()` wires up
  /// the database provider).
  ///
  /// Returns `true` on success.
  Future<bool> downloadAndRestore({
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    try {
      final activePath = await _activeDatabasePath;
      final tempPath = '$activePath.restore_tmp';

      // Ensure clean start
      final tempFile = File(tempPath);
      if (tempFile.existsSync()) tempFile.deleteSync();

      // Download from iCloud into a temp file.
      await _downloadWithProgress(_kICloudBackupFileName, tempPath, onProgress);

      // Verify the downloaded file exists and is non-empty.
      if (!tempFile.existsSync() || tempFile.lengthSync() == 0) {
        if (tempFile.existsSync()) tempFile.deleteSync();
        return false;
      }

      // Atomically replace the active database.
      await tempFile.rename(activePath);
      return true;
    } catch (e) {
      debugPrint('iCloud restore failed: $e');
      rethrow;
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
}
