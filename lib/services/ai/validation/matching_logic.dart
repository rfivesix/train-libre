part of '../../ai_meal_validation.dart';

extension MatchingLogic on AiMealValidationEngine {
  AiMatchResult _evaluateMatch(
    AiMealCandidateItem item,
    List<FoodItem> matches,
  ) {
    final query = item.name.trim();
    if (matches.isEmpty) {
      return AiMatchResult(
        query: query,
        bestMatch: null,
        alternatives: const [],
        quality: AiMatchQuality.unmatched,
        isAmbiguous: false,
        score: 0,
      );
    }

    final selectedBarcode =
        item.selectedFood?.barcode ?? item.matchedBarcode?.trim();
    final hasExplicitPackagedProduct = item.isPackagedProduct;
    if (selectedBarcode != null &&
        selectedBarcode.isNotEmpty &&
        (item.selectedFood != null || hasExplicitPackagedProduct)) {
      final selectedMatches = matches
          .where((food) => food.barcode == selectedBarcode)
          .toList(growable: false);
      if (selectedMatches.isNotEmpty) {
        return AiMatchResult(
          query: query,
          bestMatch: selectedMatches.first,
          alternatives: matches,
          quality: AiMatchQuality.exact,
          isAmbiguous: false,
          score: 1.0,
        );
      }
    }

    final scored = matches
        .map(
          (food) => _ScoredFood(
            food: food,
            score: _matchScore(item, food),
          ),
        )
        .toList(growable: false);
    final highestScore = scored.fold<double>(
      0,
      (highest, item) => item.score > highest ? item.score : highest,
    );
    scored.sort((a, b) {
      // For generic ingredients, prefer canonical base-food candidates that
      // are close to the strongest text match. A weak base-food coincidence
      // cannot displace a clearly better match.
      final aIsNearBest =
          !hasExplicitPackagedProduct && a.score >= highestScore - 0.18;
      final bIsNearBest =
          !hasExplicitPackagedProduct && b.score >= highestScore - 0.18;
      if (aIsNearBest != bIsNearBest) {
        return aIsNearBest ? -1 : 1;
      }
      if (aIsNearBest && bIsNearBest) {
        final sourceCompare = _sourcePriority(a.food.source).compareTo(
          _sourcePriority(b.food.source),
        );
        if (sourceCompare != 0) return sourceCompare;
      }
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final sourceCompare = _sourcePriority(a.food.source).compareTo(
        _sourcePriority(b.food.source),
      );
      if (sourceCompare != 0) return sourceCompare;
      final nameCompare = a.food.name.compareTo(b.food.name);
      return nameCompare != 0
          ? nameCompare
          : a.food.barcode.compareTo(b.food.barcode);
    });

    final best = scored.first;
    final bestAliasIsUnreviewed = best.food.catalogMatchAlias != null &&
        best.food.catalogMatchReviewStatus != 'approved';
    if (bestAliasIsUnreviewed && best.score <= 0.54) {
      // An unreviewed/broad alias is retrieval evidence only. Keep every
      // candidate available to the repair/clarification flow without silently
      // assigning nutrients to one preparation or variant.
      return AiMatchResult(
        query: query,
        bestMatch: null,
        alternatives: scored.map((entry) => entry.food).toList(growable: false),
        quality: AiMatchQuality.unmatched,
        isAmbiguous: scored.length > 1,
        score: 0,
      );
    }

    final alternatives = scored.map((e) => e.food).toList(growable: false);
    final secondScore = scored.length > 1 ? scored[1].score : 0.0;
    final isAmbiguous = scored.length > 1 &&
        best.score < 0.95 &&
        (best.score - secondScore).abs() <= 0.08;
    final competingAlternatives = isAmbiguous
        ? scored
            .skip(1)
            .where((e) =>
                (best.score - e.score) <= 0.08 &&
                e.food.barcode != best.food.barcode)
            .map((e) => e.food)
            .toList(growable: false)
        : const <FoodItem>[];

    final quality = switch (best.score) {
      >= 0.95 => AiMatchQuality.exact,
      >= 0.78 => AiMatchQuality.strong,
      >= 0.55 => AiMatchQuality.partial,
      >= 0.35 => AiMatchQuality.weak,
      _ => AiMatchQuality.weak,
    };

    return AiMatchResult(
      query: query,
      bestMatch: best.food,
      alternatives: alternatives,
      competingAlternatives: competingAlternatives,
      quality: quality,
      isAmbiguous: isAmbiguous,
      score: best.score,
    );
  }

