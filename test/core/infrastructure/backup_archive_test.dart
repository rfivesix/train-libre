import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/core/infrastructure/backup_archive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workDir;

  setUp(() async {
    workDir = await Directory.systemTemp.createTemp('backup_archive_test');
  });

  tearDown(() async {
    if (await workDir.exists()) await workDir.delete(recursive: true);
  });

  Future<File> writeThumb(String name, List<int> bytes) async {
    final file = File(p.join(workDir.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }

  group('BackupArchive', () {
    test('carries the payload and the previews through a round trip',
        () async {
      final thumb = await writeThumb('abc_thumb.jpg', [1, 2, 3, 4, 5]);
      final archive = await BackupArchive.write(
        targetPath: p.join(workDir.path, 'backup.zip'),
        payloadJson: jsonEncode({'schemaVersion': 7, 'foodEntries': []}),
        thumbnails: [thumb],
      );

      final contents = await BackupArchive.open(archive.path);
      addTearDown(contents.close);

      expect(contents.payload['schemaVersion'], 7);

      final target = Directory(p.join(workDir.path, 'restored'));
      expect(await contents.extractThumbnails(target), 1);
      expect(
        await File(p.join(target.path, 'abc_thumb.jpg')).readAsBytes(),
        [1, 2, 3, 4, 5],
      );
    });

    test('an encrypted archive leaves nothing readable in the clear',
        () async {
      final thumb = await writeThumb('abc_thumb.jpg', utf8.encode('PREVIEW'));
      final archive = await BackupArchive.write(
        targetPath: p.join(workDir.path, 'backup.zip'),
        payloadJson: jsonEncode({'schemaVersion': 7, 'secret': 'BREAKFAST'}),
        thumbnails: [thumb],
        passphrase: 'correct horse',
      );

      // The whole point of the passphrase: a backup that encrypts the meals
      // but ships readable photos of them protects nothing.
      final raw = await archive.readAsBytes();
      expect(String.fromCharCodes(raw), isNot(contains('BREAKFAST')));
      expect(String.fromCharCodes(raw), isNot(contains('PREVIEW')));

      final contents =
          await BackupArchive.open(archive.path, passphrase: 'correct horse');
      addTearDown(contents.close);
      expect(contents.payload['secret'], 'BREAKFAST');

      final target = Directory(p.join(workDir.path, 'restored'));
      expect(await contents.extractThumbnails(target), 1);
      expect(
        await File(p.join(target.path, 'abc_thumb.jpg')).readAsString(),
        'PREVIEW',
      );
    });

    test('an encrypted archive refuses to open without the passphrase',
        () async {
      final archive = await BackupArchive.write(
        targetPath: p.join(workDir.path, 'backup.zip'),
        payloadJson: '{}',
        thumbnails: const [],
        passphrase: 'correct horse',
      );

      expect(
        () => BackupArchive.open(archive.path),
        throwsA(isA<BackupPassphraseRequired>()),
      );
      expect(
        () => BackupArchive.open(archive.path, passphrase: 'wrong'),
        throwsA(anything),
      );
    });

    test('recognises an archive by its content, not its name', () async {
      final archive = await BackupArchive.write(
        targetPath: p.join(workDir.path, 'named-anything.dat'),
        payloadJson: '{}',
        thumbnails: const [],
      );
      final head = (await archive.readAsBytes()).take(4).toList();

      expect(BackupArchive.looksLikeArchive(head), isTrue);
      expect(BackupArchive.looksLikeArchive(utf8.encode('{"a":1}')), isFalse);
      expect(BackupArchive.looksLikeArchive(const [0x50]), isFalse);
    });
  });
}
