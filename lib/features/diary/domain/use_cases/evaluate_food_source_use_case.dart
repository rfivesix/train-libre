import '../models/food_item.dart';

/// Use Case to score and prioritize food source candidates.
/// Prioritizes exact matches, starts-with prefixes, and specific source types
/// (base/user first, then OFF).
class EvaluateFoodSourceUseCase {
  const EvaluateFoodSourceUseCase();

  List<FoodItem> execute({
    required List<FoodItem> candidates,
    required String searchTerm,
    int limit = 5,
  }) {
    final searchLower = searchTerm.trim().toLowerCase();
    final items = List<FoodItem>.from(candidates);

    items.sort((a, b) {
      int score(FoodItem item) {
        final name = item.name.toLowerCase();
        final brand = item.brand?.trim().toLowerCase() ?? '';
        final fullName1 = brand.isEmpty ? name : '$brand $name';
        final fullName2 = brand.isEmpty ? name : '$name $brand';

        if (name == searchLower ||
            fullName1 == searchLower ||
            fullName2 == searchLower) {
          return 0;
        }
        if (name.startsWith(searchLower) ||
            fullName1.startsWith(searchLower) ||
            fullName2.startsWith(searchLower)) {
          return 1;
        }
        return 2;
      }

      final sa = score(a);
      final sb = score(b);
      if (sa != sb) return sa.compareTo(sb);

      int srcPri(FoodItemSource s) {
        switch (s) {
          case FoodItemSource.base:
            return 0;
          case FoodItemSource.user:
            return 1;
          case FoodItemSource.off:
            return 2;
        }
      }

      final spa = srcPri(a.source);
      final spb = srcPri(b.source);
      if (spa != spb) return spa.compareTo(spb);

      return a.name.length.compareTo(b.name.length);
    });

    return items.take(limit).toList();
  }
}
