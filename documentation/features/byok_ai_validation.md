# AI Meal Capture & Deterministic Validation Engine

Train Libre sends a meal description or prepared image to the selected AI provider. In local catalog mode it matches returned suggestions against the food catalog and checks the candidate before diary save. Direct AI estimate mode instead saves reviewed nutrition estimates as macro snapshots without catalog matching. The selected provider may be an online service, a user-configured OpenAI-compatible endpoint, Ollama at `localhost`, or Apple Foundation Models when available. The app computes matched-item nutrition from catalog data and proposed grams; some response shapes also contain model-proposed meal-level calorie and macro ranges for heuristic validation, not verified nutrition facts.

The matching and validation details below describe local catalog mode; they do not guarantee verification of direct AI nutrition estimates. This document describes the analysis and validation engine. The surrounding photo, text, voice, barcode, meal grouping, and photo-storage flows are described in [Meal Capture Pipeline](meal_capture_pipeline.md).

---

## 1. Provider routes and key storage

The request path is selected in the app; there is no Train Libre AI proxy in these call sites. For online providers, the app posts prompt content and prepared JPEG data from the device to the provider endpoint. Requests are provider-specific:

| Selection | Request path in the app |
| --- | --- |
| OpenAI | `https://api.openai.com/v1/chat/completions` |
| Gemini | `https://generativelanguage.googleapis.com/{v1beta or v1}/models/{model}:generateContent`; API key is a query parameter, and the client can try alternate model/version routes after model/version errors. |
| Anthropic | `https://api.anthropic.com/v1/messages` |
| Mistral | `https://api.mistral.ai/v1/chat/completions` |
| DeepSeek | `https://api.deepseek.com/chat/completions` |
| xAI | `https://api.x.ai/v1/chat/completions` |
| Ollama | `http://localhost:11434/v1/chat/completions` |
| Custom | The configured base URL with `/chat/completions` appended. |
| Apple Foundation Models | Native iOS method-channel call; availability and image support are gated by iOS/framework versions below. |

The OpenAI-compatible request builders attach image data as `data:image/jpeg;base64,...` with low detail; Gemini and Anthropic use their own inline/base64 image formats. The app's image processor prepares/resizes images before these requests. Which endpoint actually stores or processes submitted data is governed by that provider or configured server.

### Apple Foundation Models (`appleFoundation`)
The Apple provider is offered only on iOS and the native plugin reports it available only when `SystemLanguageModel.default` is available on iOS 26 or later. Train Libre passes the prompt and any prepared image bytes to a Swift `LanguageModelSession`; image attachments are used only on iOS 27 or later in builds with the required compiler support. The app can prewarm a session with the system instructions. This repository does not establish that Apple processing uses a particular chip, has zero storage/network activity, or is available on every iOS 26 device; the framework availability result is the runtime gate. Although the Flutter layer can pass image bytes, iOS 26's code path calls the text-only `respond(to:)` overload, so photo understanding through this provider is not available there.

### Encrypted Key Storage (BYOK Providers)
For providers that require a key, Train Libre reads and writes a per-provider key using `FlutterSecureStorage` under `ai_api_key_<provider>`. The source explicitly configures device-only accessibility for iOS and macOS. It does not specify Android storage options here, so this page does not make a platform-specific Android Keystore or backup claim. The selected provider and model identifiers are also stored; selected-provider state has a SharedPreferences fallback.

*   `ai_api_key_openai`: Secure key for OpenAI.
*   `ai_api_key_gemini`: Secure key for Google Gemini.
*   `ai_api_key_anthropic`: Secure key for Anthropic Claude.
*   `ai_api_key_mistral`: Secure key for Mistral.
*   `ai_api_key_deepseek`: Secure key for DeepSeek.
*   `ai_api_key_xai`: Secure key for xAI Grok.
*   `ai_api_key_ollama`: Optional — the app does not attach an API key to its Ollama request.
*   `ai_api_key_custom`: Optional key for any OpenAI-compatible endpoint.

The selected provider is stored under `ai_selected_provider` in secure storage and mirrored to SharedPreferences. Most selected model IDs use `ai_selected_model_<provider>`; Ollama and Custom share `ai_custom_model`, and Custom also stores `ai_custom_base_url`.

### Self-Hosted and Custom Endpoints
Two additional choices use OpenAI-compatible request construction:

*   **Ollama**: the app sends requests to `http://localhost:11434/v1`. That is the device's loopback address; the code does not configure a home-network server address.
*   **Custom OpenAI Compatible**: sends the request to the configured base URL with an optional key and model. The destination and its network/privacy behavior depend on the value entered by the user.

