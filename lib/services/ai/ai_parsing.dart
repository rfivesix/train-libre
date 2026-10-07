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
  final rawCatalog = e['catalogSearchTerm'];
  final catalogSearchTerm = rawCatalog is String
      ? rawCatalog
      : (rawCatalog is List && rawCatalog.isNotEmpty ? rawCatalog.first?.toString() : null);

  return AiMealCandidateItem(
    name: (e['name'] as String?) ?? '',
    grams: grams,
    confidence: (e['confidence'] as num?)?.toDouble(),
    servedGrams: served,
    matchedBarcode: e['matchedBarcode'] as String?,
    stateHint: e['stateHint'] as String?,
    catalogSearchTerm: catalogSearchTerm,
    searchTerms: _parseSearchTerms(e['searchTerms']),
  );
}

List<AiMealCandidateItem> _extractCandidateItemsFromMap(Map<String, dynamic> map) {
  // Check common wrapper keys
  for (final key in ['items', 'meal', 'food_components', 'components', 'foods', 'ingredients', 'dish']) {
    final val = map[key];
    if (val is List && val.isNotEmpty) {
      final items = <AiMealCandidateItem>[];
      for (final el in val) {
        if (el is Map<String, dynamic>) {
          items.add(_parseCandidateItem(el));
        } else if (el is String && el.trim().isNotEmpty) {
          items.add(AiMealCandidateItem(
            name: el.trim(),
            grams: 100,
            confidence: 0.8,
          ));
        }
      }
      if (items.isNotEmpty) return items;
    }
  }

  // Fallback: check if the map itself represents a single food item
  if (map.containsKey('name')) {
    return [_parseCandidateItem(map)];
  }

  // Check any list value in the map
  for (final val in map.values) {
    if (val is List && val.isNotEmpty) {
      final items = <AiMealCandidateItem>[];
      for (final el in val) {
        if (el is Map<String, dynamic>) {
          items.add(_parseCandidateItem(el));
        } else if (el is String && el.trim().isNotEmpty) {
          items.add(AiMealCandidateItem(
            name: el.trim(),
            grams: 100,
            confidence: 0.8,
          ));
        }
      }
      if (items.isNotEmpty) return items;
    }
  }
  return const [];
}

List<AiSuggestedItem> _extractSuggestedItemsFromMap(Map<String, dynamic> map) {
  for (final key in ['items', 'meal', 'food_components', 'components', 'foods', 'ingredients', 'dish']) {
    final val = map[key];
    if (val is List && val.isNotEmpty) {
      final items = <AiSuggestedItem>[];
      for (final el in val) {
        if (el is Map<String, dynamic>) {
          items.add(AiSuggestedItem.fromJson(el));
        } else if (el is String && el.trim().isNotEmpty) {
          items.add(AiSuggestedItem(
            name: el.trim(),
            estimatedGrams: 100,
            confidence: 0.8,
          ));
        }
      }
      if (items.isNotEmpty) return items;
    }
  }

  if (map.containsKey('name')) {
    return [AiSuggestedItem.fromJson(map)];
  }

  for (final val in map.values) {
    if (val is List && val.isNotEmpty) {
      final items = <AiSuggestedItem>[];
      for (final el in val) {
        if (el is Map<String, dynamic>) {
          items.add(AiSuggestedItem.fromJson(el));
        } else if (el is String && el.trim().isNotEmpty) {
          items.add(AiSuggestedItem(
            name: el.trim(),
            estimatedGrams: 100,
            confidence: 0.8,
          ));
        }
      }
      if (items.isNotEmpty) return items;
    }
  }
  return const [];
}

extension AiParsing on AiService {
  @visibleForTesting
  AiMealCandidate parseMealCandidateForTesting(String content) =>
      _parseMealCandidateFromContentSync(content);

  @visibleForTesting
  List<AiSuggestedItem> parseItemsForTesting(String content) =>
      _parseItemsFromContentSync(content);

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

    // Sanitize non-standard JSON tokens like [<100, 200] or [0%, 5%] emitted by some on-device models
    cleaned = cleaned
        .replaceAllMapped(RegExp(r'\[\s*<\s*(\d+)'), (m) => '[${m.group(1)}')
        .replaceAllMapped(RegExp(r'(\d+)\s*%\s*([,\]])'), (m) => '${m.group(1)}${m.group(2)}');

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        final contextMap = decoded['mealContext'];
        AiMealContext? mealContext =
            contextMap != null && contextMap is Map<String, dynamic>
                ? AiMealContext.fromJson(contextMap)
                : null;

