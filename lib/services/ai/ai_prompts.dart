part of '../ai_service.dart';

abstract class _AiPrompts {
  /// Builds the system prompt, optionally localised to [appLanguage] and [catalogLanguage].
  static String buildSystemPrompt({
    String? languageCode,
    String? appLanguage,
    String? catalogLanguage,
    DepthScaleFacts? depthFacts,
  }) {
    final effectiveAppLang = appLanguage ?? languageCode;
    final effectiveCatalogLang = catalogLanguage;

    final langRuleBuffer = StringBuffer();
    if (effectiveAppLang != null && effectiveAppLang.isNotEmpty) {
      langRuleBuffer.write(
        '\n10. IMPORTANT: All primary food "name" values MUST be in the "$effectiveAppLang" language '
        '(e.g. use "Apfel" instead of "Apple" when app language is "de").',
      );
    }
    if (effectiveCatalogLang != null &&
        effectiveCatalogLang.isNotEmpty &&
        effectiveAppLang != null &&
        effectiveCatalogLang != effectiveAppLang) {
      langRuleBuffer.write(
        '\n11. DUAL LANGUAGE SEARCH: The active regional food catalog uses "$effectiveCatalogLang". '
        'If an item represents a packaged product, brand, or regional dish, also provide a "catalogSearchTerm" '
        'field in "$effectiveCatalogLang" (e.g. name: "Schinkenbaguette", catalogSearchTerm: "Baguette au jambon").',
      );
    }

    final depthBlockBuffer = StringBuffer();
    if (depthFacts != null && depthFacts.isValid) {
      depthBlockBuffer.write('''

LIDAR SCALE MEASUREMENT (measured, not estimated — trust these numbers over your visual impression):
- Distance from camera to the food: ${depthFacts.subjectDistanceCm.toStringAsFixed(0)} cm
- The visible frame covers ${depthFacts.frameWidthCm.toStringAsFixed(0)} cm x ${depthFacts.frameHeightCm.toStringAsFixed(0)} cm at that distance
- Nearest surface: ${depthFacts.nearCm.toStringAsFixed(0)} cm, farthest: ${depthFacts.farCm.toStringAsFixed(0)} cm

Use this to calibrate the absolute size of everything in the image. Do NOT rely on assumed plate or cutlery sizes when this measurement is present — derive plate diameter and portion dimensions from the frame size above.
''');
    }

    final langRule = langRuleBuffer.toString();
    final depthBlock = depthBlockBuffer.toString();

    return '''
You are a nutrition analysis assistant. Analyze the provided meal image(s) or description.$depthBlock

CRITICAL RULES:
1. Establish a holistic meal context anchor *before* decomposing. Identify the dish and its overall cooking method, expected calories, and macro percentage ranges based on culinary knowledge.
2. Break down EVERY meal into its individual, atomic, loggable food components.
   For example, "Cheeseburger with fries" must become: burger bun, beef patty, cheese slice, lettuce, tomato, ketchup, french fries — each as a separate item with its own estimated weight.
3. Do NOT return composite meal names. Always decompose into individual ingredients.
4. Estimate weights in grams as accurately as possible based on visual cues or typical serving sizes.
5. Set confidence between 0.0 and 1.0 based on how certain you are about each item and its quantity.
6. Provide a "stateHint" string for each item (e.g. "cooked", "raw", "fried", "baked", "boiled", "grilled", etc.) to help the matching engine select the correct database variant.
7. CONSOLIDATE duplicate items: if the user mentions or you detect multiple quantities of the same food (e.g. "4 eggs"), return ONE single entry with the total combined weight. Never return duplicate rows for the same food item.
8. Do NOT estimate, guess, or return any nutritional data (calories, protein, fat, carbs, etc.) inside the items array. The items array must ONLY contain identification and estimated weight. The holistic "mealContext" anchor *does* contain expected macronutrient ranges for the overall meal.
9. Use SIMPLE, SHORT base food names only. For example, use "Banane" not "Reife Banane", "Ei" not "Gekochtes Ei", "Apfel" not "Grüner Apfel". Keep names as generic and simple as possible to maximize database matching.$langRule

Respond ONLY with a valid JSON object. No markdown, no explanation, no extra text.
The JSON object must have exactly these two fields:
1. "mealContext": An object containing:
   - "dishType": string (the name of the dish/meal)
   - "expectedKcalRange": array of two integers [low, high]
   - "expectedMacroProfile": an object with keys "proteinPercent", "carbsPercent", "fatPercent", each being an array of two integers [low, high]
   - "cookingMethod": string (overall cooking method)
   - "contextNotes": string (contextual culinary details)
2. "items": An array where each element has:
   - "name": string (individual food component name in user UI language)
   - "catalogSearchTerm": string or null (optional search keyword in catalog language if different from UI language)
   - "estimatedGrams": integer (estimated weight in grams)
   - "confidence": number (0.0 to 1.0)
   - "stateHint": string or null (e.g. "cooked", "raw", "boiled")

Example response:
{
  "mealContext": {
    "dishType": "Omelette with Butter",
    "expectedKcalRange": [250, 350],
    "expectedMacroProfile": {
      "proteinPercent": [20, 30],
      "carbsPercent": [1, 5],
      "fatPercent": [70, 80]
    },
    "cookingMethod": "pan-fried in butter",
    "contextNotes": "Made with 3 eggs and 10g of butter"
  },
  "items": [
    {"name": "Egg", "catalogSearchTerm": "Oeuf", "estimatedGrams": 150, "confidence": 0.9, "stateHint": "cooked"},
    {"name": "Butter", "catalogSearchTerm": "Beurre", "estimatedGrams": 10, "confidence": 0.8, "stateHint": "raw"}
  ]
}
''';
  }

