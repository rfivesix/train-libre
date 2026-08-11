# Telemetry & Privacy Architecture in Train Libre

Train Libre is an open-source, privacy-first fitness and nutrition tracking app. We believe that user privacy and data ownership are fundamental rights. 

This document explains our **optional, privacy-focused usage statistics architecture**, why we collect telemetry, how we systematically prevent user profiling and location tracking, what data is (and is NOT) collected, and the complete schema of all telemetry events.

---

## 1. Purpose & Rationale: Why We Collect Telemetry

We collect aggregate usage statistics for three primary reasons:
1. **Product Improvement & Feature Cleanliness:** To understand which features in Train Libre are heavily used and which are ignored, allowing us to maintain a sleek codebase and deprecate unused options.
2. **Onboarding Optimization:** To analyze onboarding conversion rates, identify screens where users get confused or drop off, and measure time spent on setup steps to refine the initial user experience.
3. **Aggregate Impact Metrics:** To calculate overall app usage statistics (e.g. Daily/Monthly Active Users, total completed workouts, total logged food items across all users) for open-source project growth and milestone announcements (e.g., *"Over 5 million food items logged!"*).

---

## 2. Strict Opt-In Consent Architecture

* **Disabled by Default:** Telemetry is strictly **OFF** when Train Libre is first installed.
* **No Pre-Consent Connection:** The PostHog SDK is not even *initialized* before consent. `Posthog().setup()` is deferred out of `init()` and into `optIn()`, because the native SDK's `PostHogRemoteConfig.preloadRemoteConfig()` runs unconditionally at setup — it is gated only by a testing flag and ignores the opt-out state — so merely setting the SDK up would open a connection to PostHog EU and expose the device's IP address. An install that never opts in performs zero network activity toward PostHog and sends zero events, `app_launched` included. A local device UUID is still generated on first launch so DAU counting can start the moment a user does opt in; generating it involves no transmission.
* **Instant Revocation & Data Deletion:** Users can turn off telemetry at any time in Settings (*Support & Info -> Anonyme Nutzungsstatistiken teilen*). Toggling the switch off immediately disables the PostHog SDK (`Posthog().disable()`). In addition, users can tap **"Telemetrie-Daten löschen"** directly in Settings (discreet `AppLinkRow` below the telemetry card). Triggering deletion issues `$delete_person` deletion requests to PostHog EU servers for all associated IDs before erasing local device UUIDs, clearing cached counters, and resetting PostHog SDK state (`Posthog().reset()`).
* **F-Droid Build Cleanliness:** F-Droid and offline-only builds compiled with `--dart-define=DISABLE_TELEMETRY=true` completely strip the PostHog SDK binary footprint. A zero-overhead `NoOpTelemetryService` stub replaces the telemetry pipeline entirely.

---

## 3. Systematic Anti-Profiling & Data Minimization Safeguards

To ensure that collecting aggregate statistics cannot be abused to profile individual users, Train Libre enforces strict architectural safeguards:

### A. The 2-ID Strategy & Per-Launch In-App ID Rotation
Traditional analytics SDKs link every screen view and action back to a single persistent user profile timeline. Train Libre decouples device launch metrics from in-app behavior:

| Event Category | Target Event | `distinct_id` | `$process_person_profile` | Isolation Safeguard |
| :--- | :--- | :--- | :--- | :--- |
| **App Launch (DAU/MAU)** | `app_launched` | Locally generated, random **Device UUID** (stored in `SharedPreferences`, NEVER derived from hardware IDFV or Android ID) | `false` | Sent via direct HTTP POST to PostHog EU API ONLY when opted in. PostHog counts unique active devices without linking app launch events to any in-app activity or screen views. |
| **Onboarding Funnel** | `onboarding_step_viewed`, `onboarding_completed`, `onboarding_abandoned` | **Ephemeral RAM UUID** (`onboarding_session_id`) | `false` | Generated in RAM at onboarding start and discarded immediately when onboarding finishes or exits. |
| **In-App Actions & Screens** | `screen_viewed`, `feature_used`, `workout_completed`, `setting_toggled`, `daily_food_logged` | **Ephemeral anonymous SDK ID** (rotated on every app launch) | `false` | Decoupled from the `app_launched` device UUID. Every app startup calls `Posthog().reset()`, which discards the stored anonymous ID so the native SDK mints a fresh one — events from different app launches cannot be linked to the same device. |

