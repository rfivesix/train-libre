# BYOK AI Meal Capture & Deterministic Validation Engine

Train Libre translates food descriptions, dictated speech or meal photos into precise, loggable items. The language model is the only part that leaves the device, and only to the provider the user configured themselves: the feature operates on a **Bring Your Own Key (BYOK)** model, and every model output is verified on-device by a deterministic validation pipeline before it can be saved. All nutritional numbers come from the local database, never from the model.

This document describes the analysis and validation engine. The surrounding capture flow — the unified camera, barcode detection, dictation, meal grouping and photo storage — is described in [Meal Capture Pipeline](meal_capture_pipeline.md).

---

## 1. Bring Your Own Key (BYOK) Security Architecture

Train Libre does not deploy intermediate servers to handle AI requests. All calls are dispatched directly from the user's mobile device to the selected AI provider.

### Encrypted Key Storage
User-configured API keys are stored directly inside native system secure vaults (iOS Keychain and Android Keystore) via `FlutterSecureStorage`, using device-only accessibility so they are never carried into an iCloud Keychain backup. The key for each provider is stored under `ai_api_key_<provider>`:

*   `ai_api_key_openai`: Secure key for OpenAI.
*   `ai_api_key_gemini`: Secure key for Google Gemini.
*   `ai_api_key_anthropic`: Secure key for Anthropic Claude.
*   `ai_api_key_mistral`: Secure key for Mistral.
*   `ai_api_key_xai`: Secure key for xAI Grok.
*   `ai_api_key_ollama`: Optional — Ollama normally needs no key.
*   `ai_api_key_custom`: Optional key for any OpenAI-compatible endpoint.

The active provider (`ai_selected_provider`) and the selected model (`ai_selected_model_<provider>`) are saved in the same secure store, isolating all credentials from external developers.

### Self-Hosted and Custom Endpoints
Two of the seven providers do not imply a third party at all:

*   **Ollama**: points at a local or home-network Ollama server; the meal photo never leaves the user's own machines.
*   **Custom OpenAI Compatible**: any endpoint the user enters under `ai_custom_base_url`, with an optional key and model name.

Both support vision, so the full photo pipeline works without any commercial provider involved. The request timeout is user-configurable (`ai_timeout_seconds`).

---

## 2. System Prompt & LLM Boundaries

To maintain data integrity and prevent AI hallucination of nutritional values, the system prompt strictly restricts the AI's responsibilities:

1.  **Macro/Calorie Ban**: The AI is strictly prohibited from estimating, guessing, or returning any nutritional numbers (calories, protein, carbs, fat). Nutritional calculations are resolved deterministically by Train Libre using its local database.
2.  **Decomposition Rule**: The AI must break down every composite meal into its basic, atomic components. For example, "Spaghetti Bolognese" must be decomposed into: *spaghetti, beef mince, tomatoes, onions, garlic, olive oil, parmesan cheese*.
3.  **Short Base Names**: Ingredient names must be returned in their simplest, generic forms (e.g., "Apfel" instead of "Grüner Apfel", "Ei" instead of "Großes gekochtes Ei") to maximize local database match rates.
4.  **Consolidation**: Duplicate items must be consolidated before returning (e.g., if the user describes eating 3 eggs, the AI must return a single entry for "Egg" with a combined weight).
5.  **Holistic Context Anchor (`mealContext`)**: The system requests and structures a `mealContext` block, establishing a culinary baseline for validation:
    *   `dishType`: Name of the identified dish.
    *   `expectedKcalRange`: Estimated total calorie boundaries `[low, high]`.
    *   `expectedMacroProfile`: Expected macronutrient percentage ranges (`proteinPercent`, `carbsPercent`, `fatPercent`), each as `[low, high]`.
    *   `cookingMethod`: Overall preparation method of the dish.
    *   `contextNotes`: Free-text culinary details.
6.  **Dual-Language Catalog Search**: The app language and the installed food catalog's language are not always the same (a German UI on a French Open Food Facts catalog). When they differ, each item may additionally carry a `catalogSearchTerm` in the catalog language, so the local matcher can search the catalog in its own language while the user still reads the item in theirs.
7.  **Output Constancy**: The output format is restricted to a structured JSON object with exactly two fields:
    *   `mealContext`: The holistic culinary anchors described above.
    *   `items`: A list of food components, each with `name`, optional `catalogSearchTerm`, `estimatedGrams`, `confidence` and `stateHint`.

### Optional Prompt Blocks
Two blocks are prepended to the system prompt only when the corresponding data exists:

