import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
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
    test('carries the payload and the previews through a round trip', () async {
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
      expect(await contents.extractThumbnails((_) => target), 1);
      expect(
        await File(p.join(target.path, 'abc_thumb.jpg')).readAsBytes(),
        [1, 2, 3, 4, 5],
      );
    });

    test('an encrypted archive leaves nothing readable in the clear', () async {
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
      expect(await contents.extractThumbnails((_) => target), 1);
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

    test('files the previews by feature, next to the payload', () async {
      final archive = await BackupArchive.write(
        targetPath: p.join(workDir.path, 'backup.zip'),
        payloadJson: '{}',
        thumbnails: [
          await writeThumb('abc_thumb.jpg', [1])
        ],
      );

      final input = InputFileStream(archive.path);
      final names =
          ZipDecoder().decodeStream(input).files.map((f) => f.name).toList();
      await input.close();

      expect(names, contains('backup.json'));
      expect(names, contains('thumbs/meals/abc_thumb.jpg'));
    });

    test('still takes the flat previews of an older archive', () async {
      // Archives written before the previews were split by feature put them
      // straight into `thumbs/`. They have to keep restoring.
      final path = p.join(workDir.path, 'legacy.zip');
      final encoder = ZipFileEncoder();
      encoder.create(path);
      encoder.addArchiveFile(
        ArchiveFile.bytes('backup.json', utf8.encode('{"schemaVersion":7}')),
      );
      encoder.addArchiveFile(ArchiveFile.bytes('thumbs/abc_thumb.jpg', [9]));
      await encoder.close();

      final contents = await BackupArchive.open(path);
      addTearDown(contents.close);

      final target = Directory(p.join(workDir.path, 'restored'));
      expect(await contents.extractThumbnails((_) => target), 1);
      expect(
        await File(p.join(target.path, 'abc_thumb.jpg')).readAsBytes(),
        [9],
      );
    });

    test('leaves another feature\'s previews to that feature', () async {
      // `thumbs/<other>/` is not a meal preview and must not land in the meal
      // folder once a second feature stores images.
      final path = p.join(workDir.path, 'future.zip');
      final encoder = ZipFileEncoder();
      encoder.create(path);
      encoder
          .addArchiveFile(ArchiveFile.bytes('backup.json', utf8.encode('{}')));
      encoder.addArchiveFile(ArchiveFile.bytes('thumbs/workouts/x.jpg', [1]));
      await encoder.close();

      final contents = await BackupArchive.open(path);
      addTearDown(contents.close);

      expect(
        await contents.extractThumbnails(
          (_) => Directory(p.join(workDir.path, 'restored')),
        ),
        0,
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
