# Meal Capture Pipeline

> Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

Train Libre can create a diary entry from a barcode, a photo, typed meal text, or dictated text. The paths have different network and storage behavior. This page follows the capture into the diary; [BYOK AI Meal Capture & Validation](byok_ai_validation.md) explains AI matching and validation, and [Depth Scale Hint](depth_scale_hint.md) explains the optional camera depth input.

## Capture paths

| Input | What happens |
|---|---|
| Barcode | The camera detects a code and looks up a product in the local product data source. The user opens its quantity flow and confirms logging. If the product is missing locally, the screen reports that it was not found. |
| Photo | The camera captures a photo where a native capture session is available; otherwise the system camera picker is used. Gallery selection is also available. Up to four images can be added to one AI scan. |
| Typed text | The text is sent to the selected AI provider for a suggested meal. |
| Dictated text | Speech recognition produces editable text. Local cleanup runs first. If AI tidy-up is enabled, that transcript is also sent to the selected AI provider for optional restructuring; the locally cleaned transcript remains available if the request fails or times out. |
| Search, manual entry, template | These are separate diary-entry flows and do not require AI meal analysis. |

The active AI capture writer labels an image-less result `aiText`, including a voice-only capture; with images it uses `aiPhoto`. Although the database schema recognizes `aiVoice`, this writer does not currently set that source value. It stores dictated content in `voiceTranscript` when present.

## What leaves the device

An AI scan uses the provider selected in settings. The app constructs the meal request with its prompt, typed or dictated text, and any captured photos, then dispatches it to that provider. Cloud providers send the request to their service. The custom provider sends it to the configured URL; Ollama is addressed at `http://localhost:11434/v1`. Apple Foundation Models uses a separate native service path, so the app’s code does not send that request through the cloud-provider HTTP branches. The platform and model requirements for Apple’s local path are described in the BYOK page; this distinction does not establish a Neural Engine guarantee.

For photo analysis, the app prepares and encodes the images before building the provider request. If scale hints are enabled and a depth attachment is available, the request can also include scale facts and a rendered depth-map image. See [Depth Scale Hint](depth_scale_hint.md) for its limits. No photos or meal text are included in the AI scan telemetry described below.

Dictation is a separate boundary from meal analysis. The speech recognizer is asked to run on-device when the service reports that this is supported; on iOS this is checked for the selected locale. If it cannot start locally, the service tries the platform recognizer without the on-device option and the UI displays a network notice for that run. The resulting transcript may then go to the selected AI provider for tidy-up and/or meal analysis. A local text-cleanup pass runs before optional AI tidy-up.

Barcode detection itself performs a local product lookup. After the user confirms the quantity, the product and amount are logged in the diary. This article makes no claim that unrelated app telemetry or operating-system services are disabled during these flows; see [Capabilities & Privacy](overview.md) for app telemetry controls and boundaries.

## Diary records and photos

An AI review save creates a `MealEntries` row for the meal and links each matched food log to it through `mealEntryId`. The link is nullable, so older or ungrouped food logs remain valid. The entry records its time, meal slot, title, capture source, optional transcript, and photo paths. The current save path writes depth facts and additional photo paths to `captureMeta`; although the metadata type can represent a provider and model, this save path does not populate those fields.

Captured photos begin as temporary camera or picker files. On save, the app copies each photo to the app’s media directory under application support, stores relative paths, and creates a smaller preview when image processing succeeds. If storing a photo fails, its path is omitted. The first photo and preview use the entry’s photo columns; additional photo paths are kept in `captureMeta`. Images sent for AI analysis are separately prepared for provider requests, so the persisted photo is not necessarily the same encoded image payload used for analysis.

`MealEntries` are meal events. `Meals` and `MealItems` are reusable templates. Their names are similar, but they serve different purposes.

## Capture telemetry and local diagnostics

When telemetry is enabled by the user, meal-scan events report fields such as provider, input mode, photo count, whether text, voice, or LiDAR was present, duration, validation outcome, and token usage. The event properties do not include meal text or image contents. Barcode logging and depth captures with valid scale facts or a depth buffer also have feature-use events.

Separately, AI scan diagnostics are stored on-device in a bounded history (up to 20 scans). The diagnostic export includes provider/model where available, input mode, counts, timing, validation outcomes, and usage totals; it excludes prompts, meal contents, photos, file paths, API keys, and raw error messages. The diagnostics are distinct from network telemetry.

## Related documentation

- [BYOK AI Meal Capture & Validation](byok_ai_validation.md) — provider-specific request and response behavior, matching, and repair.
- [Depth Scale Hint](depth_scale_hint.md) — camera depth facts and the optional image attachment.
- [Capabilities & Privacy](overview.md) — app-wide telemetry controls and privacy boundaries.
- [Localization Architecture](../developer/localization_architecture.md) — local product catalogs used by barcode and search flows.
