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
* **No Pre-Consent Tracking:** Zero telemetry events (including `app_launched`) are transmitted before a user explicitly opts in via the onboarding setup screen or Settings.
* **Instant Revocation:** Users can turn off telemetry at any time in Settings (*Support & Info -> Anonyme Nutzungsstatistiken teilen*). Toggling the switch off immediately disables the PostHog SDK (`Posthog().disable()`) and halts all network transmissions.
* **F-Droid Build Cleanliness:** F-Droid and offline-only builds compiled with `--dart-define=DISABLE_TELEMETRY=true` completely strip the PostHog SDK binary footprint. A zero-overhead `NoOpTelemetryService` stub replaces the telemetry pipeline entirely.

---

## 3. Systematic Anti-Profiling & Data Minimization Safeguards

To ensure that collecting aggregate statistics cannot be abused to profile individual users, Train Libre enforces strict architectural safeguards:

### A. The 2-ID Strategy (Isolating DAU/MAU from In-App Activity)
Traditional analytics SDKs link every screen view and action back to a single persistent user profile timeline. Train Libre decouples device launch metrics from in-app behavior:

| Event Category | Target Event | `distinct_id` | `$process_person_profile` | Isolation Safeguard |
| :--- | :--- | :--- | :--- | :--- |
| **App Launch (DAU/MAU)** | `app_launched` | Locally generated, random **Device UUID** (stored in `SharedPreferences`, NEVER derived from hardware IDFV or Android ID) | `false` | Sent via direct HTTP POST to PostHog EU API. PostHog counts unique active devices without linking app launch events to any in-app activity or screen views. |
| **Onboarding Funnel** | `onboarding_step_viewed`, `onboarding_completed`, `onboarding_abandoned` | **Ephemeral RAM UUID** (`onboarding_session_id`) | `false` | Generated in RAM at onboarding start and discarded immediately when onboarding finishes or exits. |
| **In-App Actions & Screens** | `screen_viewed`, `feature_used`, `workout_completed`, `setting_toggled`, `daily_food_logged` | **Ephemeral SDK ID** (reset after launch) | `false` | Decoupled from `app_launched` device UUID. Events appear as un-linked aggregate data points. |

### B. Person Profile Suppression
Every telemetry payload sent to PostHog includes:
```json
"$process_person_profile": false
```
This instructs PostHog's backend **never to construct or update Person Profiles**, identity graphs, or user timelines.

### C. IP & Geolocation Scrubbing
To prevent PostHog from deriving user cities, regions, or postal codes (ZIP codes) from network request IP addresses, all payloads include:
```json
"$ip": "0.0.0.0",
"$geoip_disable": true
```
PostHog records all location properties as `(none)` / `Unknown`.

### D. Daily Aggregated Counters (`daily_food_logged`)
Rather than firing an event every single time a food entry is logged (which creates event spam and inflates infrastructure costs), Train Libre increments a local counter in `SharedPreferences`. When the app transitions to the background (`AppLifecycleState.paused`), a single aggregated `daily_food_logged` event is flushed (e.g., `count: 12`).

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
  * `app_version` (string: e.g., `"1.0.0-beta.6"`)
  * `os_version` (string: e.g., `"iOS 17.5"`)
  * `platform` (string: `"ios"`, `"android"`, `"macos"`)
  * `locale` (string: e.g., `"de_DE"`, `"en_US"`)
  * `install_source` (optional string)

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
* **`screen_viewed`**:
  * `screen_name` (string enum):
    * **Tabs:** `"workout_tab"`, `"diary_tab"`, `"analytics_tab"`, `"profile_tab"`, `"settings_tab"`
    * **Workout:** `"workout_overview"`, `"live_workout"`, `"routine_editor"`, `"workout_summary"`, `"exercise_catalog"`, `"exercise_detail"`, `"create_exercise"`
    * **Diary:** `"diary_day_view"`, `"add_food_search"`, `"food_detail"`, `"create_food"`, `"ai_meal_capture"`, `"ai_meal_review"`, `"barcode_scanner"`, `"meal_editor"`, `"food_explorer"`, `"fasting_tracker"`
    * **Analytics:** `"statistics_hub"`, `"muscle_group_analytics"`, `"pr_dashboard"`, `"consistency_tracker"`, `"body_nutrition_correlation"`, `"recovery_tracker"`
    * **Health & Utilities:** `"body_measurements"`, `"goal_editor"`, `"pulse_overview"`, `"sleep_overview"`, `"steps_overview"`, `"supplements_overview"`, `"settings_main"`, `"ai_settings"`, `"cloud_backup"`, `"export_data"`, `"import_data"`, `"data_privacy_settings"`, `"about_app"`, `"legal_privacy"`, `"qr_share"`

### 4. Feature Triggers (`feature_used`)
* **`feature_used`**:
  * `feature_key` (string): `"routine_created"`, `"routine_started"`, `"routine_shared_qr"`, `"routine_scanned_qr"`, `"custom_exercise_created"`, `"barcode_scanned"`, `"custom_food_created"`, `"recipe_created"`, `"fasting_timer_started"`, `"fasting_timer_completed"`, `"body_measurement_logged"`, `"json_backup_created"`, `"json_backup_restored"`, `"icloud_sync_triggered"`, `"csv_exported"`, `"apple_health_exported"`, `"health_connect_exported"`, `"app_tour_started"`, `"app_tour_completed"`, `"supplement_logged"`, `"plate_calculator_used"`

### 5. Daily Aggregated Food Logging (`daily_food_logged`)
* **`daily_food_logged`**:
  * `count` (int: number of food items logged on that day)
  * `sources` (list of strings: e.g., `["barcode_scan", "manual_search", "ai_capture"]`)

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
  * `used_plate_calculator` (bool)
  * `has_workout_notes` (bool)

### 7. Settings Changes (`setting_toggled`)
* **`setting_toggled`**:
  * `setting_key` (string: e.g., `"unit_system"`, `"telemetry_opt_in"`, `"dark_mode_option"`, `"icloud_sync_enabled"`, `"ai_provider_selected"`, `"apple_health_export_enabled"`, `"pulse_tracking_enabled"`)
  * `value` (dynamic)

### 8. System & AI Stability
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