*   **LiDAR scale measurement**: measured distance and visible frame size in centimetres, marked explicitly as measured rather than estimated. See [Depth Scale Hint](depth_scale_hint.md).
*   **Depth map legend**: an explanation of the false-colour depth image attached as the last picture, again only on capable devices with the setting enabled.

### Voice Transcript Tidy Pass
Dictated meal descriptions run through a separate, small prompt (`buildVoiceTidyPrompt`) before analysis. It only restructures what was said — one bullet per food, qualifiers preserved as notes, obvious speech-recognition mishearings of food names corrected — and is explicitly forbidden from inventing foods, amounts or preparation. Nutrition is never touched here; the tidied text then enters the normal text analysis path. See [Meal Capture Pipeline](meal_capture_pipeline.md).

---

## 3. Deterministic Validation Engine

Once the AI returns its JSON list, the raw suggestions are processed by the local `AiMealValidationEngine`. This engine applies a series of rigid checks:

### Merge Heuristics & Normalization
Before evaluating database matches, the engine normalizes all text tokens and checks for duplicates. If duplicate ingredients are detected, they are automatically merged: the weights are summed, and the maximum confidence is retained.

### Database Matching & Quality Classification
The engine matches ingredients against the local SQLite database using fuzzy string matching and barcodes:
*   **Exact Match (Score ≥ 0.95)**: Perfect textual alignment or matching barcode.
*   **Strong Match (Score ≥ 0.78)**: Excellent alignment (e.g., token overlaps).
*   **Partial Match (Score ≥ 0.55)**: Moderate overlap (triggers an information warning).
*   **Weak Match (Score < 0.55)**: Lower overlap or questionable semantic alignment.
*   **Unmatched**: Results in an `unmatched_item` error for that item. Triggered only when no database candidates are found at all; it is not bound to a specific score threshold.

Match quality itself is also reported: `weak_db_match` and `partial_db_match` raise a warning and an info issue respectively, and `ambiguous_db_match` warns when the two best candidates are within 0.08 of each other, i.e. when the engine cannot meaningfully tell them apart.

### Item-Level Validation Rules
The engine raises warnings or errors if a suggested portion violates physiological plausibility:
*   **Grams ≤ 0**: Triggers a critical `invalid_quantity` error.
*   **Grams > 3000g**: Triggers a critical `extreme_quantity` error.
*   **Grams ≤ 5g**: Triggers a `tiny_quantity` warning.
*   **Grams > 1200g**: Triggers a `large_quantity` warning.
*   **Confidence < 0.5**: Triggers a `low_ai_confidence` warning.

Once an item is matched, the matched database entry is checked as well:
*   `zero_nutrition_match`: the matched entry carries no usable nutrition data.
*   `implausible_food_density`: the matched entry exceeds 950 kcal per 100 g.
*   `macro_energy_mismatch`: the entry's macros imply more than 180 kcal above its stated calories.
*   `implausible_item_nutrition`: this portion alone exceeds 2500 kcal, 250 g protein, 500 g carbs or 220 g fat.

### Meal-Level Validation Rules
Beyond the individual items, the assembled meal is checked as a whole:
*   `empty_meal` (error): the AI returned no items.
*   `all_items_unmatched` (error): not a single item could be matched to the local database.
*   `partial_unmatched_items` (warning): some items remain unmatched and cannot be saved until resolved.
*   `zero_total_kcal` (warning): matched items sum to 0 kcal.
*   `capture_total_kcal_extreme` (error) / `capture_total_kcal_high` (warning): above 5000 / 3500 kcal for a single captured meal.
*   `macro_total_extreme` (error) / `macro_total_high` (warning): totals above 350/700/300 g or 250/550/220 g of protein/carbs/fat.

---

## 4. Multi-Dimensional Cross-Check Validation Rules

To prevent erroneous database matching and portion estimation, Train Libre implements four strict multi-dimensional cross-check rules connecting matched database entities with the holistic culinary anchors:

### C1: expected Kcal Range Check
Verifies whether the sum of the calories of all matched database ingredients is within the expected total meal calorie range from the culinary anchor:
*   **Warning (`anchor_kcal_deviation`)**: Raised if the total matched calories deviate by > 25% from the nearest boundary of the expected range.
*   **Error (`anchor_kcal_extreme`)**: Raised if the total matched calories deviate by > 50% from the nearest boundary, escalating to a hard validation failure.