> **Why `reset()` and not `identify()`:** calling `identify()` marks the user as *identified*, and with PostHog's default `personProfiles: identifiedOnly` that is precisely the trigger for building a Person Profile. It also emits an `$identify` event, which is generated natively and therefore bypasses `beforeSend` entirely — arriving at PostHog with the real request IP and writing the resolved city, postal code and coordinates into `$set`/`$set_once` person properties. `reset()` achieves the same per-launch ID rotation while the user stays anonymous.

### B. Rageclick & Autocapture Suppression
Rage-click autocapture is **enabled by default in the native PostHog iOS SDK** and registers its own integration independently of `captureElementInteractions`. It emits `$rageclick` with raw `$touch_x` / `$touch_y` coordinates through a native channel that the Dart-side `beforeSend` cannot intercept. It is therefore switched off at the source:

```dart
config.rageClickConfig.enabled = false;   // requires posthog_flutter >= 5.36.0
```

The same reasoning applies to every other subsystem that emits its own native events, all of which are disabled in `PostHogConfig`: `sessionReplay`, `surveys`, `sendFeatureFlagEvents`, `preloadFeatureFlags`, `capturePushNotificationSubscriptions` and `capturePushNotificationOpened` (the last two default to `true` as of posthog_flutter 5.35.0 and would otherwise register device push tokens with PostHog). `beforeSend` additionally drops a deny-list of `$`-prefixed and survey events as defense in depth. No raw UI element text, touch coordinates, or view hierarchies are ever captured or transmitted.

### C. Person Profile Suppression
The SDK is configured with:
```dart
config.personProfiles = PostHogPersonProfiles.never;
```
and every telemetry payload additionally carries:
```json
"$process_person_profile": false
```
Together these instruct PostHog's backend **never to construct or update Person Profiles**, identity graphs, or user timelines. The single exception is the `$delete_person` request issued by "Telemetrie-Daten löschen": it deliberately omits `$process_person_profile` because person processing is the very step that carries out the deletion.

### D. Zero IP Logging & Country/World Map Analytics
To prevent PostHog from deriving user cities, regions, or postal codes (ZIP codes) from network request IP addresses, every payload carries **both** of the following:
```json
"$ip": "0.0.0.0",
"$geoip_disable": true
```
`$ip: "0.0.0.0"` alone is **not** sufficient — PostHog's server-side GeoIP transformation still resolves the real request IP unless `$geoip_disable` is set. Both are applied centrally: in `PostHogConfig.beforeSend` for everything captured through the SDK, and inline in the two direct HTTP payloads (`app_launched` and `$delete_person`).

To enable PostHog World Map visualizations and country breakdown insights without logging IP addresses, Train Libre resolves the user's system region/locale on the client side and attaches standard PostHog GeoIP country and continent metadata:
```json
"$geoip_country_code": "DE",
"$geoip_country_name": "Germany",
"$geoip_continent_code": "EU",
"$geoip_continent_name": "Europe",
"$locale": "de_DE"
```
Only country and continent are ever sent. City, subdivision, postal code, latitude, longitude and time zone are never populated.

### E. Aggregated Food Counters (`daily_food_logged`)
Rather than firing an event every single time a food entry is logged (which creates event spam and inflates infrastructure costs), Train Libre increments a local counter in `SharedPreferences`. When the app transitions to the background, a single aggregated `daily_food_logged` event is flushed (e.g., `count: 12`) and the SDK queue is flushed to the network.

Two implementation details matter for the accuracy of this counter:

