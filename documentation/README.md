# Train Libre: Modular Documentation Suite

Welcome to the technical documentation suite for **Train Libre**, a highly performant, offline-first, and privacy-centric wellness, sleep, and nutrition tracking application. This suite provides detailed architecture specifications, state management paradigms, and mathematical descriptions of the core algorithmic features of the application.

## Project Vision

Train Libre is designed around the core principles of user autonomy, offline capability, and algorithmic transparency. By avoiding any centralized backend, storing all user records in a local SQLite database (via Drift), and utilizing a Bring Your Own Key (BYOK) model for optional AI enhancements, the application guarantees absolute user privacy and data ownership.

---

## Documentation Directory Map

This documentation suite is split into highly modular, focused files categorised by audience and purpose. Use the links below to navigate the suite.

### 1. Developer Documentation (`documentation/developer/`)
For software engineers, system architects, and technical contributors.

*   [**System Overview & Testing Philosophy**](developer/overview.md): High-level system purpose, tech stack, and details on our highly stable 147-file, 900+ test suite.
*   [**System Architecture & SQLite Lifecycle**](developer/architecture.md): Our strict Clean Architecture boundaries (Presentation $\rightarrow$ Domain $\leftarrow$ Data) and thread-safe lazy-initializing private constructor for SQLite.
*   [**Data Flow & State Lifecycle**](developer/data_flow_and_state.md): Detail on our "Reactive Reads / Imperative Writes" paradigm, reactive Drift stream handlers, subscription lifecycles, and edit-mode user interface input blocking.
*   [**Localization Architecture**](developer/localization_architecture.md): Offline-first relational localization strategy for the app's catalogs and UI strings, plus the step-by-step guide for adding a new locale.

### 2. Feature Transparency & Algorithmic Logic (`documentation/features/`)
For advanced users, mathematical evaluators, and privacy auditors who seek complete transparency into our smart processing engines.

*   [**Capabilities & Privacy Overview**](features/overview.md): Summary of the app's advanced smart capabilities, local processing model, and native secure storage.
*   [**Bayesian TDEE Estimator (Kalman Filter)**](features/bayesian_tdee_estimator.md): Full mathematical and algorithmic analysis of the Adaptive Diet Recommendation Engine, including Kalman filter equations, variance boundaries, completeness coefficients, and linear ramps.
*   [**BYOK AI Meal Capture & Validation**](features/byok_ai_validation.md): Core detail on the local BYOK API integration, system prompts restricting LLM calculations, fuzzy string matching, target-fit verification, and the 3-pass self-repair verification loop.
*   [**Meal Capture Pipeline**](features/meal_capture_pipeline.md): The capture paths around the analysis — unified camera with passive barcode detection, voice dictation, meals as logged events, photo storage, and what leaves the device on each path.
*   [**Depth Scale Hint (LiDAR)**](features/depth_scale_hint.md): How measured scale facts and an optional false-colour depth image improve portion estimation on LiDAR devices, including the quality gate and the explicit non-goals.
*   [**Native Health Sync & Export**](features/health_sync_export.md): Technical overview of the Apple HealthKit and Google Health Connect data syncing pipelines (bidirectional for vitals), details on step segment merging, and the SQLite-backed Single Source of Truth (SSOT) idempotency architecture.
*   [**Sleep Health Score Engine (SHS v3.5)**](features/sleep_scoring_engine.md): Complete technical specification of our sleep scoring algorithms, including Gaussian, logistic, and quadratic curves for 5 domains and the continuous soft-cap multiplier penalty logic.
*   [**Muscle Recovery & Fatigue Modeling**](features/muscle_recovery_model.md): Detailed heuristic for estimating muscle-specific readiness using piecewise interpolation, volume-based recovery windows, and intensity-based fatigue extensions.
*   [**Estimated 1-Rep Max Heuristic**](features/intelligent_workouts.md): The Epley-based submaximal strength estimation model behind personal records and strength progression, including its non-medical scope.
*   [**Live Activity & Workout Session**](features/live_activity_workout.md): The iOS Live Activity and Dynamic Island surface for a running workout, and the state it mirrors.
*   [**iOS Home Screen Widgets**](features/ios_home_screen_widgets.md): The home screen widget family, their configuration, and the data they read.