### C2: Expected Macro Profile Check
Compares the matched database macronutrient distribution against the expected macro percentage profile in the culinary anchor:
*   **Warning (`anchor_macro_profile_deviation`)**: Raised if the actual protein, carbs, or fat percentage deviates by > 15% from the anchor profile.

### C3: Cooking State Mismatch Check
Detects preparation state discrepancies between the AI's parsed item and the matched database entry (e.g., a "raw chicken breast" matched to "cooked chicken breast"). Both sides are read for raw and cooked markers in German and English (`raw`/`roh`, `cooked`/`gekocht`, `fried`/`gebraten`, `baked`/`gebacken`, `boiled`, `zubereitet`):
*   **Warning (`state_mismatch`)**: Raised when the state hint and the matched entry do not clearly agree.
*   **Error (same `state_mismatch` code, escalated severity)**: Raised when the two directly contradict each other — a raw hint on a cooked database entry or vice versa — because that is the case where the caloric density is systematically wrong.

### C4: Portion Density Anomaly Detection
Checks for implausible ingredient quantities based on standard portion densities:
*   **Warning (`implausible_portion_density`)**: Raised if the matched database product density deviates significantly, meaning the effective portion density is > 2x or < 0.5x of the default database product density, indicating potential gram calculation anomalies.

---

## 5. The "Top-N Fuzzy Alternatives" Candidate Selection System

When a validation issue or match anomaly occurs, Train Libre does not let the LLM blindly guess replacements. Instead, the local Dart engine uses a **Candidate Selection** model:

1.  **Local Database Querying**: The `ProductLocalDataSource` queries the SQLite database via `fuzzyMatchCandidatesForRepair`, pulling the top 5 to 10 closest fuzzy matches using Jaro-Winkler string similarity.
2.  **State-Aware Re-ranking**: Candidates are re-ranked based on preparation state matches (e.g., prioritising cooked or grilled items if a cooking hint is present).
3.  **Prompt Menu Injection**: These database candidates (including their exact database names, calories, and macronutrient distributions) are structured as a selection menu and injected directly into the repair prompt payload under a `CANDIDATES` block.
4.  **Semantic Selection**: The LLM acts as a semantic selector rather than an estimator, choosing the mathematically and culinary-wise best-fitting database candidate.

---

## 6. The 3-Pass Self-Repair Loop

To recover from invalid JSON formats, incorrect ingredient portions, or missing database matches, Train Libre runs a closed feedback loop managed by `AiRepairOrchestrator`:

```
               [LLM Candidate Output]
                         |
                         v
             [AiMealValidationEngine]
                         |
           Is Score >= 70 & No Errors?
             /                       \
          (Yes)                      (No)
           /                           \
[Pass Validation]            [Format Feedback Log]
                                        |
                            Has Loop Run < 3 Times?
                              /                 \
                           (Yes)                (No)
                            /                     \
                   [Re-request LLM]       [Fail Validation]
               (Injects Top-N Candidates &
                Holistic mealContext Anchor)
```

### 1. Scoring Formula
The engine computes an overall quality score starting at 100, subtracting points based on issue severity:
*   **Info Issue**: -2 points.
*   **Warning Issue**: -8 points.
*   **Error Issue**: -24 points.
*   **Missed macro target fit**: -12 points, applied once when an explicit macro target was given (recipe target-fit mode) and the result does not meet it.

The result is clamped to the 0–100 range.

### 2. Validation Threshold
A candidate only passes validation if:
*   The overall score is **≥ 70**.
*   There are **zero critical errors** (e.g., no `all_items_unmatched`, no `anchor_kcal_extreme`, no `invalid_quantity`).

### 3. Repair Feedback Generation
If the candidate fails, the engine generates a structured feedback block detailing the precise index of the offending items and the error codes (e.g., `state_mismatch`, `anchor_kcal_extreme`). The orchestrator submits this log alongside the list of verified **Top-N Database Candidates** and the **`mealContext`** back to the LLM. The loop runs for a maximum of **3 passes** before returning a final failed validation status.

---

## 7. Clinical Disclaimer
The AI Meal Capture system is an estimation tool designed to simplify dietary logging. Portion sizes and ingredient weights are heuristic estimates and may deviate from actual values. Users should manually verify all structural components and weights before finalizing their logs, especially when managing medical conditions like diabetes.

---

## 8. Related Documentation

*   [Meal Capture Pipeline](meal_capture_pipeline.md) — the capture paths that feed this engine and how a meal is stored afterwards.
*   [Depth Scale Hint](depth_scale_hint.md) — the LiDAR measurement and depth image that extend the prompt on capable devices.