* **Single choke point.** The increment lives in `DiaryLocalDataSource.insertFoodEntry`, the one method every logging path funnels through. Placing it in `NutritionRepository` instead would miss the majority of entries, because most screens call `DatabaseHelper.instance.insertFoodEntry` directly and bypass the repository.
* **Serialized read-modify-write.** Logging a saved meal or confirming an AI meal scan inserts every item in a tight loop, each firing an unawaited increment. Those increments are queued through a single-future lock; otherwise they interleave, several read the same starting value, and a five-item meal is recorded as one entry.

The flush is triggered from the app-root `AppLifecycleListener` in `main.dart`, so it also runs when the app is backgrounded from onboarding or any screen outside the tab shell.

---

## 4. What Is Strictly NOT Tracked

Train Libre enforces a strict zero-PII (Personally Identifiable Information) policy. **We NEVER track or transmit:**

* ❌ **No Names or Identifiers:** No user names, display names, email addresses, or account credentials.
* ❌ **No Personal Workout Data:** No custom workout titles, routine names, exercise names, or workout note text.
* ❌ **No Personal Nutrition Data:** No food names, brand names, custom recipe titles, calorie counts, or meal details.
* ❌ **No Body Measurements:** No body weight, height, waist size, body fat percentage, age, or gender.
* ❌ **No Location Data:** No GPS coordinates, IP addresses, city, state, country, or postal codes.

---

## 5. Complete Telemetry Event & Property Schema Catalog

### 1. App Launch & Uniqueness
* **`app_launched`** (Sent via Direct HTTP POST with `persistent_device_uuid`):
  * `$geoip_country_code` (PostHog native metadata string: e.g., `"DE"`, `"US"`)
  * `$locale` (PostHog native metadata string: e.g., `"de_DE"`, `"en_US"`)
  * `app_version` (string: e.g., `"1.0.0-beta.6"`)
  * `os_version` (string: e.g., `"iOS 17.5"`)
  * `platform` (string: `"ios"`, `"android"`, `"macos"`)
  * `locale` (string: e.g., `"de_DE"`, `"en_US"`)
  * `country` (string: 2-letter ISO code e.g., `"DE"`, `"US"`)
  * `install_source` (optional string)
  * Environment metadata mirroring the SDK's own events: `$app_build`, `$app_name`, `$app_version`, `$app_namespace`, `$device_type`, `$is_emulator`, `$lib`, `$lib_version`, `$os`, `$os_name`, `$os_version`, `$sent_at`, `$timezone`

  > Device manufacturer, model and name, plus the TestFlight/sideload flags, are **not** sent. They were previously guessed from `platform` and reported fabricated hardware (`"Apple"`/`"arm64"`/`"iPhone"` for every iOS device, `"Android"`/`"Mobile"` for every Android one), which polluted analytics with values no device actually had.

### 2. Onboarding Funnel
* **`onboarding_step_viewed`**:
  * `step_index` (int: `0` to `7`)
  * `step_name` (string: `"welcome"`, `"unit_system"`, `"region_selection"`, `"profile_basics"`, `"body_measurements"`, `"adaptive_goals"`, `"permissions_consent"`, `"completion"`)
  * `duration_seconds` (int: time spent on previous step)
  * `session_id` (ephemeral RAM UUID)
* **`onboarding_completed`**:
  * `total_duration_seconds` (int)
  * `restored_from_backup` (bool)
  * `session_id` (ephemeral RAM UUID)
* **`onboarding_abandoned`**:
  * `last_step_index` (int)
  * `last_step_name` (string)
  * `session_id` (ephemeral RAM UUID)

### 3. Screen Views (`screen_viewed`)
The closed set of values lives in `ScreenName` (`lib/services/telemetry/telemetry_service.dart`); call sites reference the constants rather than string literals.

