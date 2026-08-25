import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/data/meal_photo_store.dart';

void main() {
  group('MealPhotoStore.thumbPathFor', () {
    // Extra photos of a multi-shot capture only store their full-size path, so
    // deletion and orphan pruning find the preview by this convention. It has
    // to keep matching what `save` writes.
    test('names the preview the way save does', () {
      expect(
        MealPhotoStore.thumbPathFor('meal_photos/abc.jpg'),
        'meal_photos/abc_thumb.jpg',
      );
    });

    test('leaves nothing to delete for a missing path', () {
      expect(MealPhotoStore.thumbPathFor(null), isNull);
      expect(MealPhotoStore.thumbPathFor(''), isNull);
    });
  });
}
