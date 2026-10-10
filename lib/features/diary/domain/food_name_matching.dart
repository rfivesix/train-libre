import 'models/food_item.dart';

/// Shared catalog/query normalization and lexical relevance.
/// Synonyms come from catalog aliases, never from suffix guessing.
abstract final class FoodNameMatching {
  static final _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  // Keep German transliterations distinct from unrelated plain vowels.
  static const folds = {
    'a\u0308': 'ae',
    'o\u0308': 'oe',
    'u\u0308': 'ue',
    'ä': 'ae',
    'ö': 'oe',
    'ü': 'ue',
    'ß': 'ss',
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ç': 'c',
    'ñ': 'n',
    'œ': 'oe',
    'æ': 'ae',
    '\u0300': '',
    '\u0301': '',
    '\u0302': '',
    '\u0303': '',
    '\u0308': '',
    '\u0327': '',
  };

  static String normalize(String value) {
    var result = value.toLowerCase();
    for (final fold in folds.entries) {
      result = result.replaceAll(fold.key, fold.value);
    }
    // Combining accents must not introduce a word boundary.
    return result
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(_separators, ' ')
        .trim();
  }

  static List<String> tokens(String value) => normalize(value)
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toSet()
      .toList();

  /// Lower is better: identity, complete words, word prefixes, no match.
  static int textRank(String query, String name, {bool compactNames = false}) {
    final q = normalize(query);
    final n = normalize(name);
    if (q.isEmpty || n.isEmpty) return 4;
    if (q == n || (compactNames && compact(q) == compact(n))) return 0;
    final queryTokens = tokens(q);
    final nameTokens = tokens(n);
    if (queryTokens.every(nameTokens.contains)) return 1;
    if (queryTokens.every((q) => nameTokens.any((n) => n.startsWith(q)))) {
      return 2;
    }
    if (compactNames && compact(n).startsWith(compact(q))) return 3;
    return 4;
  }

  static int rank(String query, FoodItem food, {bool includeBrand = true}) {
    var best = 4;
    for (final name in names(food, includeBrand: includeBrand)) {
      final score = textRank(query, name,
          compactNames: food.source == FoodItemSource.base);
      if (score < best) best = score;
    }
    if (food.catalogMatchAlias case final alias?) {
      final score = textRank(query, alias, compactNames: true);
      final approved = food.catalogMatchScope == 'identity' &&
          food.catalogMatchReviewStatus == 'approved';
      final aliasScore = score == 4 ? 4 : (approved ? score : score + 1);
      if (aliasScore < best) best = aliasScore;
    }
    return best;
  }

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