The client includes images for these request paths, but whether a given endpoint/model accepts or processes vision depends on that endpoint. Cloud providers receive the text and image data included in their request. The configurable request timeout defaults to 60 seconds; code stores the supplied value without enforcing a range here.

---

## 2. System Prompt & LLM Boundaries

The prompt requests food names and portion estimates. The structured schema excludes per-item calorie and macro fields, but provider/schema enforcement varies; treat all model output as a suggestion:

1.  **Food-level nutrition**: The item schema has no calorie or macro fields, and matched-item nutrition used by validation comes from catalog entries multiplied by suggested grams. The model may propose `expectedKcalRange` and `expectedMacroProfile` as whole-meal context when those fields are requested; these are estimates, not verified nutrition facts. When the parser receives a legacy top-level `dishType` without a context, or a context with a malformed range, it can use `[0, 9999]` as a broad calorie fallback, which effectively weakens the range check.
2.  **Decomposition request**: The prompt asks the model to split composite meals into ingredient items. This instruction does not guarantee complete or correct decomposition.
3.  **Names and retrieval variants**: The prompt requests concise names and 1–2 ingredient-specific `searchTerms`, including a German BLS search term when needed. It also has an exception for specifically identified branded/packaged foods, which may use `catalogSearchTerm` and provide `packagedProductEvidence` based on the image or user input.
4.  **Consolidation**: The prompt asks the model to combine duplicates. Independently, the local validator merges duplicate normalized names with the same barcode by summing grams and keeping the higher confidence.
5.  **Model-proposed meal context (`mealContext`)**: The structured schema requests a `mealContext` block used as a heuristic cross-check. The non-schema prompt uses a different top-level example and does not request a macro profile; the parser accepts multiple shapes and supplies fallback context when needed:
    *   `dishType`: Name of the identified dish.
    *   `expectedKcalRange`: Model-proposed total calorie boundaries `[low, high]`.
    *   `expectedMacroProfile`: When present, model-proposed macronutrient percentage ranges (`proteinPercent`, `carbsPercent`, `fatPercent`), each as `[low, high]`.
    *   `cookingMethod`: Overall preparation method of the dish.
    *   `contextNotes`: Free-text culinary details. These fields are model output and are not independently established facts.
6.  **Catalog search terms**: The prompt gives separate handling to generic ingredients and identified packaged products. Generic terms are searched against local base-food data; `catalogSearchTerm` is intended for a specific packaged product in its catalog language, not a general translation field.
7.  **Two portion values**: The prompt asks for `servedGrams` and `estimatedGrams`; the parser uses `estimatedGrams` as the item grams used in catalog nutrition calculations, falling back to other gram fields if omitted. For prepared food, the prompt describes `estimatedGrams` as a raw equivalent. The app does not independently verify that conversion.
8.  **Requested output shape**: The structured schema requests a JSON object with `mealContext` and `items`; the non-schema prompt shows a different object shape. Provider schema enforcement is conditional: the app enables structured output only for selected provider/model families, and retries some schema-rejection responses without the provider schema. The parser also accepts several alternate JSON wrappers, so the exact shape is not guaranteed by the runtime for every provider.
    *   `mealContext`: The holistic culinary anchors described above.
    *   `items`: A list of food components, each with `name`, optional `catalogSearchTerm`, `searchTerms`, `servedGrams`, raw-equivalent `estimatedGrams`, `confidence` and `stateHint`.

### Optional Prompt Blocks
Two blocks are prepended to the system prompt only when the corresponding data exists:

*   **LiDAR scale measurement**: measured distance and visible frame size in centimetres, marked explicitly as measured rather than estimated. See [Depth Scale Hint](depth_scale_hint.md).
*   **Depth map legend**: when both a depth image and non-empty legend are supplied, the image is appended after meal photos and the legend is included in the prompt.

### Voice Transcript Tidy Pass
Dictation can use a separate tidy request before meal analysis. It asks the model to return food bullets and context while preserving what was said; this is a prompt instruction, not a guarantee that the model cannot alter or omit content. The request is capped at 15 seconds and a failed/empty tidy response returns `null`, allowing the caller to keep its locally cleaned transcript. See [Meal Capture Pipeline](meal_capture_pipeline.md).

---

## 3. Deterministic Validation Engine

Once the AI returns its JSON list, the raw suggestions are processed by the local `AiMealValidationEngine`. This engine applies a series of rigid checks:

### Merge Heuristics & Normalization
Before evaluating database matches, the engine normalizes all text tokens and checks for duplicates. If duplicate ingredients are detected, they are automatically merged: the weights are summed, and the maximum confidence is retained.