        if (mealContext == null && decoded.containsKey('dishType')) {
          final dishType = decoded['dishType']?.toString().trim();
          if (dishType != null && dishType.isNotEmpty) {
            mealContext = AiMealContext(
              dishType: dishType,
              expectedKcalRange: const [0, 9999],
              expectedMacroProfile: const {},
            );
          }
        }

        final items = _extractCandidateItemsFromMap(decoded);
        if (items.isNotEmpty) {
          return AiMealCandidate(
            context: mealContext,
            items: items,
          );
        }
      }

      if (decoded is List) {
        final items = <AiMealCandidateItem>[];
        for (final el in decoded) {
          if (el is Map<String, dynamic>) {
            items.add(_parseCandidateItem(el));
          } else if (el is String && el.trim().isNotEmpty) {
            items.add(AiMealCandidateItem(
              name: el.trim(),
              grams: 100,
              confidence: 0.8,
            ));
          }
        }
        if (items.isNotEmpty) return AiMealCandidate(items: items);
      }
    } catch (e) {
      debugPrint('[AiParsing] Direct jsonDecode failed: $e');
    }

    // Try wrapping in brackets if it looks like comma-separated JSON objects without outer array
    if (cleaned.startsWith('{') && cleaned.endsWith('}') && cleaned.contains('},{')) {
      try {
        final wrapped = '[$cleaned]';
        final decoded = jsonDecode(wrapped);
        if (decoded is List) {
          final items = decoded
              .whereType<Map<String, dynamic>>()
              .map(_parseCandidateItem)
              .toList();
          if (items.isNotEmpty) return AiMealCandidate(items: items);
        }
      } catch (e) {
        debugPrint('[AiParsing] Wrapped objects jsonDecode failed: $e');
      }
    }

    final startBracket = cleaned.indexOf('{');
    final endBracket = cleaned.lastIndexOf('}');
    if (startBracket != -1 && endBracket != -1 && endBracket > startBracket) {
      try {
        final jsonStr = cleaned.substring(startBracket, endBracket + 1);
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          final contextMap = decoded['mealContext'];
          AiMealContext? mealContext =
              contextMap != null && contextMap is Map<String, dynamic>
                  ? AiMealContext.fromJson(contextMap)
                  : null;

          if (mealContext == null && decoded.containsKey('dishType')) {
            final dishType = decoded['dishType']?.toString().trim();
            if (dishType != null && dishType.isNotEmpty) {
              mealContext = AiMealContext(
                dishType: dishType,
                expectedKcalRange: const [0, 9999],
                expectedMacroProfile: const {},
              );
            }
          }

          final items = _extractCandidateItemsFromMap(decoded);
          if (items.isNotEmpty) {
            return AiMealCandidate(
              context: mealContext,
              items: items,
            );
          }
        }
      } catch (e) {
        debugPrint('[AiParsing] Bracket extraction jsonDecode failed: $e');
      }
    }

    // Try extracting all top-level JSON objects from the text if it's a sequence of objects
    // e.g. {"mealContext": ...}, {"name": "Fladenbrot", ...} {"name": "Hähnchenbrust", ...}
    final objectMatches = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').allMatches(cleaned);
    if (objectMatches.isNotEmpty) {
      AiMealContext? extractedContext;
      final extractedItems = <AiMealCandidateItem>[];

      for (final match in objectMatches) {
        final rawObj = match.group(0);
        if (rawObj == null) continue;
        try {
          // Sanitize raw object for potential angle brackets in numbers like [<100, 200]
          final sanitized = rawObj
              .replaceAll(RegExp(r'\[\s*<\s*(\d+)'), '[\$1')
              .replaceAll(RegExp(r'(\d+)\s*%\s*([,\]])'), '\$1\$2');
          final decodedObj = jsonDecode(sanitized);
          if (decodedObj is Map<String, dynamic>) {
            if (decodedObj.containsKey('mealContext') && decodedObj['mealContext'] is Map<String, dynamic>) {
              extractedContext ??= AiMealContext.fromJson(decodedObj['mealContext'] as Map<String, dynamic>);
            } else if (decodedObj.containsKey('dishType') && !decodedObj.containsKey('name')) {
              extractedContext ??= AiMealContext(
                dishType: decodedObj['dishType']?.toString() ?? '',
                expectedKcalRange: const [0, 9999],
                expectedMacroProfile: const {},
              );
            }

            if (decodedObj.containsKey('items') ||
                decodedObj.containsKey('meal') ||
                decodedObj.containsKey('food_components')) {
              extractedItems.addAll(_extractCandidateItemsFromMap(decodedObj));
            } else if (decodedObj.containsKey('name')) {
              extractedItems.add(_parseCandidateItem(decodedObj));
            }
          }
        } catch (_) {}
      }

      if (extractedItems.isNotEmpty) {
        return AiMealCandidate(
          context: extractedContext,
          items: extractedItems,
        );
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
        final items = <AiSuggestedItem>[];
        for (final el in decoded) {
          if (el is Map<String, dynamic>) {
            items.add(AiSuggestedItem.fromJson(el));
          } else if (el is String && el.trim().isNotEmpty) {
            items.add(AiSuggestedItem(name: el.trim(), estimatedGrams: 100, confidence: 0.8));
          }
        }
        if (items.isNotEmpty) return items;
      } else if (decoded is Map<String, dynamic>) {
        final items = _extractSuggestedItemsFromMap(decoded);
        if (items.isNotEmpty) return items;
      }
    } catch (e) {
      debugPrint('[AiParsing] Direct items jsonDecode failed: $e');
    }

    // Try wrapping in brackets if it looks like comma-separated JSON objects without outer array
    // e.g. {"name":"Banh Canh..."},{"name":"Tomato"...}
    if (cleaned.startsWith('{') && cleaned.contains('},{')) {
      try {
        var toWrap = cleaned;
        if (toWrap.endsWith(']}')) {
          toWrap = toWrap.substring(0, toWrap.length - 2);
        } else if (toWrap.endsWith('}')) {
          // keep
        }
        final wrapped = '[$toWrap]';
        final decoded = jsonDecode(wrapped);
        if (decoded is List) {
          final items = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => AiSuggestedItem.fromJson(e))
              .toList();
          if (items.isNotEmpty) return items;
        }
      } catch (e) {
        debugPrint('[AiParsing] Wrapped objects suggested items jsonDecode failed: $e');
      }
    }

    // Second attempt: search for array delimiters [ ... ]
    final startIdx = cleaned.indexOf('[');
    final endIdx = cleaned.lastIndexOf(']');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      try {
        final jsonStr = cleaned.substring(startIdx, endIdx + 1);
        final List<dynamic> itemsRaw = jsonDecode(jsonStr) as List<dynamic>;
        final items = <AiSuggestedItem>[];
        for (final el in itemsRaw) {
          if (el is Map<String, dynamic>) {
            items.add(AiSuggestedItem.fromJson(el));
          } else if (el is String && el.trim().isNotEmpty) {
            items.add(AiSuggestedItem(name: el.trim(), estimatedGrams: 100, confidence: 0.8));
          }
        }
        if (items.isNotEmpty) return items;
      } catch (e) {
        debugPrint('[AiParsing] Items array extraction failed: $e');
      }
    }

    // Third attempt: search for object delimiters { ... }
    final startObj = cleaned.indexOf('{');
    final endObj = cleaned.lastIndexOf('}');
    if (startObj != -1 && endObj != -1 && endObj > startObj) {
      try {
        final jsonStr = cleaned.substring(startObj, endObj + 1);
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          final items = _extractSuggestedItemsFromMap(decoded);
          if (items.isNotEmpty) return items;
        }
      } catch (e) {
        debugPrint('[AiParsing] Items object extraction failed: $e');
      }
    }

    // Fourth attempt: Extract sequence of JSON objects from the text
    // e.g. {"mealContext": ...}, {"name": "Fladenbrot", ...} {"name": "Hähnchenbrust", ...}
    final objMatches = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').allMatches(cleaned);
    if (objMatches.isNotEmpty) {
      final items = <AiSuggestedItem>[];
      for (final match in objMatches) {
        final rawObj = match.group(0);
        if (rawObj == null) continue;
        try {
          final decodedObj = jsonDecode(rawObj);
          if (decodedObj is Map<String, dynamic>) {
            if (decodedObj.containsKey('items') ||
                decodedObj.containsKey('meal') ||
                decodedObj.containsKey('food_components')) {
              items.addAll(_extractSuggestedItemsFromMap(decodedObj));
            } else if (decodedObj.containsKey('name')) {
              items.add(AiSuggestedItem.fromJson(decodedObj));
            }
          }
        } catch (_) {}
      }
      if (items.isNotEmpty) return items;
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
