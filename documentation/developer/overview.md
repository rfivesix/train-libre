# Developer Overview & Testing Philosophy

This document outlines the high-level system purpose, the modular offline-first tech stack, and the comprehensive testing philosophy that maintains stability across the Train Libre codebase.

---

## High-Level System Purpose

Train Libre is an offline-first, privacy-respecting health, nutrition, sleep, and activity tracker. Unlike traditional wellness applications that rely on persistent cloud servers, Train Libre runs entirely locally. It treats the user's mobile device as the primary computing unit and the absolute source of truth.

### Key Technical Pillars
1.  **Zero Backend Dependency**: No external cloud service or account is required for registration, database writes, sync logs, or analytic graphs. The user's device remains the absolute authority.
2.  **User-Driven Connectivity & Privacy Boundaries**: User actions initiate Bring Your Own Key (BYOK) AI capture APIs (or local/LAN Ollama endpoints), the platform speech recognizer used for meal dictation when no on-device recognizer exists, catalog downloads, and native system Health platforms (Apple HealthKit / Google Health Connect). Optional pseudonymised usage telemetry (PostHog EU) is disabled by default, uses coarse metric bucketing without person profiling, and may send its fixed event catalog only after explicit consent. A build compiled with `--dart-define=DISABLE_TELEMETRY=true` selects the no-op telemetry implementation.
3.  **Performance and Battery Preservation**: Database access and background syncing utilize optimized local querying, reactive streams, caching, and lazy initialization to minimize battery usage and CPU overhead.

---

## Technology Stack

The application's framework and core modules are built using the following technologies:

*   **Core Framework**: Flutter (Dart) for high-performance cross-platform presentation and systems integration.
*   **Local Persistence**: Drift (built on top of native SQLite databases) using schema version 31 with compile-time type safety, reactive streams, and additive schema self-healing (`reconcileSchema()`).
*   **Security & Encryption**: `flutter_secure_storage` to handle sensitive local data, such as private API keys for optional AI services, utilizing iOS Keychain and Android Keystore with device-only accessibility.
*   **Platform Integration**: Native Method Channels to bridge iOS Swift HealthKit and Android Kotlin Health Connect systems directly to Dart services.
*   **Home Screen Widgets & Live Activity**: Shared Dart snapshot architecture (`HomeWidgetSnapshot`) feeding iOS WidgetKit and Dynamic Island / Live Activities, as well as Android AppWidget/Glance providers and Quick Settings tiles, documented in the [Home Screen Widgets guide](ios_home_screen_widgets.md).

---

## Testing Philosophy

A core tenet of the Train Libre development lifecycle is strict mathematical and logic regression checking. Due to the high sensitivity of personal health records and the mathematical nature of the TDEE (Total Daily Energy Expenditure) filter, any logic drift would result in erroneous calorie targets or synchronization corruption.

To prevent regressions, the codebase maintains an automated test suite. Contributors should run the relevant tests and static analysis locally; this document does not claim that every pull request is enforced by a repository-wide test workflow.

### Test Categories
1.  **Unit Tests**: Validate mathematical engines (e.g., `BayesianTdeeEstimator` and Kalman updates, Brzycki 1RM heuristics with effective load resolution), text token fuzzy matching scores, data parsing models, and canonical health-data mapping algorithms.
2.  **Widget & Integration Tests**: Test page transitions, loading state blocks, secure key persistence, backup/restore file integrity, and asynchronous data ingestion flows.
3.  **Database Migration Tests**: Validate that schema transitions across all versions up to the current schema version 31 are completely lossless, and verify additive schema self-healing via `reconcileSchema()`.

### Core Testing Invariant
Changes should be validated with the relevant automated tests before merge. Database tests can inject an isolated database through `DatabaseHelper.forTesting()`, preventing them from colliding with real user storage.
