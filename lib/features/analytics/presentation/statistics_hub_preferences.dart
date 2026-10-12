import 'package:shared_preferences/shared_preferences.dart';

/// Stable identifiers for the cards that can appear in the statistics hub.
enum StatisticsHubCardId {
  steps('steps', 'activity'),
  sleep('sleep', 'recovery'),
  pulse('pulse', 'recovery'),
  bodyNutrition('bodyNutrition', 'body'),
  bodyMeasurements('bodyMeasurements', 'body'),
  consistency('consistency', 'training'),
  performance('performance', 'training'),
  muscleGroups('muscleGroups', 'training'),
  macros('macros', 'nutrition');

  const StatisticsHubCardId(this.storageId, this.categoryId);

  final String storageId;
  final String categoryId;

  static StatisticsHubCardId? fromStorageId(String value) {
    for (final card in values) {
      if (card.storageId == value) return card;
    }
    return null;
  }
}

class StatisticsHubPreferences {
  static const _key = 'statistics_hub_pinned_cards_v2';

  static const defaultPinnedCards = <StatisticsHubCardId>[
    StatisticsHubCardId.bodyNutrition,
    StatisticsHubCardId.macros,
    StatisticsHubCardId.bodyMeasurements,
    StatisticsHubCardId.consistency,
    StatisticsHubCardId.muscleGroups,
    StatisticsHubCardId.performance,
  ];

  static const _previousDefaultPinnedCards = <String>[
    'steps',
    'sleep',
    'bodyNutrition',
    'consistency',
  ];

  static Future<List<StatisticsHubCardId>> loadPinnedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key);
    if (stored == null || _matchesPreviousDefaults(stored)) {
      return List<StatisticsHubCardId>.of(defaultPinnedCards);
    }
    // Keep newly introduced cards available in the add list, without pinning
    // them automatically for users who already customized their hub.
    final cards = <StatisticsHubCardId>[];
    for (final storedId in stored) {
      final card = StatisticsHubCardId.fromStorageId(storedId);
      if (card != null && !cards.contains(card)) cards.add(card);
    }
    return cards;
  }

  static bool _matchesPreviousDefaults(List<String> stored) {
    if (stored.length != _previousDefaultPinnedCards.length) return false;
    for (var i = 0; i < stored.length; i++) {
      if (stored[i] != _previousDefaultPinnedCards[i]) return false;
    }
    return true;
  }

  static Future<void> savePinnedCards(List<StatisticsHubCardId> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      cards.map((card) => card.storageId).toList(growable: false),
    );
  }
}
