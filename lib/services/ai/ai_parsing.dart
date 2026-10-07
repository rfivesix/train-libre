part of '../ai_service.dart';

List<String> _parseSearchTerms(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<String>()
      .map((term) => term.trim())
      .where((term) => term.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

AiMealCandidateItem _parseCandidateItem(Map<String, dynamic> e) {
  final grams = (e['estimatedGrams'] as num?)?.toInt() ??
      (e['grams'] as num?)?.toInt() ??
      (e['servedGrams'] as num?)?.toInt() ??
      0;
  final served = (e['servedGrams'] as num?)?.toInt() ??
      (e['estimatedGrams'] as num?)?.toInt() ??
      (e['grams'] as num?)?.toInt();
  return AiMealCandidateItem(
    name: (e['name'] as String?) ?? '',
    grams: grams,
    confidence: (e['confidence'] as num?)?.toDouble(),
    servedGrams: served,
    matchedBarcode: e['matchedBarcode'] as String?,
    stateHint: e['stateHint'] as String?,
    catalogSearchTerm: e['catalogSearchTerm'] as String?,
    searchTerms: _parseSearchTerms(e['searchTerms']),
  );
}

extension AiParsing on AiService {
  /// Extracts the meal candidate (holistic context and items) from the AI response off the main thread.
  Future<AiMealCandidate> _parseMealCandidateFromContent(String content) async {
    return Isolate.run(() => _parseMealCandidateFromContentSync(content));
  }

  AiMealCandidate _parseMealCandidateFromContentSync(String content) {
    debugPrint('[AiParsing] Attempting to parse meal candidate from AI response:\n$content');
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        final contextMap = decoded['mealContext'];
        final AiMealContext? mealContext =
            contextMap != null && contextMap is Map<String, dynamic>
                ? AiMealContext.fromJson(contextMap)
                : null;

        final rawItems = decoded['items'];
        if (rawItems is List) {
          final items = rawItems
              .whereType<Map<String, dynamic>>()
              .map(_parseCandidateItem)
              .toList();
          return AiMealCandidate(
            context: mealContext,
            items: items,
          );
        }
      }

      if (decoded is List) {
        final items = decoded
            .whereType<Map<String, dynamic>>()
            .map(_parseCandidateItem)
            .toList();
        return AiMealCandidate(items: items);
      }
    } catch (e) {
      debugPrint('[AiParsing] Direct jsonDecode failed: $e');
    }

    final startBracket = cleaned.indexOf('{');
    final endBracket = cleaned.lastIndexOf('}');
    if (startBracket != -1 && endBracket != -1 && endBracket > startBracket) {
      try {
        final jsonStr = cleaned.substring(startBracket, endBracket + 1);
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final contextMap = decoded['mealContext'];
        final AiMealContext? mealContext =
            contextMap != null && contextMap is Map<String, dynamic>
                ? AiMealContext.fromJson(contextMap)
                : null;

        final rawItems = decoded['items'];
        if (rawItems is List) {
          final items = rawItems
              .whereType<Map<String, dynamic>>()
              .map(_parseCandidateItem)
              .toList();
          return AiMealCandidate(
            context: mealContext,
            items: items,
          );
        } else if (decoded.containsKey('name')) {
          // In case model returned a single food item object instead of a list
          return AiMealCandidate(
            context: mealContext,
            items: [_parseCandidateItem(decoded)],
          );
        }
      } catch (e) {
        debugPrint('[AiParsing] Bracket extraction jsonDecode failed: $e');
      }
    }

    final startArray = cleaned.indexOf('[');
    final endArray = cleaned.lastIndexOf(']');
    if (startArray != -1 && endArray != -1 && endArray > startArray) {
      try {
        final jsonStr = cleaned.substring(startArray, endArray + 1);
        final List<dynamic> itemsList = jsonDecode(jsonStr) as List<dynamic>;
        final items = itemsList
            .whereType<Map<String, dynamic>>()
            .map(_parseCandidateItem)
            .toList();
        return AiMealCandidate(items: items);
      } catch (e) {
        debugPrint('[AiParsing] Array extraction jsonDecode failed: $e');
      }
    }

    // Final fallback: If model returned plain text bullet points (e.g. "- Bread\n- Tomato")
    final bulletLines = cleaned
        .split('\n')
        .map((l) => l.trim())
        .where((l) => RegExp(r'^[-*•\d\.]+\s+').hasMatch(l))
        .map((l) => l.replaceFirst(RegExp(r'^[-*•\d\.]+\s+'), '').trim())
        .where((l) => l.isNotEmpty && !l.toLowerCase().startsWith('the meal'))
        .toList();

    if (bulletLines.isNotEmpty) {
      debugPrint('[AiParsing] Fallback parsing bullet points into candidate items: $bulletLines');
      final fallbackItems = bulletLines.map((line) {
        // Check for grams or amounts in bullet line if any (e.g. "Bread (50g)" or "50g Bread")
        final gramMatch = RegExp(r'(\d+)\s*g\b', caseSensitive: false).firstMatch(line);
        final grams = gramMatch != null ? int.tryParse(gramMatch.group(1)!) ?? 100 : 100;
        final cleanName = line
            .replaceAll(RegExp(r'\(\s*\d+\s*g\s*\)', caseSensitive: false), '')
            .replaceAll(RegExp(r'\b\d+\s*g\b', caseSensitive: false), '')
            .trim();
        return AiMealCandidateItem(
          name: cleanName.isNotEmpty ? cleanName : line,
          grams: grams,
          confidence: 0.8,
        );
      }).toList();

      return AiMealCandidate(
        items: fallbackItems,
      );
    }

    debugPrint('[AiParsing] Failed to parse meal candidate. Raw AI response:\n$content');
    throw const AiParseException(
        'No valid JSON object or array found in response.');
  }

  /// Extracts the JSON array from the AI response text off the main thread.
  Future<List<AiSuggestedItem>> _parseItemsFromContent(String content) async {
    return Isolate.run(() => _parseItemsFromContentSync(content));
  }

  List<AiSuggestedItem> _parseItemsFromContentSync(String content) {
    debugPrint('[AiParsing] Attempting to parse suggested items from AI response:\n$content');
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

    // First attempt: try full jsonDecode in case the response is clean JSON
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        final list = decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => AiSuggestedItem.fromJson(e))
            .toList();
        if (list.isNotEmpty) return list;
      } else if (decoded is Map<String, dynamic>) {
        final rawItems = decoded['items'];
        if (rawItems is List) {
          final list = rawItems
              .whereType<Map<String, dynamic>>()
              .map((e) => AiSuggestedItem.fromJson(e))
              .toList();
          if (list.isNotEmpty) return list;
        } else if (decoded.containsKey('name')) {
          return [AiSuggestedItem.fromJson(decoded)];
        }
      }
    } catch (e) {
      debugPrint('[AiParsing] Direct items jsonDecode failed: $e');
    }

    // Second attempt: search for array delimiters [ ... ]
    final startIdx = cleaned.indexOf('[');
    final endIdx = cleaned.lastIndexOf(']');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      try {
        final jsonStr = cleaned.substring(startIdx, endIdx + 1);
        final List<dynamic> items = jsonDecode(jsonStr) as List<dynamic>;
        if (items.isNotEmpty) {
          return items
              .whereType<Map<String, dynamic>>()
              .map((e) => AiSuggestedItem.fromJson(e))
              .toList();
        }
      } catch (e) {
        debugPrint('[AiParsing] Items array extraction failed: $e');
      }
    }

    // Third attempt: search for object delimiters { ... } containing "items"
    final startObj = cleaned.indexOf('{');
    final endObj = cleaned.lastIndexOf('}');
    if (startObj != -1 && endObj != -1 && endObj > startObj) {
      try {
        final jsonStr = cleaned.substring(startObj, endObj + 1);
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          final rawItems = decoded['items'];
          if (rawItems is List && rawItems.isNotEmpty) {
            return rawItems
                .whereType<Map<String, dynamic>>()
                .map((e) => AiSuggestedItem.fromJson(e))
                .toList();
          } else if (decoded.containsKey('name')) {
            return [AiSuggestedItem.fromJson(decoded)];
          }
        }
      } catch (e) {
        debugPrint('[AiParsing] Items object extraction failed: $e');
      }
    }

    // Fourth attempt: If model returned plain text bullet points (e.g. "- Bread\n- Tomato")
    final bulletLines = cleaned
        .split('\n')
        .map((l) => l.trim())
        .where((l) => RegExp(r'^[-*•\d\.]+\s+').hasMatch(l))
        .map((l) => l.replaceFirst(RegExp(r'^[-*•\d\.]+\s+'), '').trim())
        .where((l) => l.isNotEmpty && !l.toLowerCase().startsWith('the meal'))
        .toList();

    if (bulletLines.isNotEmpty) {
      debugPrint('[AiParsing] Fallback parsing bullet points into suggested items: $bulletLines');
      return bulletLines.map((line) {
        final gramMatch = RegExp(r'(\d+)\s*g\b', caseSensitive: false).firstMatch(line);
        final grams = gramMatch != null ? int.tryParse(gramMatch.group(1)!) ?? 100 : 100;
        final cleanName = line
            .replaceAll(RegExp(r'\(\s*\d+\s*g\s*\)', caseSensitive: false), '')
            .replaceAll(RegExp(r'\b\d+\s*g\b', caseSensitive: false), '')
            .trim();
        return AiSuggestedItem(
          name: cleanName.isNotEmpty ? cleanName : line,
          estimatedGrams: grams,
          confidence: 0.8,
        );
      }).toList();
    }

    debugPrint('[AiParsing] Failed to parse items. Raw AI response:\n$content');
    throw const AiParseException('No JSON array found in response.');
  }
}
