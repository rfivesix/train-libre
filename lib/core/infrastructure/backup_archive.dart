// lib/core/infrastructure/backup_archive.dart

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../util/encryption_util.dart';

/// The container a backup travels in.
///
/// A backup used to be a single JSON document, which left it no way to carry
/// the meal photos: base64 inside the JSON would have multiplied its size and
/// held the whole thing in memory twice. A zip carries them as files next to
/// the payload instead.
///
/// Only the *previews* go in. They are what the diary list shows, they are
/// around 15 KB each rather than 150 KB, and a backup meant to be mailed to
/// yourself or parked in a cloud folder should not be carrying a full photo
/// library. The full-size photos stay on the device that took them.
///
/// Layout:
///
/// ```text
/// backup.json                       the payload, as before
/// thumbs/meals/<name>_thumb.jpg     one preview per meal that has one
/// ```
///
/// Previews sit in a folder named after the feature they belong to, the same
/// way they do on disk. The next feature that stores images adds a sibling
/// folder instead of forcing a second archive format, and an archive written
/// today keeps restoring once it does.
///
/// An encrypted archive stores the same tree with `encryption.json` added and
/// every other entry suffixed `.enc`. The previews are encrypted too — an
/// encrypted backup that ships readable photos of what someone eats would be a
/// hole in exactly the thing the passphrase is there to close.
class BackupArchive {
  static const String payloadEntry = 'backup.json';
  static const String encryptedPayloadEntry = 'backup.json.enc';
  static const String keyHeaderEntry = 'encryption.json';
  static const String thumbsFolder = 'thumbs';

  /// Where meal previews go. Archives written before the split put them
  /// straight into [thumbsFolder]; [BackupArchiveContents.extractThumbnails]
  /// still takes those.
  static const String mealThumbsFolder = '$thumbsFolder/meals';
  static const String encryptedSuffix = '.enc';

  /// Previews are already-compressed JPEGs; deflating them again costs CPU and
  /// saves close to nothing.
  static const CompressionType _storeOnly = CompressionType.none;

  /// True when [head] starts with the zip magic number.
  ///
  /// Sniffed rather than taken from the file name because a backup picked from
  /// a cloud provider often arrives with whatever extension that provider felt
  /// like, and because older backups are bare JSON that must keep restoring.
  static bool looksLikeArchive(List<int> head) {
    return head.length >= 4 &&
        head[0] == 0x50 &&
        head[1] == 0x4B &&
        head[2] == 0x03 &&
        head[3] == 0x04;
  }

  /// Writes a backup archive to [targetPath].
  ///
  /// [thumbnails] are copied in under their own file names; anything that
  /// disappeared between being listed and being read is skipped rather than
  /// failing the whole export.
  static Future<File> write({
    required String targetPath,
    required String payloadJson,
    required List<File> thumbnails,
    String? passphrase,
  }) async {
    final cipher = passphrase == null || passphrase.isEmpty
        ? null
        : await EncryptionUtil.newCipher(passphrase);

    final encoder = ZipFileEncoder();
    encoder.create(targetPath);
    try {
      if (cipher != null) {
        _addBytes(
          encoder,
          keyHeaderEntry,
          utf8.encode(jsonEncode(cipher.header)),
        );
      }

      final payloadBytes = utf8.encode(payloadJson);
      _addBytes(
        encoder,
        cipher == null ? payloadEntry : encryptedPayloadEntry,
        cipher == null ? payloadBytes : await cipher.encrypt(payloadBytes),
      );

      final used = <String>{};
      for (final thumb in thumbnails) {
        List<int> bytes;
        try {
          bytes = await thumb.readAsBytes();
        } catch (e) {
          debugPrint('[BackupArchive] skipping unreadable ${thumb.path}: $e');
          continue;
        }
        var name = p.basename(thumb.path);
        if (!used.add(name)) continue;
        if (cipher != null) {
          bytes = await cipher.encrypt(bytes);
          name = '$name$encryptedSuffix';
        }
        _addBytes(encoder, '$mealThumbsFolder/$name', bytes);
      }
    } finally {
      await encoder.close();
    }
    return File(targetPath);
  }

  static void _addBytes(ZipFileEncoder encoder, String name, List<int> bytes) {
    encoder.addArchiveFile(
      ArchiveFile.bytes(name, bytes)..compression = _storeOnly,
    );
  }