* **`screen_viewed`**:
  * `screen_name` (string enum):
    * **Tabs:** `"workout_tab"`, `"diary_tab"`, `"analytics_tab"`, `"profile_tab"`, `"settings_tab"`
    * **Workout:** `"live_workout"`, `"routine_editor"`, `"routine_list"`, `"workout_summary"`, `"workout_history"`, `"workout_detail"`, `"exercise_catalog"`, `"exercise_detail"`, `"create_exercise"`
    * **Diary:** `"diary_day_view"`, `"nutrition_hub"`, `"meal_list"`, `"add_food_search"`, `"food_detail"`, `"create_food"`, `"ai_meal_capture"`, `"ai_meal_review"`, `"barcode_scanner"`, `"meal_editor"`, `"food_explorer"`
    * **Analytics:** `"statistics_hub"`, `"muscle_group_analytics"`, `"pr_dashboard"`, `"consistency_tracker"`, `"body_nutrition_correlation"`, `"recovery_tracker"`
    * **Health & Utilities:** `"body_measurements"`, `"goal_editor"`, `"pulse_overview"`, `"sleep_overview"`, `"steps_overview"`, `"supplements_overview"`, `"settings_main"`, `"ai_settings"`, `"data_management"`, `"about_app"`, `"legal_privacy"`, `"feedback_report"`

> **Reconciled against the app:** `"workout_overview"` was folded into `"workout_tab"` (same screen). `"cloud_backup"`, `"export_data"`, `"import_data"` and `"data_privacy_settings"` were replaced by the single `"data_management"` — backup, CSV export, import and local-data deletion all live on `DataManagementScreen`. `"fasting_tracker"` and `"qr_share"` were removed: the app has no fasting tracker, and routine sharing is text/image based with no QR screen. `"feedback_report"` was added; it was already being sent but was missing from the catalog.

### 4. Feature Triggers (`feature_used`)
The closed set of values lives in `FeatureKey` (`lib/services/telemetry/telemetry_service.dart`).

* **`feature_used`**:
  * `feature_key` (string): `"routine_created"`, `"routine_started"`, `"routine_shared"`, `"workout_imported"`, `"custom_exercise_created"`, `"barcode_scanned"`, `"custom_food_created"`, `"recipe_created"`, `"supplement_logged"`, `"body_measurement_logged"`, `"apple_health_exported"`, `"health_connect_exported"`, `"json_backup_created"`, `"json_backup_restored"`, `"icloud_sync_triggered"`, `"csv_exported"`, `"app_tour_started"`, `"app_tour_completed"`

> **Reconciled against the app:** `"routine_shared_qr"` became `"routine_shared"` — sharing goes through `ShareService`'s text/image sheet, there is no QR flow. `"routine_scanned_qr"` was replaced by `"workout_imported"` (CSV/XLSX import via `ImportManager`). `"fasting_timer_started"`, `"fasting_timer_completed"` and `"plate_calculator_used"` were removed: neither a fasting timer nor a plate calculator exists in the app.
>
> Keys whose event can fire from several screens are tracked at their data-layer choke point (`recipe_created`, `supplement_logged`, `body_measurement_logged`, `json_backup_created`, `json_backup_restored`, `csv_exported`) so no call site can bypass them. `icloud_sync_triggered` is tracked when the user enables iCloud sync or triggers a manual backup ("Backup Now"); automatic background syncs perform zero telemetry tracking.

### 5. Aggregated Food Logging (`daily_food_logged`)
* **`daily_food_logged`**:
  * `count` (int: number of food items logged since the last flush)
  * `sources` (list of strings, closed set from `FoodLogSource`): `"manual_search"` (search / favourites / recents), `"barcode_scan"`, `"ai_capture"` (AI meal scanner), `"meal"` (saved meal or recipe logged in bulk)

### 6. Workout Completion (`workout_completed`)
* **`workout_completed`**:
  * `workout_type` (string: `"routine"` or `"custom"` ONLY)
  * `exercise_count` (int)
  * `set_count` (int)
  * `duration_minutes` (int)
  * `has_rest_timer` (bool)
  * `rest_timer_count` (int)
  * `has_rir` (bool)
  * `rir_sets_count` (int)
  * `has_supersets` (bool)
  * `superset_count` (int)
  * `has_warmup_sets` (bool)
  * `has_drop_sets` (bool)
  * `has_failure_sets` (bool)
  * `used_plate_calculator` (bool — reserved; the app has no plate calculator yet, so this is always `false`)
  * `has_workout_notes` (bool)

