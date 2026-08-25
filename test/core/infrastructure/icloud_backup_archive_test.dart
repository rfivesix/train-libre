import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/core/infrastructure/icloud_backup_archive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workDir;

  setUp(() async {
    workDir = await Directory.systemTemp.createTemp('icloud_archive_test');
  });

  tearDown(() async {
    if (await workDir.exists()) await workDir.delete(recursive: true);
  });

  File write(String name, List<int> bytes) {
    final file = File(p.join(workDir.path, name));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return file;
  }

  /// Stands in for the `VACUUM INTO` snapshot: what matters here is that the
  /// exact bytes come back out, not that SQLite can read them.
  File writeSnapshot() => write(
        'snapshot.sqlite',
        Uint8List.fromList(List<int>.generate(4096, (i) => i % 251)),
      );

  group('ICloudBackupArchive', () {
    test('carries the database and the previews through a round trip',
        () async {
      final database = writeSnapshot();
      final thumb = write('abc_thumb.jpg', [1, 2, 3, 4, 5]);

      final archive = await ICloudBackupArchive.pack(
        targetPath: p.join(workDir.path, 'icloud_backup.zip'),
        database: database,
        thumbnails: [thumb],
      );

      expect(await ICloudBackupArchive.looksLikeArchive(archive), isTrue);

      final restoredDb = p.join(workDir.path, 'restored.sqlite');
      expect(
        await ICloudBackupArchive.extractDatabase(
          archivePath: archive.path,
          targetPath: restoredDb,
        ),
        isTrue,
      );
      expect(
        await File(restoredDb).readAsBytes(),
        await database.readAsBytes(),
      );

      final photoDir = Directory(p.join(workDir.path, 'media', 'meals'));
      expect(
        await ICloudBackupArchive.extractThumbnails(
          archivePath: archive.path,
          directoryFor: (_) => photoDir,
        ),
        1,
      );
      expect(
        await File(p.join(photoDir.path, 'abc_thumb.jpg')).readAsBytes(),
        [1, 2, 3, 4, 5],
      );
    });

    test('files the previews by feature, next to the database', () async {
      final archive = await ICloudBackupArchive.pack(
        targetPath: p.join(workDir.path, 'icloud_backup.zip'),
        database: writeSnapshot(),
        thumbnails: [
          write('abc_thumb.jpg', [1])
        ],
      );

      final input = InputFileStream(archive.path);
      final names =
          ZipDecoder().decodeStream(input).files.map((f) => f.name).toList();
      await input.close();

      expect(names, contains('icloud_backup.sqlite'));
      expect(names, contains('thumbs/meals/abc_thumb.jpg'));
    });

    test('a backup without previews is still a backup', () async {
      final archive = await ICloudBackupArchive.pack(
        targetPath: p.join(workDir.path, 'icloud_backup.zip'),
        database: writeSnapshot(),
        thumbnails: const [],
      );

      expect(
        await ICloudBackupArchive.extractDatabase(
          archivePath: archive.path,
          targetPath: p.join(workDir.path, 'restored.sqlite'),
        ),
        isTrue,
      );
      expect(
        await ICloudBackupArchive.extractThumbnails(
          archivePath: archive.path,
          directoryFor: (_) =>
              Directory(p.join(workDir.path, 'media', 'meals')),
        ),
        0,
      );
    });

    test('reports an archive that carries no database', () async {
      // Swapping the live database for nothing would empty the app, so this
      // has to be distinguishable from a restore that worked.
      final encoder = ZipFileEncoder();
      final path = p.join(workDir.path, 'empty.zip');
      encoder.create(path);
      encoder.addArchiveFile(ArchiveFile.bytes('thumbs/meals/abc.jpg', [1]));
      await encoder.close();

      expect(
        await ICloudBackupArchive.extractDatabase(
          archivePath: path,
          targetPath: p.join(workDir.path, 'restored.sqlite'),
        ),
        isFalse,
      );
    });

    test('tells a legacy bare snapshot apart from an archive', () async {
      // Accounts backed up by an older build still hold `icloud_backup.sqlite`
      // in their container, and it must keep restoring.
      final legacy = writeSnapshot();
      expect(await ICloudBackupArchive.looksLikeArchive(legacy), isFalse);
      expect(
        await ICloudBackupArchive.looksLikeArchive(
          File(p.join(workDir.path, 'missing.zip')),
        ),
        isFalse,
      );
    });

    test('drops a preview whose file vanished mid-backup', () async {
      final gone = File(p.join(workDir.path, 'gone_thumb.jpg'));
      final archive = await ICloudBackupArchive.pack(
        targetPath: p.join(workDir.path, 'icloud_backup.zip'),
        database: writeSnapshot(),
        thumbnails: [
          gone,
          write('abc_thumb.jpg', [1])
        ],
      );

      expect(
        await ICloudBackupArchive.extractThumbnails(
          archivePath: archive.path,
          directoryFor: (_) =>
              Directory(p.join(workDir.path, 'media', 'meals')),
        ),
        1,
      );
    });
  });
}
