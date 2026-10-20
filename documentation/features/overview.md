# Feature Capabilities and Privacy Boundaries

Train Libre is local-first: workout, diary, measurement, sleep, and other app records are stored in the app’s local database. Optional integrations can move selected data outside that database. In particular, network AI providers receive the meal input sent for analysis, HealthKit or Health Connect can exchange records when enabled, user-triggered exports and backups can create files, and optional telemetry sends usage events after consent. “Local-first” therefore does not mean that every operation is offline or that no data can leave the device.

> Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

## Data boundaries

### Local calculations and records

The TDEE estimator, macro allocator, adaptive-goal review logic, sleep score, muscle-recovery estimate, and estimated 1RM calculations run in the app. Their inputs come from app records and, where configured, imported health data. They do not require sending those records to a server for the calculation. Estimates and recommendations are heuristics; their presence in the app does not make them clinical assessments.

The AI meal-capture path is different. The selected provider receives the prompt and, for image analysis, resized meal images. Providers include remote services and local/custom endpoints; the destination depends on the provider and its configuration. Apple Foundation Models is an on-device option when the native framework is available. The code does not establish that every provider is offline, that every supported device uses a Neural Engine, or that provider processing has the same privacy terms. Review the [AI capture and validation documentation](byok_ai_validation.md) before choosing a provider.

### Optional connections

HealthKit on iOS and Health Connect on Android are separate platform integrations. Permissions and supported data types determine what can be imported or exported. The app also has user-triggered backup/export flows and optional iCloud sync. These paths are distinct from optional product telemetry; enabling one does not imply that health records are included in telemetry. See [Health Sync & Export](health_sync_export.md) for the supported data and platform limits.

API credentials are stored through `FlutterSecureStorage`. The iOS and macOS configuration uses this-device-only Keychain accessibility; this Dart configuration does not establish the same platform-specific storage guarantee for Android. See the [AI provider and validation page](byok_ai_validation.md) for provider-specific request behavior.

### Optional usage telemetry

Telemetry is disabled unless the user opts in. Initialization reads the saved choice, and PostHog SDK setup is deferred until opt-in; setting `DISABLE_TELEMETRY=true` at build time selects a no-op implementation. Users can opt out in Settings. The app sends opted-in events to PostHog’s EU capture endpoint.

The SDK configuration disables person profiles, lifecycle capture, surveys, replay, feature-flag events, push events, and rage-click capture, and filters selected event names. SDK events receive properties that disable PostHog person-profile processing and GeoIP lookup. In-app SDK identity is reset on SDK configuration to rotate its distinct ID. The separate `app_launched` event is sent directly over HTTP with a locally stored persistent install ID, so telemetry is pseudonymous rather than fully anonymous or identity-free.

Event properties are not uniformly coarse buckets. Depending on the event, they include app/platform/OS version, locale, country, time zone, feature and screen keys, counts, durations, booleans, AI provider, and validation outcome metadata. The AI scan telemetry helpers report request metadata rather than the submitted meal text or images. The telemetry service uses closed values or sanitization for selected fields. This describes app-created telemetry payloads; it is not a guarantee about PostHog’s service-side retention or processing beyond the SDK configuration.

## Feature directory

These articles explain feature logic and its limitations. Practical instructions belong in the [User Guide](../user_guide/overview.md); implementation internals belong in [Developer Documentation](../developer/overview.md).

### 1. Bayesian TDEE Estimate and Adaptive Calorie Target

A recursive Bayesian estimator combines logged intake and body-weight observations with a baseline prior. A separate controller can adjust an eligible calorie target after review. Both operate on local app data; sparse, incomplete, or incompatible data can prevent a target update.

* [Bayesian TDEE estimator](bayesian_tdee_estimator.md)

### 2. Macronutrient Distribution

A deterministic allocator converts a calorie target and profile/goal inputs into protein, fat, and carbohydrate targets, subject to configured bounds and fallback behavior. The allocation is an app rule, not an individualized clinical prescription.

* [Macronutrient Distribution](macro_distribution.md)

### 3. Meal Capture and BYOK AI Validation

Meal capture can use image, text, voice, or barcode workflows. AI analysis uses the selected provider; network providers receive the request content, while Apple Foundation Models can run on-device when available. Validation checks structured output against the local food catalog, but suggestions can remain ambiguous or require user correction.

* [Meal capture and AI validation](meal_capture_pipeline.md)
* [BYOK providers and validation](byok_ai_validation.md)

### 4. Health Sync and Export

Platform adapters exchange supported records with HealthKit or Health Connect after the relevant permissions and settings are enabled. Import, export, and update behavior varies by data type and platform; the feature is not a guarantee of complete or background synchronization.

* [Health Sync & Export](health_sync_export.md)

### 5. Sleep Health Score (SHS v3)

The score combines five sleep domains using the current v3 formulas and score caps. Imported records are mapped into the sleep inputs; missing or partial stage data can affect completeness and the result. The score is a software heuristic, not a diagnosis or a measure of medical sleep health.

* [Sleep Health Score engine](sleep_scoring_engine.md)

### 6. Muscle Recovery Estimate

The model turns eligible logged sets into time-decaying, per-muscle residual load and maps that load to a continuous readiness estimate. Its inputs and coverage limits depend on workout logging and exercise metadata.

* [Muscle Recovery model](muscle_recovery_model.md)

### 7. Estimated 1-Rep Max

The app estimates 1RM from eligible logged set loads and repetitions using its configured formula and valid repetition range. Bodyweight and assisted movements use effective-load rules; an estimate is not a guaranteed maximum or a safety assessment.

* [Estimated 1RM heuristics](intelligent_workouts.md)

### 8. Workout Progression

When enabled, the progression feature evaluates eligible recent performance and proposes set targets under the current simple progression policy. The user can review or edit the proposed values; eligibility and load mode affect the result.

* [Workout progression engine](workout_progression_engine.md)

### 9. Live Activity and Widgets

iOS provides a workout Live Activity; Android uses its workout notification surfaces and platform-supported live-update behavior. Home-screen widgets are a separate feature with platform-specific support and limits.

* [Live Activity and workout notification behavior](live_activity_workout.md)
* [Home Screen Widgets](../developer/ios_home_screen_widgets.md)

### 10. Adaptive Nutrition Goals

Users set a goal and can receive periodic review proposals when the implementation’s data and compatibility gates pass. Proposals require user action before they change targets.

* [Adaptive Nutrition Goals](adaptive_nutrition_goals.md)

### 11. Manual Workout Plans

Users can save routines as weekly schedules or repeating sequences, record session outcomes, and optionally schedule local reminders. Sequence advancement depends on the recorded outcome and plan rules.

* [Manual Workout Plans](manual_workout_plans.md)

### 12. Macronutrient Analytics

The Statistics hub passes a selected date range to macro analytics, which displays logged intake and comparison summaries. A displayed target can differ from the active diary target when a recommendation has not been applied.

* [Macronutrient Analytics](macro_analytics.md)
