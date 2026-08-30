import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/core/media/app_media_store.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/diary/data/meal_photo_store.dart';
import 'package:train_libre/features/workout/data/workout_photo_store.dart';

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
      expect(MediaDomain.workouts.folder, p.join('media', 'workouts'));
      expect(WorkoutPhotoStore.folderName, MediaDomain.workouts.folder);
    });

    test('directoryOf creates the folder it names', () async {
      final dir = await AppMediaStore.instance.directoryOf(MediaDomain.meals);
      expect(dir.existsSync(), isTrue);
      expect(dir.path, p.join(supportDir.path, 'media', 'meals'));

      final workoutDir =
          await AppMediaStore.instance.directoryOf(MediaDomain.workouts);
      expect(workoutDir.existsSync(), isTrue);
      expect(workoutDir.path, p.join(supportDir.path, 'media', 'workouts'));
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
      expect(
        AppMediaStore.thumbPathFor('media/workouts/xyz.jpg'),
        'media/workouts/xyz_thumb.jpg',
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
      write('media/meals/drop.jpg', [3]);
      write('media/meals/drop_thumb.jpg', [4]);

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
          isTrue);
      expect(File(p.join(supportDir.path, 'media/meals/drop.jpg')).existsSync(),
          isFalse);
      expect(
          File(p.join(supportDir.path, 'media/meals/drop_thumb.jpg'))
              .existsSync(),
          isFalse);
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

    test('matches referenced files by name regardless of folder path',
        () async {
      // Row references `meal_photos/abc.jpg` (legacy), but the actual file
      // sits in `media/meals/abc.jpg` — must not be pruned.
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

  group('mealThumbPlacement', () {
    // The one that bit us in the field: a meal logged by a build that stored
    // photos under `meal_photos/` names that folder in its row forever. Its
    // restored preview has to land there, not in this build's own folder, or
    // the row points at nothing and the meal shows up without its picture.
    Future<AppDatabase> mealDb(List<Map<String, String?>> entries) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (var i = 0; i < entries.length; i++) {
        await db.customStatement(
          'INSERT INTO meal_entries (id, consumed_at, meal_type, title, '
          'source, photo_path, photo_thumb_path) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            'entry-$i',
            1787000000,
            'mealtypeLunch',
            'Pizza',
            'aiPhoto',
            entries[i]['photo'],
            entries[i]['thumb'],
          ],
        );
      }
      return db;
    }

    test('sends a preview to the folder its row names', () async {
      final db = await mealDb([
        {
          'photo': 'meal_photos/abc.jpg',
          'thumb': 'meal_photos/abc_thumb.jpg',
        },
      ]);

      final placement = await AppMediaStore.instance.mealThumbPlacement(db);

      expect(
        placement.directoryFor('abc_thumb.jpg').path,
        p.join(supportDir.path, 'meal_photos'),
      );
    });

    test('follows each row separately', () async {
      final db = await mealDb([
        {'photo': 'meal_photos/old.jpg', 'thumb': 'meal_photos/old_thumb.jpg'},
        {'photo': 'media/meals/new.jpg', 'thumb': 'media/meals/new_thumb.jpg'},
      ]);

      final placement = await AppMediaStore.instance.mealThumbPlacement(db);

      expect(placement.directoryFor('old_thumb.jpg').path,
          p.join(supportDir.path, 'meal_photos'));
      expect(placement.directoryFor('new_thumb.jpg').path,
          p.join(supportDir.path, 'media', 'meals'));
    });

    test('falls back to this feature folder for a preview no row claims',
        () async {
      final db = await mealDb(const []);

      final placement = await AppMediaStore.instance.mealThumbPlacement(db);

      expect(
        placement.directoryFor('orphan_thumb.jpg').path,
        p.join(supportDir.path, 'media', 'meals'),
      );
    });

    test('finds the preview of a row that only stores its photo', () async {
      // Written before previews were stored as their own column, and the
      // extra shots of a multi-photo capture, are found by convention.
      final db = await mealDb([
        {'photo': 'meal_photos/abc.jpg', 'thumb': null},
      ]);

      final placement = await AppMediaStore.instance.mealThumbPlacement(db);

      expect(placement.directoryFor('abc_thumb.jpg').path,
          p.join(supportDir.path, 'meal_photos'));
    });
  });

  group('workoutThumbPlacement', () {
    Future<AppDatabase> workoutDb(List<Map<String, dynamic>> entries) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (var i = 0; i < entries.length; i++) {
        await db.customStatement(
          'INSERT INTO workout_logs (id, local_id, start_time, end_time, status, '
          'photo_path, photo_thumb_path, photo_extra_paths) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'workout-$i',
            i + 1,
            1787000000,
            1787003600,
            'completed',
            entries[i]['photo'],
            entries[i]['thumb'],
            entries[i]['extras'],
          ],
        );
      }
      return db;
    }

    test('sends a preview to the folder its row names and finds extras',
        () async {
      final db = await workoutDb([
        {
          'photo': 'media/workouts/w1.jpg',
          'thumb': 'media/workouts/w1_thumb.jpg',
          'extras': jsonEncode(['media/workouts/w2.jpg', 'media/workouts/w3.jpg']),
        },
      ]);

      final placement =
          await AppMediaStore.instance.workoutThumbPlacement(db);

      expect(
        placement.directoryFor('w1_thumb.jpg').path,
        p.join(supportDir.path, 'media', 'workouts'),
      );
      expect(
        placement.directoryFor('w2_thumb.jpg').path,
        p.join(supportDir.path, 'media', 'workouts'),
      );
      expect(
        placement.directoryFor('w3_thumb.jpg').path,
        p.join(supportDir.path, 'media', 'workouts'),
      );
    });

    test('referencedWorkoutPaths collects photoPath and extraPaths', () async {
      final db = await workoutDb([
        {
          'photo': 'media/workouts/w1.jpg',
          'thumb': 'media/workouts/w1_thumb.jpg',
          'extras': jsonEncode(['media/workouts/w2.jpg']),
        },
        {
          'photo': null,
          'thumb': null,
          'extras': null,
        },
      ]);

      final paths = await AppMediaStore.referencedWorkoutPaths(db);
      expect(paths, {
        'media/workouts/w1.jpg',
        'media/workouts/w1_thumb.jpg',
        'media/workouts/w2.jpg',
      });
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

      final dir = Directory(p.join(supportDir.path, 'media', 'meals'));
      expect(dir.listSync(), isEmpty);
    });

    test('removes workout paths and extra photos', () async {
      await AppMediaStore.instance.ensureInitialized();
      write('media/workouts/w1.jpg', [1]);
      write('media/workouts/w1_thumb.jpg', [2]);
      write('media/workouts/w2.jpg', [3]);
      write('media/workouts/w2_thumb.jpg', [4]);

      await WorkoutPhotoStore.instance.delete(
        photoPath: 'media/workouts/w1.jpg',
        thumbPath: 'media/workouts/w1_thumb.jpg',
        extraPaths: const ['media/workouts/w2.jpg'],
      );

      final dir = Directory(p.join(supportDir.path, 'media', 'workouts'));
      expect(dir.listSync(), isEmpty);
    });
  });
}
