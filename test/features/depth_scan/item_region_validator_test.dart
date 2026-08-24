// test/features/depth_scan/item_region_validator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/depth_scan/domain/item_region_validator.dart';
import 'package:train_libre/features/depth_scan/domain/models/item_region.dart';
import 'package:train_libre/services/ai_meal_validation.dart';

void main() {
  group('ItemRegionValidator', () {
    test('isBoxValid returns false for areas < 1.5% or > 60%', () {
      // Too small (< 1.5%)
      expect(ItemRegionValidator.isBoxValid([0.1, 0.1, 0.05, 0.05]), isFalse);
      // Too large (> 60%)
      expect(ItemRegionValidator.isBoxValid([0.0, 0.0, 0.8, 0.8]), isFalse);
      // Valid (9%)
      expect(ItemRegionValidator.isBoxValid([0.2, 0.2, 0.3, 0.3]), isTrue);
    });

    test('calculateBoxIou calculates exact IoU between two rectangles', () {
      final a = [0.0, 0.0, 0.5, 0.5]; // 0.25
      final b = [0.0, 0.0, 0.5, 0.5]; // exact match
      expect(ItemRegionValidator.calculateBoxIou(a, b), closeTo(1.0, 0.001));

      final c = [0.5, 0.5, 0.5, 0.5]; // disjoint
      expect(ItemRegionValidator.calculateBoxIou(a, c), equals(0.0));
    });

    test('suppresses all callouts if single region exceeds 65% (Soup rule)', () {
      final items = [
        AiMealCandidateItem(
          name: 'Soup Bowl',
          grams: 400,
          regions: [
            ItemRegion(box: [0.1, 0.1, 0.85, 0.85]), // area 0.7225 = 72% > 65%
          ],
        ),
        AiMealCandidateItem(
          name: 'Parsley',
          grams: 5,
          regions: [
            ItemRegion(box: [0.4, 0.4, 0.1, 0.1]),
          ],
        ),
      ];

      final validated = ItemRegionValidator.validateMealItems<AiMealCandidateItem>(
        items: items,
        regionsExtractor: (it) => it.regions,
        kcalExtractor: (it) => it.grams * 2.0,
      );
      expect(validated, isEmpty);
    });

    test('suppresses callouts if fewer than 2 valid distinct items remain', () {
      final items = [
        AiMealCandidateItem(
          name: 'Sole Steak',
          grams: 250,
          regions: [
            ItemRegion(box: [0.2, 0.2, 0.4, 0.4]), // area 16% (valid)
          ],
        ),
        AiMealCandidateItem(
          name: 'Salt',
          grams: 2,
          regions: const [],
        ),
      ];

      final validated = ItemRegionValidator.validateMealItems<AiMealCandidateItem>(
        items: items,
        regionsExtractor: (it) => it.regions,
        kcalExtractor: (it) => it.grams * 2.0,
      );
      // Only 1 item has valid region -> minimum 2 threshold suppresses callouts to avoid floating lone pill
      expect(validated, isEmpty);
    });

    test('retains valid callouts when 2 or more distinct items have valid regions', () {
      final items = [
        AiMealCandidateItem(
          name: 'Chicken Breast',
          grams: 165,
          regions: [
            ItemRegion(box: [0.1, 0.2, 0.3, 0.3]),
          ],
        ),
        AiMealCandidateItem(
          name: 'Basmati Rice',
          grams: 180,
          regions: [
            ItemRegion(box: [0.5, 0.2, 0.3, 0.3]),
          ],
        ),
      ];

      final validated = ItemRegionValidator.validateMealItems<AiMealCandidateItem>(
        items: items,
        regionsExtractor: (it) => it.regions,
        kcalExtractor: (it) => it.grams * 2.0,
      );
      expect(validated.length, equals(2));
      expect(validated[0].validRegions.length, equals(1));
      expect(validated[1].validRegions.length, equals(1));
    });
  });
}
