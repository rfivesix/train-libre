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

    final selectedBarcode = item.matchedBarcode?.trim();
    if (selectedBarcode != null && selectedBarcode.isNotEmpty) {
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
        .toList(growable: false)
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return _sourcePriority(a.food.source).compareTo(
          _sourcePriority(b.food.source),
        );
      });

    final best = scored.first;
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
    final queries = <String>{
      item.name,
      item.catalogSearchTerm ?? '',
      ...item.searchTerms,
    };
    var bestScore = 0.0;
    for (final query in queries) {
      bestScore = AiMealValidationEngine._maxDouble(
        bestScore,
        _matchScoreForQuery(query, food),
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

  double _matchScoreForQuery(String query, FoodItem food) {
    final normalizedQuery = AiMealValidationEngine._normalizeText(query);
    if (normalizedQuery.isEmpty) return 0;
    final names = {
      food.name,
      food.nameDe,
      food.nameEn,
    }
        .where((name) => name.trim().isNotEmpty)
        .map(AiMealValidationEngine._normalizeText)
        .toSet();

    if (names.any((name) => name == normalizedQuery)) return 1.0;
    if (names.any((name) => name.startsWith(normalizedQuery))) return 0.86;
    if (names.any((name) => normalizedQuery.startsWith(name))) return 0.78;

    final queryTokens = normalizedQuery.split(' ').where((t) => t.length > 1);
    var best = 0.0;
    for (final name in names) {
      if (name.contains(normalizedQuery)) {
        best = AiMealValidationEngine._maxDouble(best, 0.70);
      }
      final nameTokens = name.split(' ').where((t) => t.length > 1).toSet();
      if (nameTokens.isEmpty) continue;
      final overlap = queryTokens.where(nameTokens.contains).length;
      if (overlap > 0) {
        best = AiMealValidationEngine._maxDouble(
          best,
          overlap / queryTokens.length * 0.65,
        );
      }
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