### Database Matching & Quality Classification
The engine searches local catalog data using the item name, optional `catalogSearchTerm`, and `searchTerms` (up to six distinct query strings). Open Food Facts fallback is gated by packaged-product evidence/user permission. Candidate ranking uses the strongest textual score from the permitted query terms and then source/name tie-breakers; it does not treat the first returned database row as authoritative. This lookup itself is local; semantic repair, when needed, makes another selected-provider request.
*   **Exact Match (Score ≥ 0.95)**: Perfect textual alignment or matching barcode.
*   **Strong Match (Score ≥ 0.78)**: Excellent alignment (e.g., token overlaps).
*   **Partial Match (Score ≥ 0.55)**: Triggers an informational issue.
*   **Weak Match (Score < 0.55)**: The result is still a weak match in ordinary cases; an unreviewed broad alias at or below 0.54 is instead left unmatched for clarification.
*   **Unmatched**: No usable selected candidate, including when search returns no candidates or the engine rejects weak unreviewed alias evidence. It is not a single numeric score threshold.

Match quality is reported as validation issues: a weak match raises a warning, a partial match is informational, and lexical ambiguity is considered when the top scores are within 0.08 and the best score is below 0.95. These are software review signals, not measures of food identity certainty.

### Item-Level Validation Rules
The engine applies fixed review thresholds to suggested portions. These are heuristic guardrails, not clinically validated physiological limits:
*   **Grams ≤ 0**: Triggers an `invalid_quantity` error.
*   **Grams > 3000g**: Triggers an `extreme_quantity` error.
*   **0 < grams ≤ 5g**: Triggers a `tiny_quantity` informational issue.
*   **Grams > 1200g**: Triggers a `large_quantity` warning.
*   **Confidence < 0.5**: Triggers a `low_ai_confidence` informational issue.

Once an item is matched, the matched database entry is checked as well:
*   `zero_nutrition_match`: the matched entry carries no usable nutrition data.
*   `implausible_food_density`: the matched entry exceeds 950 kcal per 100 g.
*   `macro_energy_mismatch`: the entry's macros imply more than 180 kcal above its stated calories.
*   `implausible_item_nutrition`: this portion alone exceeds 2500 kcal, 250 g protein, 500 g carbs or 220 g fat.
*   `ambiguous_nutrition_match`: plausible local candidates differ by at least 75% in kcal per 100 g and the best match has not already been explicitly selected and verified. This triggers semantic candidate selection in the repair loop even when the lexical match itself looks strong.

### Meal-Level Validation Rules
Beyond the individual items, the assembled meal is checked as a whole:
*   `empty_meal` (error): the AI returned no items.
*   `all_items_unmatched` (error): not a single item could be matched to the local database.
*   `partial_unmatched_items` (warning): some items remain unmatched. The review flow can save matched entries only after the user confirms a partial save; unmatched suggestions are not saved as food entries.
*   `zero_total_kcal` (warning): matched items sum to 0 kcal.
*   `capture_total_kcal_extreme` (error) / `capture_total_kcal_high` (warning): above 5000 / 3500 kcal for a single captured meal.
*   `macro_total_extreme` (error) / `macro_total_high` (warning): totals above 350/700/300 g or 250/550/220 g of protein/carbs/fat.

---

## 4. Multi-Dimensional Cross-Check Validation Rules

Train Libre applies additional heuristic cross-checks between catalog-derived totals and any supplied meal-context anchors:

### C1: expected Kcal Range Check
Verifies whether the sum of the calories of all matched database ingredients is within the expected total meal calorie range from the culinary anchor:
*   **Warning (`anchor_kcal_deviation`)**: Raised if the total matched calories deviate by > 25% from the nearest boundary of the expected range.
*   **Error (`anchor_kcal_extreme`)**: Raised if the total matched calories deviate by > 50% from the nearest boundary, escalating to a hard validation failure.

### C2: Expected Macro Profile Check
Compares the matched database macronutrient distribution against the expected macro percentage profile in the culinary anchor:
*   **Warning (`anchor_macro_profile_deviation`)**: Raised if an actual protein, carbohydrate, or fat energy percentage falls more than 15 percentage points outside the model-proposed range.

### C3: Cooking State Mismatch Check
Detects preparation state discrepancies between the AI's parsed item and the matched database entry (e.g., a "raw chicken breast" matched to "cooked chicken breast"). Both sides are read for raw and cooked markers in German and English (`raw`/`roh`, `cooked`/`gekocht`, `fried`/`gebraten`, `baked`/`gebacken`, `boiled`, `zubereitet`):
*   **Warning (`state_mismatch`)**: Raised when the state hint and the matched entry do not clearly agree.
*   **Error (same `state_mismatch` code, escalated severity)**: Raised for some detected direct raw/cooked contradictions. A prepared visible portion with a distinct `estimatedGrams` value is treated as an intentional conversion and bypasses this state-mismatch check.