  static String buildRepairPrompt({
    String? languageCode,
    String? appLanguage,
    String? catalogLanguage,
    AiMealContext? mealContext,
    DepthScaleFacts? depthFacts,
  }) {
    final effectiveLang = appLanguage ?? languageCode;
    final langRule = (effectiveLang != null && effectiveLang.isNotEmpty)
        ? '\n- Return food names in the "$effectiveLang" language.'
        : '';

    final anchorBlock = mealContext != null
        ? '\n\nMEAL CONTEXT ANCHOR:\n'
            '- Dish: ${mealContext.dishType}\n'
            '- Expected total kcal: ${mealContext.expectedKcalRange[0]}-${mealContext.expectedKcalRange[1]}\n'
            '- Expected macro profile: P${mealContext.expectedMacroProfile["proteinPercent"]}% '
            'C${mealContext.expectedMacroProfile["carbsPercent"]}% '
            'F${mealContext.expectedMacroProfile["fatPercent"]}%\n'
            '- Cooking: ${mealContext.cookingMethod ?? "unknown"}\n'
            'Adjust gram amounts so the total aligns with this anchor.'
        : '';

    final depthBlock = (depthFacts != null && depthFacts.isValid)
        ? '\n\nLIDAR SCALE MEASUREMENT: ${depthFacts.subjectDistanceCm.toStringAsFixed(0)} cm distance, visible frame ${depthFacts.frameWidthCm.toStringAsFixed(0)}x${depthFacts.frameHeightCm.toStringAsFixed(0)} cm. Trust this measurement over assumed portion sizes.'
        : '';

    return '''
You are repairing an AI meal candidate after deterministic local validation.

Rules:
- When CANDIDATES are listed for an item, you MUST pick one of the provided exact names. Do NOT invent new names.
- If no candidates are listed, use simple, generic, local-database-matchable food names.
- Adjust estimatedGrams to bring the total meal nutrition closer to the meal context anchor.
- Correct unrealistic quantities.
- Do not invent or return nutrition values.
- Respect strict target macros when provided; local code will verify kcal/protein/carbs/fat again.
- Use low creativity and keep the output deterministic.$langRule$anchorBlock$depthBlock

Return ONLY a valid JSON array:
[{"name":"Food name","estimatedGrams":100,"confidence":0.8}]
No markdown, no explanations, no extra text.''';
  }
}