  /// Opens the archive at [path].
  ///
  /// Throws when the passphrase is wrong or missing, so the caller can tell
  /// that apart from a file that is not a backup at all.
  static Future<BackupArchiveContents> open(
    String path, {
    String? passphrase,
  }) async {
    final input = InputFileStream(path);
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } catch (e) {
      await input.close();
      rethrow;
    }

    BackupCipher? cipher;
    final header = archive.findFile(keyHeaderEntry);
    if (header != null) {
      if (passphrase == null || passphrase.isEmpty) {
        await input.close();
        throw const BackupPassphraseRequired();
      }
      final headerMap =
          jsonDecode(utf8.decode(header.content)) as Map<String, dynamic>;
      cipher = await EncryptionUtil.cipherFromHeader(headerMap, passphrase);
    }

    final payloadFile = archive.findFile(
      cipher == null ? payloadEntry : encryptedPayloadEntry,
    );
    if (payloadFile == null) {
      await input.close();
      throw const BackupArchiveMalformed();
    }

    final payloadBytes = cipher == null
        ? payloadFile.content
        : await cipher.decrypt(payloadFile.content);
    final payload = await compute(jsonDecode, utf8.decode(payloadBytes))
        as Map<String, dynamic>;

    return BackupArchiveContents._(archive, input, payload, cipher);
  }
}

/// An opened backup archive. Close it when done — it holds the file open.
class BackupArchiveContents {
  BackupArchiveContents._(
    this._archive,
    this._input,
    this.payload,
    this._cipher,
  );

  final Archive _archive;
  final InputFileStream _input;
  final BackupCipher? _cipher;

  /// The backup document, in the same shape a bare JSON backup has.
  final Map<String, dynamic> payload;

  /// Writes the meal previews to disk and reports how many landed.
  ///
  /// [directoryFor] decides where each one goes from its file name, because
  /// the restored rows — not this device's layout — say where their preview
  /// has to be; see `AppMediaStore.mealThumbPlacement`. A backup restored onto
  /// a build that keeps photos elsewhere than the one that wrote it would
  /// otherwise leave every row pointing at nothing.
  ///
  /// Entry names are reduced to their base name before use: a zip may name its
  /// entries anything at all, including `../`, and nothing in a backup has any
  /// business writing outside the photo folder.
  Future<int> extractThumbnails(
    Directory Function(String fileName) directoryFor,
  ) async {
    var written = 0;
    for (final file in _archive.files) {
      if (!file.isFile) continue;
      if (!_isMealThumb(file.name)) continue;

      var name = p.basename(file.name);
      if (_cipher != null) {
        if (!name.endsWith(BackupArchive.encryptedSuffix)) continue;
        name = name.substring(
          0,
          name.length - BackupArchive.encryptedSuffix.length,
        );
      }
      if (name.isEmpty || name == '.' || name == '..') continue;

      try {
        final cipher = _cipher;
        final bytes =
            cipher == null ? file.content : await cipher.decrypt(file.content);
        final directory = directoryFor(name);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        await File(p.join(directory.path, name)).writeAsBytes(bytes);
        written++;
      } catch (e) {
        // One unreadable preview must not cost the user the whole restore.
        debugPrint('[BackupArchive] skipping preview ${file.name}: $e');
      }
    }
    return written;
  }

  /// True for the meal previews of both archive generations: the current
  /// `thumbs/meals/<name>` and the flat `thumbs/<name>` written before the
  /// previews were split by feature. A future `thumbs/<other>/<name>` is not
  /// a meal preview and must not land in the meal folder.
  static bool _isMealThumb(String entryName) {
    if (entryName.startsWith('${BackupArchive.mealThumbsFolder}/')) return true;
    return p.url.dirname(entryName) == BackupArchive.thumbsFolder;
  }

  Future<void> close() async {
    _archive.clear();
    await _input.close();
  }
}

/// The archive is encrypted and no usable passphrase was given.
class BackupPassphraseRequired implements Exception {
  const BackupPassphraseRequired();

  @override
  String toString() => 'This backup is encrypted and needs its passphrase.';
}

/// The file is a zip, but not one this app wrote.
class BackupArchiveMalformed implements Exception {
  const BackupArchiveMalformed();

  @override
  String toString() => 'The archive does not contain a backup payload.';
}
