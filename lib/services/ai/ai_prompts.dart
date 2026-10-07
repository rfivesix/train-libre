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

  /// Builds a streamlined, highly effective system prompt for all AI providers.
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

    final depthBlockBuffer = StringBuffer();
    if (depthFacts != null && depthFacts.isValid) {
      depthBlockBuffer.write('''

LIDAR SCALE MEASUREMENT:
- Distance: ${depthFacts.subjectDistanceCm.toStringAsFixed(0)} cm. Visible frame: ${depthFacts.frameWidthCm.toStringAsFixed(0)} x ${depthFacts.frameHeightCm.toStringAsFixed(0)} cm.
Use this to judge real object and plate size.''');
    }

    if (depthMapLegend != null && depthMapLegend.trim().isNotEmpty) {
      depthBlockBuffer.write('''

DEPTH MAP: The attached relief image indicates physical food height/volume. $depthMapLegend''');
    }

    final catalogNote = (effectiveCatalogLang != null &&
            effectiveCatalogLang.isNotEmpty &&
            effectiveCatalogLang != effectiveAppLang)
        ? '\n- For regional or packaged foods, provide "catalogSearchTerm" in "$effectiveCatalogLang".'
        : '';

    final outputRule = structuredOutput
        ? 'Output the mealContext and items structure matching the required schema.'
        : '''Respond ONLY with this JSON structure:
{
  "dishType": "<Meal name in $effectiveAppLang, e.g. Döner Kebab>",
  "items": [
    {
      "name": "<Food component in $effectiveAppLang, e.g. Fladenbrot>",
      "estimatedGrams": <portion_grams_e.g_150>
    },
    {
      "name": "<Food component in $effectiveAppLang, e.g. Dönerfleisch>",
      "estimatedGrams": <portion_grams_e.g_180>
    }
  ]
}''';

    return '''
You are an expert nutrition AI. Identify the complete dish ("dishType") and all its individual food components ("items") with portion weights in grams.${depthBlockBuffer.toString()}

CRITICAL: Return ONLY valid JSON starting with "{" and ending with "}".
Never return a simple list of words. Each item MUST have "name" and "estimatedGrams".
Identify all components visible in the food (bread, meat, sauces, salad/vegetables) with realistic portions calibrated to a full serving.
Language for dishType and names: $effectiveAppLang.$catalogNote

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
            'Adjust portion grams so the total calories match this target.'
        : '';

    final depthBlock = (depthFacts != null && depthFacts.isValid)
        ? '\n\nLIDAR SCALE: distance ${depthFacts.subjectDistanceCm.toStringAsFixed(0)} cm, frame ${depthFacts.frameWidthCm.toStringAsFixed(0)}x${depthFacts.frameHeightCm.toStringAsFixed(0)} cm.'
        : '';

    return '''
You are adjusting the meal items after automated validation.

RULES:
1. When CANDIDATES are listed for an item, pick the exact matching name and include its `matchedBarcode`.
2. Adjust the portion weights (`estimatedGrams` and `servedGrams`) so the overall meal calories align with the target meal context.
3. Keep names simple and in the "$effectiveLang" language.
4. Do NOT output calorie numbers in the JSON array.$anchorBlock$depthBlock

CRITICAL: Return ONLY a valid JSON array starting with "[" and ending with "]". Do NOT return comma-separated objects without the outer array brackets.

Return ONLY this format:
[
  {
    "name": "<Food name in $effectiveLang>",
    "servedGrams": <grams>,
    "estimatedGrams": <grams>,
    "confidence": <0.0_to_1.0>,
    "stateHint": "<cooked|raw|fried|etc>",
    "searchTerms": ["<term1>"],
    "matchedBarcode": "<candidate_id_or_null>"
  }
]
No markdown, no explanations, no extra text.''';
  }
}
