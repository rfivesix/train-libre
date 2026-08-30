import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/data/workout_photo_store.dart';

void main() {
  group('WorkoutPhotoStore', () {
    test('maxPhotos is 4', () {
      expect(WorkoutPhotoStore.maxPhotos, 4);
    });

    test('folderName is media/workouts', () {
      expect(WorkoutPhotoStore.folderName, 'media/workouts');
    });

    group('thumbPathFor', () {
      test('names the preview the way save does', () {
        expect(
          WorkoutPhotoStore.thumbPathFor('media/workouts/abc.jpg'),
          'media/workouts/abc_thumb.jpg',
        );
      });

      test('leaves nothing to delete for a missing path', () {
        expect(WorkoutPhotoStore.thumbPathFor(null), isNull);
        expect(WorkoutPhotoStore.thumbPathFor(''), isNull);
      });
    });
  });
}
