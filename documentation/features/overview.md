# Feature Transparency & Privacy Architecture

Train Libre leverages advanced computational intelligence to provide users with adaptive nutrition recommendations, intelligent meal capture, workout progression, recovery analytics, and robust health metrics synchronization. Crucially, all calculations and integrations are designed around strict **local-first** and **privacy-first** principles.

---

## Architectural Privacy Invariants

To achieve true user privacy and data ownership, the application enforces the following technical boundaries:

1.  **Zero Mandatory Cloud Intermediaries**: The application does not require a custom backend server to function. There is no central user database, no mandatory registration, and no login wall. All diary, workout, sleep, and metric records reside in local SQLite storage.
2.  **On-Device Encryption & Security**: Sensitive credentials, specifically the user-provided API keys required for Bring Your Own Key (BYOK) Large Language Models, are stored in hardware-backed system secure vaults (iOS Keychain and Android Keystore) via `FlutterSecureStorage` with device-only accessibility.
3.  **Local Algorithmic Execution**: High-level statistical and physiological logic — including the Kalman filter for TDEE, macronutrient distributions, the Sleep Health Score engine, muscle recovery timelines, and Brzycki 1RM heuristics — executes entirely on-device. Personal logs, bodyweight measurements, and physical metrics are never transmitted to external servers for analytical evaluation.
4.  **Strictly Opt-In, Zero-Profiling Usage Telemetry**:
    *   Disabled by default upon installation.
    *   No network connection or SDK initialization occurs before explicit consent.
    *   Consent is requested separately from mandatory terms, with at most one non-intrusive follow-up after 14 days and 5 app launches.
    *   When enabled, events (sent to PostHog EU) are decoupled from device identity via per-launch ID rotation. Personal profiles are suppressed (`personProfiles: never`, `$process_person_profile: false`), rageclicks/autocapture are disabled, and all metrics are grouped into coarse, anonymous buckets (`TelemetryBuckets`).
    *   Users can revoke consent or delete all server-side records with one tap in Settings.
    *   A build compiled with `--dart-define=DISABLE_TELEMETRY=true` selects the no-op telemetry implementation, so telemetry initialization and event dispatch do not run.

---

## Smart Capabilities Overview

The core computational modules of Train Libre are split into isolated, mathematically transparent features:

### 1. Bayesian TDEE Estimator
A mathematical engine utilizing a recursive Kalman Filter. It combines daily bodyweight slope calculations with logged calorie intakes to predict the user's Total Daily Energy Expenditure (TDEE). By applying Bayesian priors and calculating real-time observation variance, the system adjusts calorie recommendations while automatically penalizing poor-quality or sparse data.
*   *Learn more in the [**Bayesian TDEE Estimator Documentation**](bayesian_tdee_estimator.md).*

### 2. Macronutrient Distribution
The deterministic second stage of the nutrition recommendation. It turns the estimator's calorie target into protein, carbohydrate, and fat figures: protein and fat are anchored per kilogram of body weight and scaled with the goal, carbohydrates take the remainder, and a fat floor bounds how far the distribution may give way on a budget too small to carry both targets.
*   *Learn more in the [**Macronutrient Distribution Documentation**](macro_distribution.md).*

### 3. BYOK AI Meal Capture & Validation
An image and text analysis capture engine that translates photo logs or food descriptions into atomic, loggable ingredient components. It operates under a **Bring Your Own Key (BYOK)** security structure, communicating directly with provider endpoints (OpenAI, Gemini, Anthropic, Mistral, xAI, Ollama, or custom OpenAI-compatible servers). It enforces a deterministic validation engine and a 3-pass self-repair validation loop to ensure all suggested weights and names map precisely to local database items before saving.
*   *Learn more in the [**BYOK AI Captured Meal Validation Documentation**](byok_ai_validation.md).*

### 4. Native Health Sync & Export
A local synchronization pipe bridging local wellness records with native platform health frameworks (Apple HealthKit on iOS and Google Health Connect on Android). The architecture is bidirectional:
*   **Import**: Ingests passive vitals (step segments, sleep stage intervals, and heart rate samples) into local SQLite tables, using configurable hourly step segment merging policies (`auto_dominant` and `max_per_hour`).
*   **Export**: Pushes user logs (body measurements, nutrition & hydration totals, and workout sessions) to the platform health store using a hash-based idempotency table (`health_export_records`) and incremental domain checkpoints to guarantee zero duplicate writes.
*   *Learn more in the [**Native Health Sync & Export Documentation**](health_sync_export.md).*

### 5. Sleep Health Score Engine (SHS v3.5)
A sleep analysis engine evaluating overnight recovery across 5 domains (Sleep Duration, Sleep Continuity, Sleep Stage Depth / Architecture, Circadian Timing, and Sleep Regularity). Using a continuous soft-cap multiplier model, the engine dynamically applies penalty factors based on the single worst-performing biological bottleneck (such as severe REM or N3 deep sleep deprivation, insufficient TST, or late circadian mid-sleep delays) to guide users with precise, contextual feedback.
*   *Learn more in the [**Sleep Health Score Engine Documentation**](sleep_scoring_engine.md).*

### 6. Muscle Recovery Model
A fitness-oriented piecewise linear decay heuristic designed to estimate readiness scores for individual muscle groups. It accounts for set-weighting based on primary vs. secondary involvement and intensity/RIR-based timeline extensions.
*   *Learn more in the [**Muscle Recovery Model Documentation**](muscle_recovery_model.md).*

### 7. Estimated 1-Rep Max (1RM) Heuristics
A physical capacity estimation model that computes estimated maximum strength capabilities from submaximal resistance training loads using the Brzycki formula. It accurately handles effective set loads for assisted exercises (subtracting machine assistance from bodyweight) and bodyweight movements (using historical bodyweight on the day the set was performed), capped within the safe $1 \leq r \leq 12$ repetition window.
*   *Learn more in the [**Estimated 1-Rep Max Documentation**](intelligent_workouts.md).*

### 8. Workout Progression
The workout recommendation uses the most recent first working set to suggest the next first set, then derives later-set targets from the completed first set with a transparent fatigue back-off. The user can edit every generated value directly.
*   *Learn more in the [**Workout Progression Documentation**](workout_progression_engine.md).*

### 9. Live Activity & Cross-Platform Widgets
Real-time glanceable surfaces mirroring active workouts and daily wellness metrics:
*   **Workout Live Activity**: iOS Lock Screen and Dynamic Island card displaying live set targets, active rest timers, and exercise navigation without background network polling.
*   **Home Screen Widgets**: Shared Dart snapshot engine delivering six glanceable widgets (Today Glance, Quick Actions, Steps, Measurements, Muscle Recovery, Last Workout) on both iOS 18+ and Android 12+.
*   *Learn more in the [**Live Activity Documentation**](live_activity_workout.md) and [**Home Screen Widgets Guide**](../developer/ios_home_screen_widgets.md).*
