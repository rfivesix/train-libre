import '../models/food_item.dart';
import '../food_name_matching.dart';

/// Use Case to score and prioritize food source candidates.
/// Prioritizes exact matches, starts-with prefixes, and specific source types
/// (base/user first, then OFF).
class EvaluateFoodSourceUseCase {
  const EvaluateFoodSourceUseCase();

  List<FoodItem> execute({
    required List<FoodItem> candidates,
    required String searchTerm,
    Iterable<String> searchTerms = const [],
    int limit = 5,
    bool preserveSourceCandidates = false,
  }) {
    final searchLowers = <String>{
      FoodNameMatching.normalize(searchTerm),
      ...searchTerms.map(FoodNameMatching.normalize),
    }..removeWhere((term) => term.isEmpty);
    if (searchLowers.isEmpty) return [];
    final items = List<FoodItem>.from(candidates);

    int score(FoodItem item) => searchLowers
        .map((term) => FoodNameMatching.rank(term, item))
        .reduce((a, b) => a < b ? a : b);

    final scores = {for (final item in items) item: score(item)};
    items.removeWhere((item) => scores[item]! >= 4);
    items.sort((a, b) {
      final sa = scores[a]!;
      final sb = scores[b]!;
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

      // An exact alias can surface several BLS variants. This affects only
      // retrieval order; validation still treats unreviewed aliases as weak.
      final aAlias = a.catalogMatchAlias != null &&
          searchLowers.any((term) =>
              FoodNameMatching.compact(a.catalogMatchAlias!) ==
              FoodNameMatching.compact(term));
      final bAlias = b.catalogMatchAlias != null &&
          searchLowers.any((term) =>
              FoodNameMatching.compact(b.catalogMatchAlias!) ==
              FoodNameMatching.compact(term));
      if (sa == 1 && aAlias != bAlias) return aAlias ? -1 : 1;

      final lengthCompare = a.name.length.compareTo(b.name.length);
      if (lengthCompare != 0) return lengthCompare;
      final nameCompare = a.name.compareTo(b.name);
      return nameCompare != 0 ? nameCompare : a.barcode.compareTo(b.barcode);
    });

    if (!preserveSourceCandidates) return items.take(limit).toList();
    // Each source keeps its own bounded shortlist until final validation.
    // OFF exact names can never consume the slots reserved for BLS foods.
    final counts = <FoodItemSource, int>{};
    return items.where((item) {
      final count =
          counts.update(item.source, (value) => value + 1, ifAbsent: () => 1);
      return count <= limit;
    }).toList(growable: false);
  }
}
