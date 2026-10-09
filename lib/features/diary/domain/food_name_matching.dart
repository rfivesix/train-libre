import 'models/food_item.dart';

/// Query-time normalization only: no catalog edits or food-specific vocabulary.
abstract final class FoodNameMatching {
  static final _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  static String normalize(String value) =>
      value.toLowerCase().replaceAll(_separators, ' ').trim();

  static String compact(String value) => normalize(value).replaceAll(' ', '');

  static Set<String> names(FoodItem food, {bool includeBrand = false}) {
    final names = {
      food.name,
      food.nameDe,
      food.nameEn,
      food.nameFr,
      food.nameIt,
      food.nameJa,
    }..removeWhere((name) => name.trim().isEmpty);
    if (includeBrand && food.brand.trim().isNotEmpty) {
      return {
        ...names,
        for (final name in names) '${food.brand} $name',
        for (final name in names) '$name ${food.brand}',
      };
    }
    return names;
  }
}