  double _matchScore(AiMealCandidateItem item, FoodItem food) {
    final productQuery = item.catalogSearchTerm?.trim();
    // Once packaging is evidenced, a specific product query must not tie with
    // an exact generic name merely because the ingredient label is shorter.
    final queries = item.isPackagedProduct &&
            productQuery != null &&
            productQuery.isNotEmpty
        ? <String>{productQuery}
        : <String>{
            item.name,
            item.catalogSearchTerm ?? '',
            ...item.searchTerms
          };
    var bestScore = 0.0;
    for (final query in queries) {
      bestScore = AiMealValidationEngine._maxDouble(
        bestScore,
        _matchScoreForQuery(query, food, includeBrand: item.isPackagedProduct),
      );
    }

    // State alignment boost: if the AI specified a preparation state (e.g. cooked,
    // raw) and the candidate catalog item explicitly matches that state, give a
    // small boost so a state-matched item (e.g. "Reis gekocht") isn't penalized
    // against a raw entry when cooked was photographed.
    final hint = item.stateHint?.trim().toLowerCase();
    if (hint != null && hint.isNotEmpty && bestScore >= 0.65) {
      final dbName = AiMealValidationEngine._normalizeText(food.name);
      final isPreparedHint = AiMealValidationEngine.isPreparedState(hint);
      final isRawHint = hint == 'raw' || hint == 'roh';

      final isPreparedDb = dbName.contains('cooked') ||
          dbName.contains('boiled') ||
          dbName.contains('gekocht') ||
          dbName.contains('fried') ||
          dbName.contains('gebraten') ||
          dbName.contains('baked') ||
          dbName.contains('gebacken') ||
          dbName.contains('zubereitet');
      final isRawDb = dbName.contains('raw') || dbName.contains('roh');

      if ((isPreparedHint && isPreparedDb) || (isRawHint && isRawDb)) {
        bestScore = (bestScore + 0.04).clamp(0.0, 1.0);
      }
    }

    return bestScore;
  }

  double _matchScoreForQuery(String query, FoodItem food,
      {bool includeBrand = false}) {
    final normalizedQuery = AiMealValidationEngine._normalizeText(query);
    if (normalizedQuery.isEmpty) return 0;
    final rawNames = FoodNameMatching.names(food, includeBrand: includeBrand);

    final names = rawNames.map(AiMealValidationEngine._normalizeText).toSet();

    if (names.any((name) => name == normalizedQuery)) return 1.0;

    // Preparation qualifiers remain meaningful to the AI validation rules.
    // Only that domain treats a base food's parenthetical stem as identity.
    if (food.source == FoodItemSource.base &&
        rawNames.any((name) =>
            FoodNameMatching.normalize(
                name.replaceAll(RegExp(r'\s*\([^)]*\)'), '')) ==
            normalizedQuery)) {
      return 1.0;
    }
    var best = 0.0;
    for (final name in rawNames) {
      final rank = FoodNameMatching.textRank(query, name,
          compactNames: food.source == FoodItemSource.base);
      final score = switch (rank) {
        0 => 1.0,
        1 => food.source == FoodItemSource.base ? 0.88 : 0.82,
        2 || 3 => 0.70,
        _ => 0.0,
      };
      best = AiMealValidationEngine._maxDouble(best, score);
    }
    if (food.catalogMatchAlias != null &&
        FoodNameMatching.compact(food.catalogMatchAlias!) ==
            FoodNameMatching.compact(query)) {
      final approvedIdentity = food.catalogMatchScope == 'identity' &&
          food.catalogMatchReviewStatus == 'approved';
      return AiMealValidationEngine._maxDouble(
          best, approvedIdentity ? 1.0 : 0.50);
    }
    return best;
  }

  bool _hasStateMismatch(String aiName, String dbName) {
    final ai = AiMealValidationEngine._normalizeText(aiName);
    final db = AiMealValidationEngine._normalizeText(dbName);
    const stateGroups = [
      ['raw', 'roh'],
      ['cooked', 'boiled', 'gekocht'],
      ['fried', 'gebraten'],
      ['dry', 'dried', 'trocken', 'getrocknet'],
    ];

    String? stateFor(String text) {
      for (final group in stateGroups) {
        if (group.any(text.contains)) return group.first;
      }
      return null;
    }

    final aiState = stateFor(ai);
    final dbState = stateFor(db);
    return aiState != null && dbState != null && aiState != dbState;
  }

  int _sourcePriority(FoodItemSource source) {
    return switch (source) {
      FoodItemSource.base => 0,
      FoodItemSource.user => 1,
      FoodItemSource.off => 2,
    };
  }
}
