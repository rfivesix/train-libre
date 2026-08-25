import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/core/media/app_media_store.dart';
import 'package:train_libre/features/diary/data/meal_photo_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDir;

  setUp(() async {
    supportDir = await Directory.systemTemp.createTemp('app_media_store_test');
    // path_provider has no implementation under `flutter test`, so the media
    // folder is pointed at a real temporary directory instead.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => supportDir.path,
    );
    AppMediaStore.instance.resetForTesting();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    AppMediaStore.instance.resetForTesting();
    if (await supportDir.exists()) await supportDir.delete(recursive: true);
  });

  File write(String relative, List<int> bytes) {
    final file = File(p.join(supportDir.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return file;
  }

  group('layout', () {
    test('every domain has its own folder under the media root', () {
      expect(MediaDomain.meals.folder, p.join('media', 'meals'));
      expect(MealPhotoStore.folderName, MediaDomain.meals.folder);
    });

    test('directoryOf creates the folder it names', () async {
      final dir = await AppMediaStore.instance.directoryOf(MediaDomain.meals);
      expect(dir.existsSync(), isTrue);
      expect(dir.path, p.join(supportDir.path, 'media', 'meals'));
    });
  });

  group('resolve', () {
    test('joins a relative path onto the support directory', () async {
      final file = await AppMediaStore.instance.resolve('media/meals/abc.jpg');
      expect(file!.path, p.join(supportDir.path, 'media/meals/abc.jpg'));
    });

    test('resolves a path from any folder, including the legacy one', () async {
      // Resolution never assumes a folder, which is what keeps rows written
      // before the media root existed working.
      final file = await AppMediaStore.instance.resolve('meal_photos/abc.jpg');
      expect(file!.path, p.join(supportDir.path, 'meal_photos/abc.jpg'));
    });

    test('passes an absolute path through untouched', () async {
      final file = await AppMediaStore.instance.resolve('/tmp/elsewhere.jpg');
      expect(file!.path, '/tmp/elsewhere.jpg');
    });

    test('has nothing to resolve for null or empty', () async {
      expect(await AppMediaStore.instance.resolve(null), isNull);
      expect(await AppMediaStore.instance.resolve(''), isNull);
    });

    test('resolveSync yields null before the directory is known', () {
      expect(AppMediaStore.instance.resolveSync('media/meals/abc.jpg'), isNull);
    });
  });

  group('thumbPathFor', () {
    test('names the preview next to the photo', () {
      expect(
        AppMediaStore.thumbPathFor('media/meals/abc.jpg'),
        'media/meals/abc_thumb.jpg',
      );
      expect(AppMediaStore.thumbPathFor(null), isNull);
      expect(AppMediaStore.thumbPathFor(''), isNull);
    });
  });

  group('pruneOrphans', () {
    test('keeps referenced files and their previews, drops the rest', () async {
      await AppMediaStore.instance.ensureInitialized();
      write('media/meals/keep.jpg', [1]);
      write('media/meals/keep_thumb.jpg', [2]);
      write('media/meals/orphan.jpg', [3]);
      write('media/meals/orphan_thumb.jpg', [4]);

      final removed = await AppMediaStore.instance.pruneOrphans(
        domain: MediaDomain.meals,
        referencedPaths: {'media/meals/keep.jpg'},
      );

      expect(removed, 2);
      expect(File(p.join(supportDir.path, 'media/meals/keep.jpg')).existsSync(),
          isTrue);
      expect(
        File(p.join(supportDir.path, 'media/meals/keep_thumb.jpg'))
            .existsSync(),
        isTrue,
      );
      expect(
        File(p.join(supportDir.path, 'media/meals/orphan.jpg')).existsSync(),
        isFalse,
      );
    });

    test('sweeps the legacy folder too', () async {
      await AppMediaStore.instance.ensureInitialized();
      write('meal_photos/orphan.jpg', [1]);
      write('media/meals/keep.jpg', [2]);

      final removed = await AppMediaStore.instance.pruneOrphans(
        domain: MediaDomain.meals,
        referencedPaths: {'media/meals/keep.jpg'},
      );

      expect(removed, 1);
      expect(
        File(p.join(supportDir.path, 'meal_photos/orphan.jpg')).existsSync(),
        isFalse,
      );
    });

    test('matches by file name, not by folder', () async {
      // A restored row may still name the legacy folder while the file it
      // refers to now lives under the media root. Deleting it because the two
      // folders differ would be exactly the wrong outcome.
      await AppMediaStore.instance.ensureInitialized();
      write('media/meals/abc.jpg', [1]);

      final removed = await AppMediaStore.instance.pruneOrphans(
        domain: MediaDomain.meals,
        referencedPaths: {'meal_photos/abc.jpg'},
      );

      expect(removed, 0);
      expect(File(p.join(supportDir.path, 'media/meals/abc.jpg')).existsSync(),
          isTrue);
    });

    test('has nothing to do when the folders are missing', () async {
      expect(
        await AppMediaStore.instance.pruneOrphans(
          domain: MediaDomain.meals,
          referencedPaths: const {},
        ),
        0,
      );
    });
  });

  group('deleteAll', () {
    test('removes each path and the preview beside it', () async {
      await AppMediaStore.instance.ensureInitialized();
      write('media/meals/abc.jpg', [1]);
      write('media/meals/abc_thumb.jpg', [2]);
      write('media/meals/extra.jpg', [3]);
      write('media/meals/extra_thumb.jpg', [4]);

      await MealPhotoStore.instance.delete(
        photoPath: 'media/meals/abc.jpg',
        thumbPath: 'media/meals/abc_thumb.jpg',
        extraPaths: const ['media/meals/extra.jpg'],
      );

      final dir = Directory(p.join(supportDir.path, 'media/meals'));
      expect(dir.listSync(), isEmpty);
    });
  });
}
