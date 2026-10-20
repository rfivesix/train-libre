part of '../ai_service.dart';

abstract class _AiPrompts {
  static const _blsNamingGuidance = '''

BLS BASE-FOOD CATALOG NAMING:
- The BLS base-food index uses concise German source names, even when the app or packaged-food catalog uses another language. For generic ingredients, include a German BLS search term in `searchTerms` when the everyday food name differs from the catalog wording.
- Convert everyday names to the catalog's formal food-class terminology before searching. Names commonly identify the food class first, then specify composition, variety, and preparation state. For pasta/noodles, include `Teigwaren` as a search term.
- In the initial analysis use `matchedBarcode` only when the image or user input clearly identifies a specific packaged product or barcode. For ordinary visible ingredients leave it null. During repair, use only IDs supplied for that item, including BLS IDs; an ID does not establish packaged-product evidence.
- Treat the base-food catalog as the default source for ingredients. Set `catalogSearchTerm` only when a specific branded or packaged product is visibly identified and Open Food Facts is needed to find that product. Do not request Open Food Facts for generic ingredients merely because its product name is a closer text match.
- Set `packagedProductEvidence` to a short quote or description of the brand, product label or barcode explicitly visible in the original image or stated by the user. Otherwise return null. A catalog candidate, translation, search term or familiar product name is NOT evidence of packaging. Never invent this evidence during repair.
- Keep the food identity and preparation state accurate. Do not make a generic catalog entry appear to be a specific variety or cooking method that the source does not identify.''';

  static const itemSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'name': {'type': 'string'},
      'catalogSearchTerm': {
        'type': ['string', 'null']
      },
      'packagedProductEvidence': {
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
      'packagedProductEvidence',
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
        'For a specifically identified packaged or branded product, provide a "catalogSearchTerm" '
        'in "$effectiveCatalogLang". For generic ingredients and regional dishes, use the base-food catalog '
        'and put any localized food-name alternatives in "searchTerms" instead.',
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
    final catalogNamingGuidance = _blsNamingGuidance;

    final outputRule = structuredOutput
        ? 'Output the mealContext and items structure matching the required schema.'
        : '''Respond ONLY with this JSON structure:
{
  "dishType": "Meal title in $effectiveAppLang",
  "expectedKcalRange": [500, 800],
  "cookingMethod": "baked",
  "items": [
    {
      "name": "Food component in $effectiveAppLang",
      "catalogSearchTerm": null,
      "packagedProductEvidence": null,
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
7. Provide 1-2 specific "searchTerms" for each item using only synonyms of the ingredient itself. Include a canonical BLS term when its formal catalog wording differs from everyday wording. NEVER use broad category words like "fruit", "vegetable", "dairy", "starch", "topping", "snack" as search terms.
8. Consolidate duplicate items into a single entry with total combined weight.$langRule

$catalogNamingGuidance

CRITICAL: Return ONLY valid JSON starting with "{" and ending with "}".
Separate all items in the "items" array with commas (e.g. `[{"name": "..."}, {"name": "..."}]`).
No commentary or markdown outside the JSON.

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
    final catalogNamingGuidance = _blsNamingGuidance;

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
1. When CANDIDATES are listed for an item, pick the EXACT name and [id] from that item's list. Return the [id] as `matchedBarcode`, including for base foods. This selects a supplied catalog entry; it is not evidence of packaging. For generic ingredients prefer a suitable [base] candidate. Use [off] only when no suitable base candidate exists or original packaged-product evidence identifies that product.
2. If no candidates are listed, use simple, generic base food names in "$effectiveLang" that exist in standard nutrition tables.
3. Adjust portion weights (`servedGrams` and `estimatedGrams`) so the overall meal calories align with the target meal context.
4. Keep names simple and in the "$effectiveLang" language.
5. For generic ingredient matching, include the German BLS food-class term in `searchTerms` when the everyday term differs from the source catalog wording. Preserve the correct composition and preparation state.
6. Do NOT output calorie numbers in the JSON array.$anchorBlock$depthBlock
7. Return exactly the requested items with their original `itemIndex` values. Do not add, reorder, or omit items. For catalog-locked items change only quantities; preserve identity, preparation state and catalog selection.

$catalogNamingGuidance

CRITICAL: Return ONLY a valid JSON array starting with "[" and ending with "]". Do NOT return comma-separated objects without outer array brackets.

Return ONLY this format:
[
  {
    "itemIndex": 0,
    "name": "Food name in $effectiveLang",
    "servedGrams": 150,
    "estimatedGrams": 150,
    "confidence": 0.9,
    "stateHint": "cooked",
    "searchTerms": ["food name"],
    "catalogSearchTerm": null,
    "matchedBarcode": null
  }
]
No markdown, no explanations, no extra text.''';
  }
}
