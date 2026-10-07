part of '../ai_service.dart';

abstract class _AiPrompts {
  static const itemSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'name': {'type': 'string'},
      'catalogSearchTerm': {
        'type': ['string', 'null']
      },
      'servedGrams': {'type': 'integer'},
      'estimatedGrams': {'type': 'integer'},
      'confidence': {'type': 'number'},
      'stateHint': {
        'type': ['string', 'null']
      },
      'searchTerms': {
        'type': 'array',
        'items': {'type': 'string'}
      },
      'matchedBarcode': {
        'type': ['string', 'null']
      },
    },
    'required': [
      'name',
      'catalogSearchTerm',
      'servedGrams',
      'estimatedGrams',
      'confidence',
      'stateHint',
      'searchTerms',
      'matchedBarcode',
    ],
  };

  static const mealSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'mealContext': {
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          'dishType': {'type': 'string'},
          'expectedKcalRange': {
            'type': 'array',
            'items': {'type': 'integer'}
          },
          'expectedMacroProfile': {
            'type': 'object',
            'additionalProperties': false,
            'properties': {
              'proteinPercent': {
                'type': 'array',
                'items': {'type': 'integer'}
              },
              'carbsPercent': {
                'type': 'array',
                'items': {'type': 'integer'}
              },
              'fatPercent': {
                'type': 'array',
                'items': {'type': 'integer'}
              },
            },
            'required': ['proteinPercent', 'carbsPercent', 'fatPercent'],
          },
          'cookingMethod': {'type': 'string'},
          'contextNotes': {'type': 'string'},
        },
        'required': [
          'dishType',
          'expectedKcalRange',
          'expectedMacroProfile',
          'cookingMethod',
          'contextNotes',
        ],
      },
      'items': {'type': 'array', 'items': itemSchema},
    },
    'required': ['mealContext', 'items'],
  };

  /// Builds the system prompt, optionally localised to [appLanguage] and [catalogLanguage].
  static String buildSystemPrompt({
    String? languageCode,
    String? appLanguage,
    String? catalogLanguage,
    DepthScaleFacts? depthFacts,
    String? depthMapLegend,
    bool structuredOutput = false,
  }) {
    final effectiveAppLang = appLanguage ?? languageCode ?? 'de';
    final effectiveCatalogLang = catalogLanguage;

    final langRuleBuffer = StringBuffer();
    if (effectiveAppLang.isNotEmpty) {
      langRuleBuffer.write(
        '\n9. IMPORTANT: Both the overall meal name ("dishType") and all individual food "name" values MUST be in the "$effectiveAppLang" language '
        '(e.g. use standard, common food terms in "$effectiveAppLang" like "Reis", "Hähnchenbrust", "Fladenbrot", "Apfel", "Olivenöl").',
      );
    }
    if (effectiveCatalogLang != null &&
        effectiveCatalogLang.isNotEmpty &&
        effectiveCatalogLang != effectiveAppLang) {
      langRuleBuffer.write(
        '\n10. DUAL LANGUAGE SEARCH: The active regional food catalog uses "$effectiveCatalogLang". '
        'If an item represents a packaged product, brand, or regional dish, also provide a "catalogSearchTerm" '
        'field in "$effectiveCatalogLang".',
      );
    }

    final depthBlockBuffer = StringBuffer();
    if (depthFacts != null && depthFacts.isValid) {
      depthBlockBuffer.write('''

LIDAR SCALE MEASUREMENT (measured, not estimated — trust these numbers over visual impression):
- Distance: ${depthFacts.subjectDistanceCm.toStringAsFixed(0)} cm. Visible frame: ${depthFacts.frameWidthCm.toStringAsFixed(0)} x ${depthFacts.frameHeightCm.toStringAsFixed(0)} cm.
- Nearest surface: ${depthFacts.nearCm.toStringAsFixed(0)} cm, farthest: ${depthFacts.farCm.toStringAsFixed(0)} cm.
Use this to calibrate the absolute portion size and plate dimensions.''');
    }

    if (depthMapLegend != null && depthMapLegend.trim().isNotEmpty) {
      depthBlockBuffer.write('''

DEPTH MAP IMAGE: The attached relief image indicates physical food height/volume. $depthMapLegend''');
    }

    final langRule = langRuleBuffer.toString();
    final depthBlock = depthBlockBuffer.toString();

    final outputRule = structuredOutput
        ? 'Output the mealContext and items structure matching the required schema.'
        : '''Respond ONLY with this JSON structure:
{
  "mealContext": {
    "dishType": "Meal title in $effectiveAppLang",
    "expectedKcalRange": [500, 800],
    "expectedMacroProfile": {
      "proteinPercent": [15, 25],
      "carbsPercent": [45, 55],
      "fatPercent": [25, 35]
    },
    "cookingMethod": "baked",
    "contextNotes": "brief note"
  },
  "items": [
    {
      "name": "Food component in $effectiveAppLang",
      "catalogSearchTerm": null,
      "servedGrams": 150,
      "estimatedGrams": 150,
      "confidence": 0.9,
      "stateHint": "cooked",
      "searchTerms": ["food component", "alternative search term"]
    }
  ]
}''';

    return '''
You are an expert nutrition AI. Analyze the meal image(s) or description and break it down into loggable ingredients.$depthBlock

CRITICAL RULES:
1. Decompose EVERY meal into its atomic, single ingredient components (e.g. "Reis", "Hähnchenfleisch", "Tomaten", "Zwiebeln", "Olivenöl", "Käse").
2. Do NOT return composite meal names as ingredients (e.g. NEVER return "Sandwich mit Fleisch", "Döner", "Pizza" inside items). Always separate bread, meat, vegetables, cheese, sauce.
3. Use SIMPLE, SHORT base food names only (e.g. "Reis" not "Gebratener Basmatireis", "Ei" not "Gekochtes Hühnerei", "Tomaten" not "Reife Tomatenscheiben"). Keep names generic so they match local nutrition databases reliably.
4. Estimate weights in grams realistically. Calibrate to the whole serving (a standard full main meal typically weighs 350–700g total).
5. The database commonly stores nutrition for RAW or UNPREPARED food. Provide both "servedGrams" (visible cooked/eaten weight) and "estimatedGrams" (raw equivalent weight used for database lookup). For raw or non-swelling foods, both numbers are identical.
6. Provide "stateHint" ("cooked", "raw", "fried", "baked", "boiled", "grilled") to resolve the correct database preparation state.
7. Provide 1-3 short "searchTerms" for each item to maximize database query recall.
8. Consolidate duplicate items into a single entry with total combined weight.$langRule

CRITICAL: Return ONLY valid JSON starting with "{" and ending with "}". No commentary or markdown outside the JSON.

$outputRule''';
  }

  /// Prompt for turning a raw dictation transcript into bullets.
  ///
  /// The interesting failure of speech recognition here is not filler words —
  /// a local rule can strip those. It is misheard food names: "Sriracha" comes
  /// back as "Sir Ratscher", and no rule engine can know that. Correcting them
  /// needs a model that knows what food is called.
  static String buildVoiceTidyPrompt() {
    return '''
You clean up a spoken meal description that has been through speech recognition.

Return ONLY JSON in this exact shape:
{
  "bullets": [
    {"text": "<food with its amount>", "notes": ["<what the user said about this food>"]}
  ],
  "context": "<anything about the meal as a whole, or omit>"
}

Rules:
- One bullet per food. Put the amount in "text" when the user gave one
  ("500 g Hähnchen"). When they gave none, just name the food.
- Everything the user said ABOUT a food goes into that food's "notes", in their
  own words: preparation, weighing basis, brand, "not much", "with the skin".
  Never fold a qualifier into "text" and never drop one.
- Speech recognition mangles food names. Correct obvious mishearings to the food
  that was clearly meant ("Sir Ratscher" -> "Sriracha"). Fix casing and joined
  or split compound words. If you cannot tell what was meant, keep it verbatim
  rather than guessing at a different food.
- Drop filler words and false starts. Keep everything else.
- Invent nothing: no foods, no amounts, no preparation the user did not say.
- Answer in the language the transcript is in.
- No commentary, no code fences, JSON only.''';
  }

  static String buildRepairPrompt({
    String? languageCode,
    String? appLanguage,
    String? catalogLanguage,
    AiMealContext? mealContext,
    DepthScaleFacts? depthFacts,
  }) {
    final effectiveLang = appLanguage ?? languageCode ?? 'de';

    final anchorBlock = mealContext != null
        ? '\n\nMEAL CONTEXT ANCHOR:\n'
            '- Dish: ${mealContext.dishType}\n'
            '- Target calories: ${mealContext.expectedKcalRange[0]}-${mealContext.expectedKcalRange[1]} kcal\n'
            '- Target macros: P${mealContext.expectedMacroProfile["proteinPercent"]}% '
            'C${mealContext.expectedMacroProfile["carbsPercent"]}% '
            'F${mealContext.expectedMacroProfile["fatPercent"]}%\n'
            '- Cooking: ${mealContext.cookingMethod ?? "unknown"}\n'
            'Adjust portion grams so the total calories match this target.'
        : '';

    final depthBlock = (depthFacts != null && depthFacts.isValid)
        ? '\n\nLIDAR SCALE: distance ${depthFacts.subjectDistanceCm.toStringAsFixed(0)} cm, frame ${depthFacts.frameWidthCm.toStringAsFixed(0)}x${depthFacts.frameHeightCm.toStringAsFixed(0)} cm.'
        : '';

    return '''
You are repairing an AI meal candidate after deterministic local database validation.

RULES:
1. When CANDIDATES are listed for an item, pick the EXACT name string from the candidate list and include its `matchedBarcode`.
2. If no candidates are listed, use simple, generic base food names in "$effectiveLang" that exist in standard nutrition tables.
3. Adjust portion weights (`servedGrams` and `estimatedGrams`) so the overall meal calories align with the target meal context.
4. Keep names simple and in the "$effectiveLang" language.
5. Do NOT output calorie numbers in the JSON array.$anchorBlock$depthBlock

CRITICAL: Return ONLY a valid JSON array starting with "[" and ending with "]". Do NOT return comma-separated objects without outer array brackets.

Return ONLY this format:
[
  {
    "name": "Food name in $effectiveLang",
    "servedGrams": 150,
    "estimatedGrams": 150,
    "confidence": 0.9,
    "stateHint": "cooked",
    "searchTerms": ["food name"],
    "matchedBarcode": null
  }
]
No markdown, no explanations, no extra text.''';
  }
}