`workout_type` is coerced to `"routine"` or `"custom"` in `trackWorkoutCompleted` before it is sent, so a user-authored routine title can never leak through this field.

### 7. Settings Changes (`setting_toggled`)
* **`setting_toggled`**:
  * `setting_key` (string: e.g., `"unit_system"`, `"telemetry_opt_in"`, `"dark_mode_option"`, `"icloud_sync_enabled"`, `"ai_provider_selected"`, `"apple_health_export_enabled"`, `"pulse_tracking_enabled"`)
  * `value` (dynamic)

### 8. System, Algorithm & Voluntary Feedback
* **`recommendation_generated`** (Anonymized TDEE metrics, ZERO PII):
  * `weight_log_count` (int: number of weight entries in Bayesian window)
  * `intake_logged_days` (int: number of logged nutrition days in window)
  * `window_days` (int: e.g., `14` or `28`)
  * `effective_sample_size` (double: e.g., `3.5`)
  * `has_slope` (bool)
  * `has_intake` (bool)
  * `confidence` (string enum: `"notEnoughData"`, `"low"`, `"medium"`, `"high"`)
  * `confidence_score_bucket` (string enum: `"0.00-0.25"`, `"0.25-0.50"`, `"0.50-0.75"`, `"0.75-1.00"`)
  * `warning_level` (string enum: `"none"`, `"moderate"`, `"high"`)
  * `quality_flags` (list of strings: e.g., `["bayesian_recursive_filter", "bayesian_intake_unavailable"]`)
  * `is_prior_only` (bool)

* **`feedback_report_submitted`** (Voluntary Diagnostic Feedback):
  * `included_sections` (list of strings: e.g., `["adaptive_nutrition", "backup_restore", "user_note"]`)
  * `has_user_note` (bool)
  * `user_note_length` (int — the length only; the note text itself is never transmitted)
  * `submission_method` (string: `"posthog_direct"`, `"email"`, `"copied"`, `"shared"`, `"saved_file"`)
  * `diag_*` — diagnostic state parsed from the report preview: counters (`diag_input_weight_log_count`, `diag_input_intake_logged_days`, `diag_input_window_days`), confidence and warning levels, quality flags, estimator/phase/prior state strings, backup status and due-date keys.

  **Excluded by `_isSensitiveDiagnosticKey`:** any key carrying a body measurement or a nutrition quantity — `diag_latest_logged_weight_kg`, `diag_input_weight_reference_kg`, `diag_*_kcal`, `diag_*_protein_g` / `_carbs_g` / `_fat_g`, `diag_*maintenance*`, `diag_target_rate_kg_per_week` and anything else matching `weight` / `_kg` / `kcal` / `calorie` / `protein` / `carbs` / `fat` / `maintenance` (pure `*_count` and `*_days` keys are kept, since a count reveals no measured value). The user-authored note is never added to the map at all.

  The full report — including weight, calorie and macro figures and the note verbatim — is still available through the **email, share, copy and file-export** actions. Those go directly to the developer under the user's own control and do not pass through PostHog. Direct submission additionally requires telemetry to be switched on; if it is off the app says so instead of reporting a delivery that did not happen.

* **`ai_meal_scan_requested`**: `request_id`, `provider`
* **`ai_meal_scan_completed`**: `request_id`, `provider`, `latency_bucket`, `success`, `error_code`
* **`db_migration_status`**: `from_version`, `to_version`, `success`

---

## 6. Data Processor & Infrastructure

* **Telemetry Service Provider:** PostHog, Inc. (San Francisco, CA, USA)
* **Data Storage Host:** PostHog EU (`https://eu.i.posthog.com`), hosted on AWS `eu-central-1` (Frankfurt am Main, Germany). All primary telemetry data remains in the European Union.
* **GDPR Legal Basis:** Art. 6(1)(a) GDPR (Explicit User Consent).
* **Data Processing Agreement (DPA):** Executed under Art. 28 GDPR with PostHog, Inc. Technical support transfers are protected under the EU-US Data Privacy Framework (DPF).
* **Retention Period:** Telemetry data is automatically erased from PostHog EU servers after 12 months.
