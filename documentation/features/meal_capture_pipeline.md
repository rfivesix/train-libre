# Meal Capture Pipeline

Logging a meal is one action with several entrances: a barcode, a photo, spoken words, a catalog search or a saved template. This document describes how those entrances work, what they have in common, and how the result is stored. The analysis and validation that happens *inside* an AI capture is described separately in [BYOK AI Meal Capture & Validation](byok_ai_validation.md); the LiDAR measurement that can accompany a photo is described in [Depth Scale Hint](depth_scale_hint.md).

---

## 1. A Meal as a Logged Event

A single AI scan of a plate produces several ingredients. Historically each one was an independent row in `NutritionLogs` that shared nothing but the string `'Lunch'` — so there was no object the photo, the meal name or a re-analysis could hang on.

`MealEntries` is that object. It records what happened, not what may be reused:

| Column | Meaning |
|---|---|
| `consumedAt`, `mealType` | when it was eaten and under which meal slot |
| `title` | the meal's name, e.g. "Chicken with rice" |
| `source` | how it was captured: `aiPhoto`, `aiVoice`, `aiText`, `barcode`, `manual`, `template` |
| `photoPath`, `photoThumbPath` | the photo and its preview, **relative** to the application support directory |
| `voiceTranscript` | the dictated text, when there was one |
| `captureMeta` | JSON side-car: LiDAR scale facts, AI provider and model, additional photos |

`NutritionLogs.mealEntryId` is the one column that connects the two. It is **nullable** and cleared rather than cascaded (`onDelete: setNull`), which is what keeps the change additive: every entry logged before this existed, and every entry logged without a group today, behaves exactly as before.

> **Naming caveat.** `Meals` / `MealItems` are *templates* to reuse. `MealEntries` are *events* that happened. The similar names are historical and are a known wart.

`captureMeta` is deliberately schemaless — a nullable text column costs nothing while the shape of the feature is still moving, and malformed or outdated metadata degrades to "no extras" rather than breaking the meal it belongs to.

---

## 2. The Unified Camera

On iOS a single `AVCaptureSession` can deliver a preview, barcode metadata, still photos and depth at the same time. `AiMealCaptureScreen` uses exactly that: one native session that runs preview, passive barcode detection, photo capture and (where available) LiDAR depth together.

### Passive Barcode Detection
Barcode detection runs continuously while the meal camera is open and is on by default — most packaged foods are logged by barcode, and requiring the user to decide *in advance* whether the thing in front of them is a barcode or a plate is a decision the app can make itself. A detected code opens the normal quantity-logging flow for that product.

### Fallbacks
Nothing depends on the unified session succeeding:
*   If the native session cannot start, the screen falls back silently to the `qr_code_scanner_plus` preview.
*   `ScannerScreen` remains as a standalone barcode entrance.
*   `image_picker` remains the path for photos from the gallery.

Camera hardware is suspended and resumed with the route lifecycle, so a backgrounded or covered screen holds no camera or depth sensor.

---

## 3. Voice Dictation

Dictation is available both on its own ("describe your meal") and as an addition to a photo, where the transcript is passed to the analysis as a text hint.

*   **On-device first.** `VoiceDictationService` prefers on-device recognition and reports up front whether the device can do it, so the consent copy is accurate *before* the user speaks rather than after.
*   **Network disclosure.** When the platform has no local recognizer, recognition falls back to the platform's network recognizer (Apple or Google). `lastRunUsedNetwork` reports this so the interface can disclose it. This is a platform service, not a Train Libre endpoint, and it carries audio for the duration of the dictation only.
*   **Permissions.** Microphone and speech recognition are requested at the point of use (`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`); the microphone is live only while the dictation control is held.
*   **Tidy pass.** The raw transcript is restructured by a small AI prompt that fixes misheard food names and drops filler, without inventing foods, amounts or preparation. Without a configured AI provider, dictation is simply not offered.

---

## 4. Photo Storage

Meal photos are the first thing in the app that can grow without bound, so they are handled by shared infrastructure rather than by the diary itself.

*   `AppMediaStore` owns the files for every feature under one set of rules; `MealPhotoStore` is the meal-shaped face of it.
*   Every save writes a full-size photo and a downscaled preview, both stored **relative** to the application support directory — absolute paths would break on the next app update.
*   If a copy fails, no path is stored at all rather than a path into a temporary file that will vanish.
*   `pruneOrphans` removes files that no database row references any more, which is what keeps the folder from growing forever.

Photos are local files, not database blobs; treat them accordingly when reasoning about backup size and export contents.

---

## 5. What Is Sent Where

| Capture path | Leaves the device? |
|---|---|
| Catalog search, template, manual entry | No |
| Barcode | No — matched against the locally installed Open Food Facts catalog |
| AI photo / text | Photo and text go to the user's own configured BYOK provider only |
| AI photo with depth | Additionally a few centimetre measurements and, if enabled, a false-colour depth image |
| Voice dictation | Audio to the platform recognizer only when the device has no on-device recognizer; the resulting text then follows the AI text path |

Without a configured AI provider, none of the AI paths exist and nothing is transmitted.

---

## 6. Related Documentation

*   [BYOK AI Meal Capture & Validation](byok_ai_validation.md) — prompts, matching and the self-repair loop.
*   [Depth Scale Hint](depth_scale_hint.md) — the LiDAR measurement attached to a photo.
*   [Localization Architecture](../developer/localization_architecture.md) — the Open Food Facts catalogs that barcode and search resolve against.