### C4: Prepared Portion versus Raw Database Basis
`servedGrams` and `estimatedGrams` can differ. For example, the prompt may ask the model to estimate a raw equivalent for a cooked portion. The app uses `estimatedGrams` for catalog nutrition and does not apply a fixed yield table or independently verify the conversion.

---

## 5. Multi-Query Candidate Selection and Semantic Repair

When a validation issue or match anomaly occurs, the repair flow can ask the selected model to choose among catalog alternatives:

1.  **Local Multi-Query Retrieval**: `ProductLocalDataSource` queries the item name, optional `catalogSearchTerm`, and `searchTerms` (up to six distinct terms), merges duplicate rows, and ranks the returned local alternatives.
2.  **Nutrition-Spread Gate**: If candidates have materially different kcal per 100 g, a textually plausible result is not accepted merely because its name is close.
3.  **Prompt Menu Injection**: The repair prompt receives locally retrieved candidate names, nutrition values, and candidate IDs.
4.  **Semantic Selection by Candidate ID**: The model may return a candidate ID in `matchedBarcode`; the app keeps the selection only if that ID matches one of the alternatives supplied for that item. The field can identify a base-food catalog row and should not be read as proof of a packaged barcode. In semantic-only repairs, the app keeps the previous quantities and state; other repair types may revise permitted grams and fields.

---

## 6. Repair Requests and Revalidation

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
                       Has repair request count < 3?
                              /                 \
                           (Yes)                (No)
                            /                     \
                   [Re-request LLM]       [Fail Validation]
               (Injects real candidates, their IDs,
                nutrition data & mealContext Anchor)
```

### 1. Scoring Formula
The engine computes an overall quality score starting at 100, subtracting points based on issue severity:
*   **Info Issue**: -2 points.
*   **Warning Issue**: -8 points.
*   **Error Issue**: -24 points.
*   **Missed macro target fit**: -12 points when a macro target context is supplied and the result does not meet it.

The result is clamped to the 0–100 range.

### 2. Validation Threshold
A candidate only passes validation if:
*   The overall score is **≥ 70**.
*   There are **no error-severity issues** (including `all_items_unmatched`, `anchor_kcal_extreme`, or `invalid_quantity`).
*   Materially different nutrition candidates have been resolved to a selected catalog candidate; the selection is not proof that the AI identified the food correctly.

### 3. Repair Feedback Generation
If the candidate fails **or requires semantic selection because candidate nutrition differs materially**, the engine generates structured feedback with the affected item indices and issue details. The orchestrator supplies that feedback and relevant local alternatives to the selected model. Every repaired response enters the same local validation again. The loop runs for a maximum of **3 repair requests** before returning its latest result.

## 7. Review and diary save

The repair result is presented in the meal review screen. At save time, the screen validates again when it has no current validation result, requires the result to pass, and builds a save plan from matched items. If the plan is partial, the user must confirm saving only the matched entries. The app saves a meal entry and corresponding food rows for matched catalog items; it does not save unmatched suggestions as food entries. The user can edit suggestions before saving.

---

## 8. Privacy, telemetry, and limitations

For cloud providers, text and prepared image data included in the request are sent directly to the selected provider endpoint; the repository does not route those requests through a Train Libre server. Ollama uses the device's `localhost` endpoint, while a custom provider sends data to the configured URL. Apple Foundation Models receives the prompt through the native iOS framework path and can receive image attachments on the supported iOS 27+ path; this repository alone cannot substantiate claims about all operating-system network or storage behavior.

When telemetry is enabled, scan events can include provider, input mode, photo count, whether voice/text/LiDAR were used, outcome, elapsed times, validation/repair counts, issue categories, and provider-reported token counts. The app also keeps a separate bounded local diagnostic history in SharedPreferences, including provider/model (except custom/Ollama model names), timing, outcomes, and token totals. Its allowlisted log/export excludes prompts, meal contents, images, paths, API keys, and error messages. Local diagnostics are not the same as telemetry consent.

Model-generated food identity, portions, meal context, and raw-equivalent weights can be wrong. Catalog matching and validation provide review signals; they do not guarantee that a suggested food or quantity is correct. Review the items and portions before saving.

Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

---

## 9. Related Documentation

*   [Meal Capture Pipeline](meal_capture_pipeline.md) — the capture paths that feed this engine and how a meal is stored afterwards.
*   [Depth Scale Hint](depth_scale_hint.md) — the LiDAR measurement and depth image that extend the prompt on capable devices.
