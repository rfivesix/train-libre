# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).


## [1.0.0-beta.8] - 2026-08-03

### Added
- **Cross-Platform Workout Rest Timer Audio Output:** Configured `SoundService` (`sound_service.dart`) to play the custom audio asset (`assets/sounds/timer_done.mp3`) via `AudioPlayer` on all mobile platforms (iOS and Android), bypassing mobile-ignored `SystemSound.play` and routing audio directly through headphones, AirPods, or media speakers.
- **Glass Bottom Sheet `headerTrailing` Action Support:** Extended `showGlassBottomMenu` (`glass_bottom_menu.dart`) to support a custom `headerTrailing` widget rendered top-right in the sheet header, identical to the date/time picker headers.
- **Workout Rest Timer "Timer entfernen" Header Action:** Replaced the full-width bottom red button in `RoutinePauseTimeDialog` with a subtle top-right action ("Timer entfernen" / "Remove Timer") in the modal sheet header of `live_workout_screen.dart` and `edit_routine_screen.dart`, perfectly matching the date/time picker's "Heute" / "Jetzt" layout.

### Fixed
- **iOS Audio Category & Native Plugin Rebuild Fix:** Resolved `AVAudioSessionCategory` assertion in `SoundService` by configuring `AVAudioSessionCategory.playback` with `mixWithOthers` and `duckOthers`. Handled `MissingPluginException` gracefully when a full app restart/rebuild is pending for native plugin compilation.
- **Diary Initial Date Night Cutoff:** Updated `resolveDiaryInitialDate` (`diary_view_model.dart`) so that opening the diary before 03:00 AM automatically defaults the selected date to yesterday instead of today.
- **Workout Session Rest Timer Persistence in SQLite:** Fixed a critical issue in `workout_logging_queries.dart` (`updateSetLogs`) where `restTimeSeconds` was omitted from the `SetLogsCompanion` database query. When updating set logs during a workout, `rest_time_seconds` was left untouched in SQLite, causing rest timer values to reset to 0/default upon app restart.
- **Exercise Catalog Category Filter Dropdown:** Replaced modal bottom sheet filter menu in `ExerciseCatalogScreen` (`exercise_catalog_screen.dart`) with the app's native glass context popup dropdown (`PlatformAdaptivePopupMenu`). Clicking the filter icon now opens an inline liquid glass dropdown menu directly below the filter button, displaying category items with active checkmarks for instant filtering without opening a full-screen bottom sheet.
- **Supplement Quick Selection Sheet Layout:** Removed redundant leading pill icons (`LucideIcons.pill`) from the quick selection list tiles in `LogSupplementMenu` (`log_supplement_menu.dart`) for a cleaner, streamlined list view.

### Fixed
- **Glass Bottom Sheet Keyboard Max-Height Bound:** Corrected `maxAvailableHeight` calculation in `showGlassBottomMenu` (`glass_bottom_menu.dart`) and `_GlassPickerSheet` (`platform_adaptive_pickers.dart`) by subtracting `keyboardInset` (`viewInsets.bottom`). When the soft keyboard opens while editing complex forms (such as adding/editing fluid entries), the sheet height is now capped strictly below the top status bar / Dynamic Island, ensuring full scrollability without overflowing off-screen.
- **Liquid Glass Bottom Sheet Keyboard Extension:** Overhauled the keyboard transition in `showGlassBottomMenu` (`glass_bottom_menu.dart`) and `_GlassPickerSheet` (`platform_adaptive_pickers.dart`). Replaced negative padding with a non-clipping `Stack` extension that positions an `AdaptiveGlass` backdrop (`bottom: -keyboardInset`). The real liquid glass effect, saturation tint, and backdrop filters now extend continuously down behind the iOS/Android keyboard without triggering Flutter framework assertions or breaking glass optics.

## [1.0.0-beta.7] - 2026-08-01

### Fixed
- **Nutrition Hub Recipe Cards Visual Mismatch:** Fixed visual clipping, height mismatch (changed from 150px to 160px), missing drop shadows, and `clipBehavior` in `NutritionHubScreen` (`nutrition_hub_screen.dart`), restoring exact 1:1 visual parity with "Meine Pläne" cards in `WorkoutHubScreen`.

### Changed
- **Main Navigation Dock & Floating Action Button (FAB) Lowering:** Adjusted the bottom position and vertical padding across all Floating Action Buttons (`GlassFab`). Fixed the total bottom offset of `_LiveWorkoutFab` in `LiveWorkoutScreen` (`live_workout_screen.dart`) to `92.0px` (`12.0px outer padding + 8.0px inner margin + 64.0px rest bar height + 8.0px gap`) when the rest timer bar is active, resolving an overlapping visual bug and restoring the exact 8.0px vertical gap above the rest bar. Lowered standalone custom FAB overlays (`EditRoutineScreen`) from `24px` to `12px` base bottom margin to sit lower and consistent across all product screens.
- **Solid Saturated Brand Lime Rest Completion Banner:** Updated the rest completion banner in `LiveWorkoutScreen` (`live_workout_screen.dart`) to render 100% solid (0% transparency, `glassColor: DesignConstants.brandAccentColor`, `blur: 0.0`) in both Dark and Light modes, completely obscuring any background content behind the pill.
- **Centralized Data Source Attribution (Open Food Facts & wger):** Removed individual floating and inline `OffAttributionWidget` and `WgerAttributionWidget` overlays from product screens (`AddFoodScreen`, `FoodDetailScreen`, `FoodExplorerScreen`, `GeneralFoodSelectionScreen`, `ExerciseCatalogScreen`, `ExerciseDetailScreen`, `EditRoutineScreen`, `LiveWorkoutScreen`, `WorkoutLogDetailScreen`) to clean up screen layouts and eliminate UI clutter. Consolidated all Open Food Facts (ODbL 1.0) and wger (CC-BY-SA) attribution links into standard `AppLinkRow` list items with `LucideIcons.external_link` trailing icons under the **Attribution** section inside `AboutScreen` (`about_screen.dart`), matching the native look of the rest of the screen.

## [1.0.0-beta.6] - 2026-07-31

### Changed
- **Data-Minimizing & Zero-Profiling Telemetry Architecture (PostHog EU):** Overhauled `TelemetryService` and `PostHogTelemetryService` to enforce strict data minimization, zero profiling (`$process_person_profile: false`), and complete IP/location scrubbing (`$ip: '0.0.0.0'`, `$geoip_disable: true`). Implemented a **2-ID strategy** (Option B direct HTTP POST to PostHog EU for `app_launched` with persistent device UUID for accurate DAU/MAU counting without user profiling or in-app event correlation). Added ephemeral RAM session UUIDs for onboarding funnel tracking (`onboarding_step_viewed`, `onboarding_completed`, `onboarding_abandoned`), daily aggregated food logging counter (`daily_food_logged`), comprehensive screen view tracking (`screen_viewed`), feature usage triggers (`feature_used`), settings toggles (`setting_toggled`), and anonymized workout subfeature metrics (rest timer, RIR, supersets, warmup/drop/failure set flags, plate calculator).
- **iOS Liquid Glass Optics & Backdrop Vignette Architecture:** Overhauled application-wide glassmorphic styling and shadow hierarchy. Replaced hard artificial drop shadows (`glassShadow`) across floating buttons (`GlassFAB`, `RunningWorkoutOverlay`, rest timer bar) with clean background vignette gradients (`DesignConstants.bottomVignetteGradient`). Implemented soft, exponential fade-out vignettes for top (`GlobalAppBar`) and bottom navigation overlays (pure dark in Dark Mode, subtle off-white/cool grey tint in Light Mode), reaching 100% solid opacity right at the outer screen boundary while preserving translucency directly behind floating UI components. Unified all floating glass widgets (`GlassFab`, `live_workout_screen.dart` rest timer overlays) to use `GlassContainer` with `DesignConstants.liquidGlassSettings(isDark)` for 1:1 identical optics with `GlassTabBar`.
- **Open Food Facts Attribution Layer Fix:** Updated `FoodExplorerScreen` (`food_explorer_screen.dart`) layout to hide bottom vignette gradients in empty initial states and position `OffAttributionWidget` cleanly above the vignette layer with proper bottom padding (`96.0`), preventing text overlap with floating buttons.

- **Liquid Glass Widgets Upgrade (v0.24.1):** Upgraded `liquid_glass_widgets` dependency from `0.22.1` to `0.24.1` (PR #536).
- **Navigation Dock Capsule Radius Fix:** Updated `GlassTabBar.bottom` in `main_screen.dart` to use `GlassDefaults.capsuleRadius` for both `barBorderRadius` and `indicatorBorderRadius`, restoring smooth capsule indicator geometry in the bottom navigation dock.
- **Flicker-Free Food Search UI Transition:** Updated `FoodExplorerScreen` (`food_explorer_screen.dart`) and `AddFoodScreen` (`add_food_screen.dart`) so that previous search result lists remain visible without loading indicator flickering while typing subsequent query characters.
- **Bottom Vignette Shadow im Lebensmittel-Explorer:** `AddFoodScreen` (`add_food_screen.dart`) fehlte der weiche Gradient-Schatten am unteren Bildschirmrand. Den `body` in einen `Stack` gewrapped und ein `Positioned`-Overlay mit `DesignConstants.bottomVignetteGradient` ergänzt, konsistent mit `main_screen` und `live_workout_screen`.
- **OFF Attribution Widget als schwebendes Overlay:** `OffAttributionWidget` in `AddFoodScreen` aus den einzelnen Tabs (wo es einen schwarzen Balken erzeugte) entfernt und als einziges `Positioned`-Overlay über dem Gradient-Schatten platziert — analog zum `WgerAttributionWidget` im `live_workout_screen`. Text-Schatten für Lesbarkeit über dem Gradient ergänzt.

### Performance
- **Nutrition Hub Meal-Card Scroll Jank Fixed:** Eliminated scroll stuttering in `NutritionHubScreen` when recipe/meal cards were visible. Root causes: (1) `clipBehavior: Clip.none` on the horizontal `ListView.builder` prevented Flutter from discarding compositing layers for off-screen cards – changed to `Clip.hardEdge`. (2) Per-card `RepaintBoundary` + `BoxShadow` (via `SummaryCard`) triggered expensive offscreen compositing on every frame during outer-list scrolling – removed per-card boundaries (a single boundary around the whole horizontal section suffices) and set `disableShadow: true` on meal cards inside the list.
- **Sleep & Workout Calculations Optimization:** Optimized regularity calculator, workout routine delta detection, and sleep chart bounds calculations to use lazy Iterables, single-pass O(N) loops, and HashMaps, significantly reducing garbage collection pressure and main thread jank (PR #537, PR #540, PR #542).

### Removed
- **Repeat Onboarding Setting Removed:** Removed the "Anleitung erneut anzeigen" / "Onboarding wiederholen" option from `SettingsScreen` (`settings_screen.dart`).

### Added
- **Brand-Aware Food Search & Ranking Algorithm:** Enhanced `ProductLocalDataSource.searchProducts`, `getBaseFoods`, `EvaluateFoodSourceUseCase`, and repair fuzzy matching to incorporate product brand names (`p.brand`) directly into search token matching and text-relevance scoring. Search queries combining brand and product names in any order (e.g., "Rewe Magerquark" or "Apfelmus Kaufland Bio") now accurately match and rank relevant brand products at the top.
- **Global Liquid Glass Context Menu & Actionable Cards (`GlassActionableCard` & `GlassContextMenuOverlay`):** Added a global, highly accessible wrapper widget (`GlassActionableCard`) and iOS / WhatsApp-style context menu overlay (`GlassContextMenuOverlay`) for summary cards and item tiles across Train Libre. Supports long-press focused element elevation, 120Hz Liquid Glass backdrop blur, smooth micro-animations, haptic feedback (`HapticFeedbackService`), and semantic screen reader actions (`Semantics(customActions: ...)`). Integrated across Diary food & fluid tiles (`FoodEntryTile`, `FluidEntryTile`), Workout routines (`RoutinesScreen`), Workout History logs (`WorkoutHistoryScreen`), Supplement catalog (`SupplementHubScreen`), and Body measurement sessions (`MeasurementsScreen`). Eliminates shadow bleed artifacts and GPU blur shader re-compilation jank.
- **Comprehensive English Telemetry Documentation (`TELEMETRY.md`):** Added a dedicated root documentation file detailing Train Libre's telemetry rationale, opt-in consent model, anti-profiling & 2-ID safeguards, zero-PII policies, and complete event schema catalog (`app_launched`, `onboarding_*`, `screen_viewed`, `feature_used`, `daily_food_logged`, `workout_completed`, `setting_toggled`).
- **Accessibility Tooltips:** Added missing localized tooltips to interactive IconButtons across live workout, superset header, AI settings, and data management screens for improved screen reader support (PR #538, PR #539, PR #541).


## [1.0.0-beta.5] - 2026-07-26

### Added
- **Opt-in Anonymous Telemetry & F-Droid Cleanliness Architecture:** Implemented a privacy-first, opt-in `TelemetryService` using PostHog EU (`https://eu.i.posthog.com`) with zero PII capture. Added an abstract `TelemetryService` interface with `NoOpTelemetryService` (stub for F-Droid and disabled builds using `--dart-define=DISABLE_TELEMETRY=true`) and `PostHogTelemetryService`. Added a user-facing toggle switch ("Anonyme Nutzungsstatistiken teilen") in Settings under *Support & Info* next to Feedback (default `false`). Instrumented anonymous, coarse-bucketed events for app launches (`app_launched`), completed workouts (`workout_completed`), AI meal image scans (`ai_meal_scan_requested` / `ai_meal_scan_completed`), and database schema upgrades (`db_migration_status`).
- **Onboarding Optional Telemetry Consent Checkbox:** Added a second, optional checkbox (`i_agree_to_optional_telemetry`) to the Onboarding Consent Screen (`initial_consent_screen.dart`), allowing users to explicitly opt into anonymous usage telemetry directly upon initial launch. The checkbox is unchecked by default and does not block onboarding progress.
- **Legal Update Re-Consent Architecture (v1.6):** Implemented automatic re-consent enforcement when Privacy Policy or Terms of Service are updated to a new version (e.g. `kCurrentLegalVersion = '1.6'`). Created `LegalUpdateConsentScreen` (`legal_update_consent_screen.dart`), featuring localized version update notices, direct link to full terms, mandatory updated privacy policy consent checkbox, and pre-filled optional telemetry toggle. Updated `main.dart` startup routing to check `acceptedLegalVersion` before launching main app initializers, ensuring zero data processing or telemetry occurs until updated terms are accepted.

### Changed
- **Privacy Policy & Legal Screen Telemetry Disclosure Update:** Updated the official Privacy Policy in both German and English across legal presentation screens (`legal_screen.dart`) and root asset documentation (`privacy_policy_de.md`, `privacy_policy_en.md`) to **Version 1.6** (dated **27. Juli 2026**). Added Section 6.C (*"Optionale anonyme Telemetrie"* / *"Optional Anonymous Telemetry"*) detailing PostHog EU host disclosures, strict default opt-in status, zero PII transmission, coarse aggregated metric bucketing, instant consent revocation, legal basis under GDPR Art. 6(1)(a), data processor status under GDPR Art. 28 (PostHog, Inc. DPA), storage location & 12-month retention in AWS `eu-central-1` (Frankfurt, Germany) with EU-US Data Privacy Framework (DPF) safeguards, and telemetry data subject rights under Section 7.
- **Privacy & Analytics Claims Alignment:** Conducted a comprehensive audit across `README.md`, website pages (`docs/index.html`, `docs/privacy.html`, `docs/privacy-policy/`), Impressum (`docs/impressum.md`), and app legal screens (`legal_screen.dart`). Updated marketing claims from absolute statements like *"without analytics SDKs"* or *"Keine Tracking- oder Analyse-SDKs"* to precise, transparent phrasing (*"Kein kommerzielles Tracking / Optionale anonyme Telemetrie"* / *"No Commercial Tracking (Optional Anonymous Telemetry)"*), accurately reflecting the opt-in `posthog_flutter` integration while highlighting the absence of advertising networks, commercial profiling, or mandatory tracking.
- **Automatic Multilingual AI Meal Recognition & Language Setting Cleanup:** Removed manual "Sprache für KI-Lebensmittelnamen" (`settingsAiFoodNameLanguage`) dropdown setting from `AiSettingsScreen` (`ai_settings_screen.dart`). Overhauled `AiMatchingLanguageService` to resolve `AiMatchingContext` automatically based on app UI locale (`appLanguage`) and active Open Food Facts catalog region (`catalogLanguage`). Updated AI system prompts in `ai_prompts.dart` to instruct AI models to output primary food component names in the app UI language while providing secondary `catalogSearchTerm` keywords in the catalog language when analyzing food in foreign catalog regions (e.g., German UI app used with French OFF catalog). Updated `ProductLocalDataSource.fuzzyMatchForAi` and `AiMealValidationEngine` to perform multi-lingual candidate lookups across base foods and regional OFF databases.

### Performance
- **Background Isolate AI Payload Parsing:** Offloaded synchronous `jsonDecode()` calls for AI meal candidate and item parsing in `AiService` (`ai_parsing.dart`) to background isolates using `Isolate.run()`, preventing main UI thread frame drops when parsing large AI payloads.
- **Drift Database Indexing & Query Optimization:** Added `@TableIndex(name: 'idx_nutrition_consumed_at', columns: {#consumedAt})` and `@TableIndex(name: 'idx_fluid_consumed_at', columns: {#consumedAt})` index annotations to `NutritionLogs` and `FluidLogs` tables in `drift_database.dart`, accelerating date-range queries across diary views.
- **Nutrition Hub Recipes 120Hz Scroll Optimization:** Fixed micro-stuttering and GPU frame drops when scrolling past the "Meine Rezepte" ("My recipes") section on 120Hz ProMotion displays in `NutritionHubScreen` (`nutrition_hub_screen.dart`). Updated recipe card buttons to reuse `AppButton.primary` with `AppButtonSize.medium` (matching the Workout Hub routine card structure and primary lime styling) and isolated section cards and horizontal recipe items with `RepaintBoundary` wrappers to cache rasterized textures and eliminate GPU frame drops during scroll.
- **Food Search Rendering Optimization:** Optimized food item search rendering in `AddFoodScreen` (`add_food_screen.dart`) by replacing multiple `.where()` list traversals with a single-pass loop, reducing list traversal complexity from $O(3N)$ to $O(N)$ and eliminating intermediate array allocations (PR #535).

### Fixed
- **AI Capture Fallback Error Handling:** Added a generic `catch (e)` fallback handler in `AiMealCaptureScreen._analyze()` (`ai_meal_capture_screen.dart`) to present user-friendly error SnackBars on unexpected exceptions instead of experiencing a silent loading freeze.
- **User-Facing Exception Text Cleanup:** Replaced raw `$e` exception stacktrace strings in `meal_editor_screen.dart` with clean, localized error text while preserving `debugPrint()` diagnostic logs for development.
- **Manager Error Logging:** Added explicit `debugPrint()` logging inside catch blocks across `backup_manager.dart` to prevent silent error swallowing during auto-backups and CSV exports.
- **Diary Date-Switch Flicker Eliminated:** Implemented stale-while-revalidate pattern in `DiaryViewModel`. Removed `isLoading = true` and `notifyListeners()` from `setSelectedDate()` — the UI now keeps the previous day's content fully rendered and stable while the new date's stream subscriptions resolve in the background. The date arrow/header still updates immediately via `ValueNotifier`. A single atomic `notifyListeners()` in `_executeCalculatedState()` swaps all content to the new date at once, with no intermediate skeleton or flicker.

### Accessibility & Theme Consistency
- **Touch Target Standard Compliance:** Increased button touch target dimensions in `add_food_screen.dart` (search field action buttons) and `diary_screen.dart` (`_compactIconButton`) to meet the minimum 48x48 dp Material / Apple HIG accessibility standard.
- **Animated Progress Bars:** Converted `GlassProgressBar` from a `StatelessWidget` to a `StatefulWidget` that uses `TweenAnimationBuilder` to smoothly tween both the fill bar width and the displayed numeric value whenever they change (350 ms, `easeOutCubic`). This means all macro bars (calories, water, protein, carbs, fat, sugar, fiber, salt, caffeine), supplement goal bars, and the steps card bar animate fluidly on every value update — including the atomic date-switch content swap.
- **Cardio Metric Localization:** Extracted remaining hardcoded metric strings (`Distance`, `Duration`, `Pace`) in `exercise_detail_screen.dart` to `app_en.arb` (`exerciseMetricDistance`, `exerciseMetricDuration`, `exerciseMetricPace`) and `app_de.arb`.
- **Theme ColorScheme Consistency:** Replaced direct `Colors.black` and `Colors.white` references with `Theme.of(context).colorScheme` tokens in `main_screen.dart` and `scanner_screen.dart`.


## [1.0.0-beta.4] - 2026-07-26

### Added
- **Blocking Import Overlay & Duplicate Workout Skipping:** Added `LongRunningOperationOverlay.run()` modal glass loading screen during CSV workout imports in `data_management_screen.dart`, blocking interactions until import completes. Added automatic duplicate workout skipping in `import_manager.dart` by matching workout `startTime` timestamps against existing database logs, skipping already imported workouts and providing feedback (*"0 neue Workouts importiert (alle existierten bereits)"*).

### Changed
- **Settings Screen App Tour Option Cleanup:** Removed the "App Tour neu starten" navigation card tile and its handler from `SettingsScreen` per user request.
- **Live Workout Contextual Exercise Insertion:** Updated exercise addition logic in `LiveWorkoutViewModel.addExercise()` so newly added exercises are inserted immediately after the lowest exercise in the active workout that has at least one completed set (`isCompleted == true`), matching real-world gym workflow. Automatically synchronizes `logOrder` database sequence. If no sets are completed yet, exercises append to the end as before.
- **Statistics Hub Section Reordering:** Reordered the main sections in `StatisticsHubScreen` so that **Körper (Body)** (Body metrics & measurements) is positioned directly between **Erholung (Recovery)** and **Training** (Consistency, Performance PRs, Muscle Volume), prioritizing body composition metrics higher up the dashboard layout.
- **Exercise Mapping 1-Tap Pill Selection:** Enhanced `exercise_mapping_screen.dart` to automatically pre-select top fuzzy search matches for unlinked imported exercises and render alternative recommendations as interactive 1-tap `GlassPillButton` elements with selection checkmarks. Users can confirm or switch exercise mappings with 1 tap. Retained persistent access to "Übungen zuordnen" in Settings under *Data Management* for ongoing exercise mapping.
- **Exercise Search & Fuzzy Matching Overhaul:** Overhauled exercise lookup (`getExerciseByName`) and search (`searchExercises`) in `exercises_queries.dart`. Added automatic parenthetical equipment qualifier stripping (e.g., `(Maschine)`, `(Langhantel)`, `(Kurzhantel)`), a 3-pass multi-tier search engine (strict `AND` -> sanitized base-name -> flexible `OR` with synonym expansion for `KH`/`LH`, `Beinstrecken`/`Beinstrecker`, `Wadendrücken`/`Wadenheben`, `Squat`/`Kniebeuge`, etc.), and automatic high-confidence linking during CSV import. Updated `exercise_mapping_screen.dart` to automatically pre-select top fuzzy search matches for unknown imported exercises, providing instant 1-tap mapping.
- **App Store Rating Flow & 2-Step Glass Bottom Sheet:** Updated `AppReviewService` rating prompt threshold from 7 days of usage down to 3 days after initial app launch. Replaced unprompted background review trigger with an interactive 2-step `showGlassBottomMenu` dialog asking "Gefällt dir Train Libre?". Selecting "Ja, gefällt mir" triggers native `in_app_review` rating prompt and marks prompt as completed; selecting "Nein, nicht wirklich" dismisses the menu and marks prompt completed to prevent low ratings on the App Store; selecting "Erinnere mich später" snoozes the rating prompt for 7 days.
- **Onboarding Legal & Consent Screen (GDPR & Clickwrap UX):** Streamlined initial consent UI in `initial_consent_screen.dart`. Removed separate Terms of Service checkbox in favor of an inline Clickwrap agreement statement below the main action button (*"By tapping 'Accept & Get Started', you agree to our Terms of Service and acknowledge our Privacy Policy"*). Retained single explicit consent checkbox required under GDPR Art. 9 with purpose-specific wording (*"I explicitly consent to the processing of my fitness and health data for workout tracking and training insights. I can withdraw my consent at any time in Settings"*), enabling the primary action button once checked. Refined the introduction text to be informative rather than claiming blanket consent. Fixed checkmark icon contrast in Dark Mode by setting `checkColor: theme.colorScheme.onPrimary` (high-contrast dark checkmark on primary lime background) and unified the font style of the clickwrap text below the button with `theme.textTheme.bodySmall` to match the consent text above. Updated localized strings (`welcome_privacy_body`, `i_agree_to_privacy_policy`, `by_tapping_accept`, `and_acknowledge`) across all supported languages (`en`, `de`, `fr`, `it`, `ja`).

### Fixed
- **Onboarding Unit System Persistence:** Fixed an issue where unit system selection during Onboarding (Metric vs Imperial) was not properly persisted to `SharedPreferences` and SQLite `appSettings`. Removed the early return guard in `UnitService.setUnitSystem()` that prevented disk writes when the selected system matched memory state, updated `ProfileLocalDataSource.saveUserGoals()` to store the selected `unit_system` in the `AppSettings` table instead of hardcoding `'metric'`, and added explicit persistence in `OnboardingScreen._finishOnboarding()`.
- **Statistics Screen Caching & Instant Tab Switching:** Fixed destructive reloading and full-screen skeleton flashing on tab switches to the Statistics screen. Added in-memory caching with a 30-second freshness TTL, dirty state tracking (`markDirty()`) on home screen data updates, non-destructive background updates when returning to cached statistics views, and restricted `Skeletonizer` enablement to initial cold loads (`!hasAnyData`) and explicit timeframe range changes.
- **100x Import Speedup & SQLite Variable Chunking:** Optimized exercise name resolution during CSV import in `import_manager.dart` by introducing an in-memory `exerciseCache`, reducing DB queries from 4,000+ to ~40 and speeding up imports to <0.5 seconds. Fixed endless loading loops in `WorkoutHistoryScreen` by chunking `localIdsByUuid.keys` in `_loadWorkoutLogsWithSets` (`workout_local_data_source.dart`) into max 500-variable batches to eliminate `SQLiteException: too many SQL variables` errors on large histories.
- **Hevy CSV Import & Locale Date Parsing:** Fixed a crash during Hevy CSV workout import caused by uninitialized `intl` date formatting in background isolates (`LocaleDataException: Locale data has not been initialized, call initializeDateFormatting(<locale>)`). Added isolate-level `initializeDateFormatting()` in `ImportManager.decodeAndGroupWorkouts` and expanded date parsing patterns in `_parseDate` to safely handle full German and English month names (e.g. `"25 Juli 2026, 14:21"`) as well as dot-separated and localized day-month formats.
- **Exercise Notes Localized Tooltips:** Replaced hardcoded German tooltip strings (`"Notizen bearbeiten"`) with localized strings (`l10n.exerciseNoteTitle`) across workout components (`LiveWorkoutScreen`, `EditRoutineExerciseCard`, `WorkoutExerciseLogCard`), ensuring correct accessibility labels for screen readers in all supported languages (PR #532).
- **Food Selection Accessibility Tooltips:** Added missing localized tooltips (`l10n.add_button`) to icon-only add buttons in `FoodExplorerScreen`, `GeneralFoodSelectionScreen`, and `FoodItemSearchTile` for enhanced screen reader navigation (PR #534).

### Performance
- **Ernährungs-Screen 120Hz ProMotion Scroll Optimization:** Eliminated micro-stuttering and GPU frame drops on 120Hz ProMotion displays (e.g. iPhone 16 Pro) in `DiaryScreen`. Replaced offscreen live GPU `BackdropFilter` shader blur in `RecommendationBanner` with a high-performance translucent glass background container, and removed nested, oversized `RepaintBoundary` wrappers around the top overview column to eliminate screen-sized texture layer re-rasterization during scrolling.
- **Sleep Aggregation Iterable Optimizations:** Optimized `SleepPeriodAggregationEngine` (`sleep_period_aggregations.dart`) by refactoring `_meanScore` and `_averageDuration` to process parameters as `Iterable` instead of `List`. Replaced chained `.map().whereType().toList().fold()` allocations with single-pass `for` loops, reducing iteration complexity to O(N) time and eliminating intermediate array allocations (PR #533).

## [1.0.0-beta.3] - 2026-07-25

### Changed
- **Default Theme Mode (Dark Mode):** Updated application default theme mode in `ThemeService` from `ThemeMode.system` to `ThemeMode.dark`. New installations and unconfigured app preference states now default directly to Dark Mode while preserving user customization in `AppearanceSettingsScreen`.

### Fixed
- **Onboarding & Backup Unit System Transfer:** Added the missing `UnitSystemSlide` as a dedicated step in the `OnboardingScreen` flow (allowing users to choose between Metric `kg/cm/ml` and Imperial `lbs/in/fl oz` on initial setup). Fixed unit system preference transfer during backup import (`BackupManager` & `ICloudSyncService`) by explicitly synchronizing `unit_system` in `SharedPreferences` with database settings and invoking `UnitService.reload()`, ensuring imported imperial or metric settings immediately update the onboarding screens and application UI.
- **Maestro Store Screenshot Automation Scripts:** Synchronized and updated both German (`iOS_store_screenshots_de.yaml`) and English (`iOS_store_screenshots_en.yaml`) Maestro UI automation flows. Integrated the onboarding unit system selection step (`UnitSystemSlide`) selecting Metric (`kg/cm/ml`) for both languages, removed obsolete Health permission popups, fixed Muscle Readiness card selector (`"Muskel-Bereitschaft"` / `"Muscle Readiness"`), and streamlined the complete automated screenshot capture flow across diary, nutrition, settings, measurements, recovery, AI meal capture, and live workout logging.

## [1.0.0-beta.2] - 2026-07-23

### Legal
- **Privacy Policy v1.5 — iCloud Backup Disclosure:** Added iCloud Backup clause (item 5) to Section 6 (Data Security & Backups) across all legal documents to disclose the new optional iCloud Backup feature introduced in this release. Clause confirms: (1) the feature is strictly opt-in and user-controlled via Apple ID / iOS settings; (2) backup data is encrypted by Apple's iCloud infrastructure; (3) Train Libre has no access to backup files or encryption keys on any external server; (4) data privacy is governed by Apple's iCloud Privacy Policy. Updated across: in-app `legal_screen.dart` (EN + DE), `docs/privacy-policy/privacy_policy.md` (EN + DE), `docs/privacy.html`, `docs/privacy-policy/index.html`, and `docs/script.js` i18n translations for all five supported languages (EN, DE, FR, IT, JA). Document version bumped from 1.4 → 1.5, effective date 23. Juli 2026.

### Added
- **AI Meal Pre-Processing & UI Refinements:** Added instant local pre-processing pipeline (`PhotoPreProcessor`) for AI photo scanning. As soon as a photo is captured or selected, image optimization and base64 encoding run in the background with a blurred preview thumbnail, a grey progress bar, and interactive cancelation via the delete button.
- **AI Meal Review & Spatial Depth Hooks:** Added inline quick quantity stepper controls (`-25g`, `+25g`), explicit trash deletion buttons on `MealReviewComparisonCard`, and quick-action feedback tags ("Larger portions", "Separate ingredients", etc.) on `AiMealReviewScreen`. Extended candidate data models (`AiSuggestedItem`, `AiMealCandidateItem`) with spatial depth fields (`volumeCm3`, `depthConfidence`, `spatialBoundingBox`) to support future camera depth / LiDAR scan integration.
- **Additional Overview Nutrient Setting:** Added customizable *"Zusätzlicher Nährstoff in der Übersicht"* setting in `SettingsScreen`. Users can select which non-standard nutrient is featured in the 3x2 daily overview grid on `DiaryScreen` alongside Calories & Water: **Ballaststoffe (Fiber)** (*Default*), **Zucker (Sugar)**, or **Salz (Salt)**. The 3rd tile dynamically renders intake vs configured target goals (`targetFiber`, `targetSugar`, `targetSalt`) with full localizations (`de`, `en`, `fr`, `it`, `ja`).

### Fixed
- **Real-Time Overview Nutrient & Goal Targets:** Fixed intake calculation for Ballaststoffe (Fiber) and Salz (Salt) by adding `summary.fiber` and `summary.salt` accumulation logic to `CalculateDailyNutritionUseCase` for food entries. Fixed delayed update in `DiaryScreen` when changing the *"Zusätzlicher Nährstoff"* setting by adding an instant `StreamController` broadcast in `UserPreferencesRepository` (`watchOverviewExtraNutrient`), updating `DiaryViewModel` in real-time without needing day switches or app restarts. Fixed missing target goals for Ballaststoffe (Fiber) and Salz (Salt) by passing `targetFiber` and `targetSalt` from preferences into `DailyNutrition`, correctly displaying intake and configured daily goals (e.g. `22.0 / 30 g` for Fiber) instead of `0.0 / 30 g`. Fixed missing French localization keys (`settingsOverviewExtraNutrientTitle` & `Subtitle`) in `app_fr.arb`.
- **Diary Summary Grid Alignment:** Balanced column width ratio in `NutritionSummaryWidget` under "Heute im Blick" on `DiaryScreen` from asymmetric `3:4` to an exact `1:1` (50% / 50%) split, giving primary daily metrics (Calories & Water) equal prominence and centering the layout divider.
- **Workout Summary & Log Detail UI Refinements:** Redesigned the top summary hero header in `WorkoutLogDetailScreen` and `WorkoutSummaryScreen`, positioning workout titles and notes left-aligned at the very top directly below the summary metrics bar instead of rendering them centered below the heatmap/heart rate sections. Moved the "Save as Routine" button to a top app bar action button. Fixed heart rate card visibility in `WorkoutSummaryScreen` by checking `PulseTrackingService.isTrackingEnabled()` and sample existence, completely hiding the card when pulse tracking is disabled and no samples exist. Standardized section headers across `WorkoutSummaryScreen` and `WorkoutLogDetailScreen` using `AppSectionHeader` for `AKTUELLE VERTEILUNGS-HEATMAP`, `NEUE REKORDE`, `ABSOLVIERTE ÜBUNGEN`, and `HERZFREQUENZ`. Fixed untranslated English PR labels (`Best Max Weight`, `Best Volume Set`, `Best 1-Rep Max`) in `WorkoutLogDetailScreen` to use localized metrics (`l10n.exerciseMetricMaxWeight`, `l10n.exerciseMetricVolume`, `l10n.exerciseMetricEst1RM`). Fixed empty Heatmap header bug by only rendering `AppSectionHeader` when muscle highlight data is non-empty.
- **AI Meal Review UX & Card Layout:** Fixed full-screen/full-list loading spinner when editing quantities or modifying items by updating values and running validation silently in the background without flickering. Fixed `Dismissible` swipe-to-delete height mismatch by resetting `SummaryCard` default vertical margin (`margin: EdgeInsets.zero`) and internal double padding (`padding: EdgeInsets.zero`), aligning the red delete background perfectly 1:1 with the white card container. Stacked Swap & Delete icons vertically above the quantity stepper for a compact, spacious left-side macro badge display.
- **App Tour Highlight Sizing & Label Inclusions:** Shifted navigation bar spotlight rectangle (`_tourNavigationBarKey`) 16px to the right for exact 1:1 symmetrical alignment around the 4 tabs glass container. Adjusted individual tab spotlight boxes (`_tourDiaryTabKey`, `_tourWorkoutTabKey`, `_tourStatisticsTabKey`, `_tourNutritionTabKey`) lower (`top - 4`, `height + 28`) so both the icon and full tab text label below are completely enclosed. Reduced overlay spotlight inflation padding (`targetRect?.inflate(4)`) for clean, tight rounded highlight borders. Updated `_skipAppTour` and `_completeAppTour` to navigate back to the **Tagebuch** tab (`_onNavigationTapped(0)`).

### Changed
- **Profile App Bar Avatar:** Updated the empty state profile button in the top app bar to display a Trade Republic style solid circular avatar containing the capitalized initial letter of the user's name when no custom profile picture is set. Custom profile images remain unchanged.

### Performance
- **Iterable & Control Flow Optimizations:** Optimized product lookup and UI screen iterations (`ProductLocalDataSource`, `MealsScreen`, `RoutinesScreen`) by replacing chained iterable method allocations with single-pass loops/Sets and replacing exception-throwing `firstWhere` lookups with safe null checks (PR #531).

### Security
- **Backup AI API Key Exclusion:** AI provider API keys (SharedPreferences keys with prefix `ai_api_key_*`) are now explicitly excluded from backup payloads in `BackupManager.generateBackupPayload()`. Keys stored via `FlutterSecureStorage` were already excluded by design; this ensures SharedPreferences-level keys are also never exported to backup files.

### Fixed
- **Onboarding App Tour Auto-Start:** Removed the opt-in dialog asking users whether they want the app tour after completing onboarding. The tour now starts automatically on first launch, giving every new user a guided introduction to the app without a choice screen.
- **Consent Re-Displayed After App Reset:** After performing a local data reset (via Settings or Data Management), the Privacy Policy & Terms of Use consent screen is now shown again before re-entering the app. Previously the app navigated directly to `AppInitializerScreen`, bypassing the consent check that only runs at cold boot in `main()`.
- **Navigation Test (settings_structure_navigation_test):** Updated test expectation from `'Show sugar in Diary overview'` to `'Additional Nutrient in Overview'` to match the renamed setting tile introduced in the configurable overview nutrient feature.
## [1.0.0-beta.1] - 2026-07-23

### Changed
- **Release:** Prepared repository for Public Beta launch phase by advancing package version string in `pubspec.yaml` to `1.0.0+1`.

### Accessibility
- **AI Meal Capture:** Added localized tooltip `l10n.aiMealCapture` to the AI Meal Capture button on the Add Food screen for improved screen reader support.

### Fixed
- **Empty States:** Fixed vertical positioning of `ColdStartEmptyState` in `RoutinesScreen` by accounting for top app bar padding (`topPadding`).
- **Empty States:** Fixed ingredient empty state in `MealScreen` by providing adequate vertical height, resolving straight arrow lines and text overlapping.
- **Consistency Tracker:** Fixed historic timeframe selection in `ConsistencyTrackerScreen` by querying weekly metrics relative to selected timeframe bounds (`untilDate`), synchronizing `TableCalendar` focused day, making top 2x3 KPI grid metrics timeframe-adaptive ("Im Zeitraum"), removing redundant chart title lines, and adding a glassmorphic empty state view for periods without workout data.
- **Widget Test Suite:** Resolved widget test failures across 9 test files (`supplement_reactive_migration_test.dart`, `initial_consent_screen_test.dart`, `pulse_settings_screen_test.dart`, `sleep_settings_screen_test.dart`, `feedback_report_screen_test.dart`, `sleep_day_navigation_test.dart`, `adaptive_recommendation_settings_flow_test.dart`, `edit_routine_unsaved_changes_test.dart`, `data_management_delete_local_data_test.dart`, `workout_log_detail_reactive_test.dart`) by updating legacy `FilledButton`/`OutlinedButton` finders to custom `AppButton` design system components, adding missing `Key` identifiers on action buttons, replacing infinite animation `pumpAndSettle()` timeout loops with deterministic frame pumps, and fixing the reactive edit-mode guard test by: (1) adding `ValueKey('weight_input_${setLog.id}')` to the weight `TextFormField` in `WorkoutLogSetRow`, and (2) setting a 800×3000 test viewport via `tester.binding.setSurfaceSize` so `ReorderableListView.builder` eagerly renders all items. All **644/644 tests now pass**.

### Security
- **Backup Export:** Fixed dynamic table name SQL injection vulnerability in `BackupManager._fetchTable` by strictly validating table names using alphanumeric regex before query execution.

### Performance
- **Liquid Glass Shader Pipeline (Android Fix):** Fixed severe 5 FPS GPU pipeline stuttering on Android devices (e.g. Samsung Galaxy S23) by introducing platform-adaptive glass quality (`DesignConstants.defaultGlassQuality`). Replaced hardcoded `GlassQuality.premium` overrides across `GlassFab`, `GlassTabBar`, `RunningWorkoutOverlay`, `SpeedDialMenuOverlay`, `LiveWorkoutScreen`, and `PlatformAdaptiveDropdown` with `GlassQuality.standard` on Android (eliminating GPU subpass framebuffer stalls and enabling 60/120 FPS rendering) while preserving single-layer glass rendering (eliminating double backdrop filter blur overlays).
- **Measurements Screen:** Optimized `MeasurementsScreen` opening performance by deferring initial DB fetches past the 300ms page route push animation (`Future.delayed`), enabling 100% instant, fluid navigation transitions at 120 FPS, and migrating session card rendering to a lazy `SliverList.builder` with cached date formatting.
- **Data Export & Analytics:** Optimized data extraction loops across Export Manager, Share Service, Health Export Data Source, and Statistics Data Adapter by eliminating intermediate chained iterable allocations.
- **Diary ViewModel:** Optimized iterable pipelines and supplement log filtering in Diary ViewModel to reduce memory allocation during UI updates.

### Changed
- **Deployment Script:** Updated iOS build pipeline in `script/deploy_release.sh` to automatically sanitize version strings by stripping prerelease suffixes (e.g. `-alpha.xx` or `-beta.xx`) when calling `flutter build ios` and `flutter build ipa` for Apple App Store & TestFlight compatibility.

### Dependencies
- **GitHub Actions:** Bumped `actions/setup-python` to v7 in GitHub workflows.
- **Dependencies:** Bumped Flutter/Dart dependencies (`drift`, `drift_dev`, `flutter_local_notifications`, `google_fonts`, `liquid_glass_widgets`, `package_info_plus`, `share_plus`, `uuid`).


## [1.0.0-alpha.13] - 2026-07-19

### Added
- **Diary Supplements:** Implemented the ability to edit or delete individual historic supplement entries directly from the Diary Screen via a premium glass bottom sheet detail view.

### Changed
- **Dependencies:** Removed deprecated `isInDebugMode` flag from `Workmanager` initialization.
- **Empty States & Skeletonizer:** Harmonized Empty State & Skeletonizer architecture across remaining screens. Replaced legacy blank empty states with interactive/read-only `ColdStartEmptyState` and page-body `Skeletonizer` + `ActiveGapOverlay` combos while preserving timeframe filter interactivity on Routines, Workouts History, Meal, Sleep, Measurements, and Analytics detail views.

### Fixed
- **Code Quality:** Fixed unchecked nullable value accesses in daily nutrition logging.
- **Code Quality:** Removed duplicate tooltip arguments from Diary Screen icon buttons.
- **Scanner:** Fixed an issue where the back arrow button would disappear when camera permission was denied.
- **Statistics:** Improved performance and prevented micro-stutters during data reloading by offloading analytics payload parsing to a background isolate.
- **Statistics:** Fixed the Steps tracker card freezing on current period data by correctly binding the date range selector.
- **Live Workout:** Removed unnecessary local `Overlay` wrapper from the list builder, resolving a closure capture bug to ensure bottom padding updates instantly, and optimized the padding height to `220.0` when the rest timer is active to clear the FAB perfectly.
- **Statistics:** Optimized the rendering pipeline by showing the loading indicators immediately, but deferring the sequential SQLite queries and isolate creation by 350ms to allow the page transition and bottom bar animations to finish completely, rendering at a perfect 120Hz.
- **Statistics:** Removed all initial and reloading circular progress spinners from the analytics cards, allowing them to fall back to their full layouts which are beautifully skeletonized by the page's `Skeletonizer` for a premium shimmering effect.
## [1.0.0-alpha.12] - 2026-07-17

### Added
- **Background Tasks:** Added `workmanager` integration to schedule periodic background tasks on iOS and Android. The Adaptive Nutrition TDEE recalculation is now scheduled to run in the background.
- **Accessibility:** Added localized tooltips to the diary date navigator to improve screen reader support and usability.
- **Accessibility:** Added missing tooltips to IconButtons app-wide for improved screen reader support.

### Changed
- **Performance:** Optimized the processing of active entries in the Diary view model.
- **Performance:** Eliminated redundant loops and iterations in the `CalculateDailyNutritionUseCase`, significantly improving the performance of daily nutrition calculations.
- **Performance:** Removed expensive try-catch blocks in favor of null-safe searching for `firstWhere` control flow.

### Fixed
- **Onboarding:** Added a loading spinner to the "Next" button on the region selection page during database update checks, preventing the app from appearing frozen.
- **Backups:** Fixed an issue where routine pause timers (`pauseSeconds`) and exercise notes within routines were not correctly exported/imported via JSON backup.
- **Live Workout:** Fixed a string interpolation bug that caused new Personal Records to always display as "1 kg" (or "1 km").
- **Live Workout:** Changed Personal Record logic so that establishing a baseline (logging an exercise for the very first time) no longer triggers a "New Record" notification. Only subsequent improvements will trigger it.
- **Statistics:** Improved the empty state UI in the Statistics Hub. The active gap overlay label now reads "Keine Daten für diesen Zeitraum verfügbar" to match the Diary screen.
- **Empty States:** Fixed the "Cold Start" empty state layout. The tutorial arrow now points exactly to the center of the "+" FAB, and the height calculations have been refined to lift the arrow tip cleanly above the FAB on both the Diary and Statistics screens.
- **Empty States:** Replaced the loading `CircularProgressIndicator` during initialization (cold start loading) on both the Diary and Statistics screens with a shimmering skeleton card layout (`Skeletonizer`), eliminating the crude spinners and ensuring smooth visual transitions.
- **Statistics:** Fixed a bug where the Statistics screen would not automatically refresh after tracking a new workout or logging diary entries. Switching to the statistics tab now triggers a fresh reload of the data, which is delayed by 300ms to allow the bottom navigation bar animations to finish smoothly without drop frames (jank).
- **Diary Supplements:** Restored the expected UI behavior for supplements on the Diary screen. Supplements with a `dailyGoal` or no limit are now displayed as checkmark cards again, and only supplements with a specific `dailyLimit` (e.g., Caffeine) are shown as progress bars.
- **Notifications:** Fixed an issue where rest timer notifications on iOS would only trigger or double-trigger when returning to the app. Notifications are now correctly scheduled and foreground banners are cleanly suppressed.
- **Adaptive Pickers:** Removed redundant manual haptic feedback calls from the adaptive date, time, and timeframe pickers to prevent double haptics when scrolling.
- **Security:** Fixed a high-severity SQL injection vulnerability in the backup import flow by strictly validating table and column names.
- **Empty States:** Replaced all legacy single-text empty-state placeholders across the app with the new premium `ColdStartEmptyState` glassmorphic hero component. Affected screens: Edit Routine, Food Explorer (Recents, Favorites, and Recipes/Meals tabs).
- **Empty States:** The `ColdStartEmptyState` now supports an optional `showArrow` parameter (default: `true`). This allows the tutorial curved arrow to be hidden on read-only or context-inappropriate screens (e.g., Recents and Favorites tabs in the Food Explorer).
- **Empty States:** The `SeamlessLoadingOverlay` widget now renders the underlying child wrapped in a `Skeletonizer` shimmer as the cold-start loading state, replacing the previous `CircularProgressIndicator` fallback. All analytics detail screens (Recovery Tracker, PR Dashboard, Consistency Tracker, Muscle Group Analytics) automatically benefit from this change.
- **Statistics Hub:** All statistics section cards (Steps, Sleep, Pulse, Consistency, Volume/Muscles, Performance, Body Metrics) now always render as full cards even when tracking is disabled or data is absent. Instead of hiding or collapsing, each card renders its content behind a premium `CardEmptyStateOverlay` — a glassmorphic `BackdropFilter` with a pill-shaped message explaining the state (e.g., "No data available for this period" or "Enable step tracking in Settings"). The shimmer skeleton is preserved under the overlay for a premium feel.
- **Statistics Hub (Refinement):** Steps, Sleep, and Pulse cards (and their section headers) are now **completely hidden** from the Statistics Hub when the respective tracking feature is disabled in Settings — no empty state placeholder at all. When the feature **is** enabled but no data was logged in the selected time range, the card renders with a uniform glassmorphic `CardEmptyStateOverlay` reading "Keine Daten für diesen Zeitraum verfügbar". The Recovery (Muskel-Bereitschaft) card now also uses this overlay instead of its previous inline no-data text label.




## [1.0.0-alpha.11] - 2026-07-15

### Added
- **Premium Empty States & Loading System:** Implemented a new highly modular, glassmorphic empty state and loading skeleton system across the Diary screen and Statistics Hub. Differentiates cleanly between "Cold Start" (educational hero icon and bobbing arrow) for new users and "Active Gap" (subtle translucent glass overlay over pulsing skeleton layout components) when no data is logged for a given day or period.

### Changed
- **Centralized Premium Glass UI Height Standards:** Polished and centralized the vertical proportions of all key glassmorphic components to perfectly match native iOS standards (Apple HIG) via new shared design tokens in `DesignConstants`.
- **Glass Bottom Navigation Bar & FAB:** Reduced the floating bottom navigation bar height and floating action button (FAB) size from 74dp to 64dp, updating related shadow paths, clip states, and dynamic safety paddings.
- **Glass Workout Overlay & Rest Timer:** Scaled the running workout progress bar overlay and the live workout rest timer bar height from 74dp to 64dp. Dynamically offset the floating action button bottom padding above active rest timers to maintain a consistent 8dp clearance (124dp total offset).
- **Glass Plus-Menu & Overlay Items:** Refactored the Speed Dial overlay to use the 64dp FAB anchor and smaller 56dp custom action buttons, recalibrating the sprout animation coordinate offsets and spacing gaps.
- **Glass Bottom Sheet Menu Items:** Polished the `_GlassTile` options within the modal bottom sheet menu to use a 36dp leading icon container and 8dp vertical padding, yielding a standard 52dp height for interactive list items.

### Fixed
- **Diary Supplements and Wearables State Resolution:** Fixed a bug where active-state data streams for supplements and wearables were blocked or incorrectly overridden by skeleton dummy data on the diary screen.
- **Tracked Supplements Display Logic:** Restored display logic to show all currently tracked supplements without any daily goals or limits as simple checkmark cards, while dynamically displaying any supplement that has a `dailyGoal` or `dailyLimit` set as a progress bar.
- **Workout Hub Empty Routines State:** Rendered an inviting helper text to the right of the "Neue Routine" button when the user has no custom workout routines created, which automatically disappears as soon as the first routine is created.
- **Nutrition Hub Empty Recipes State:** Implemented matching layout behavior for the "Meine Rezepte" section in the Nutrition Hub, showing an inviting recipe creation helper text to the right of the "Rezept erstellen" button when no custom recipes exist.
- **Onboarding Weight Checks:** Adjusted empty-state checks to ensure a single onboarding weight entry does not prematurely bypass the Cold Start empty state.
- **Speed Dial Button Shape:** Restored `borderRadius: 100` on Speed Dial action buttons so they render as true circular liquid-glass orbs, not rounded rectangles (regression from the size-token refactor that set radius equal to button size 56).
- **Workout Overlay Spacing:** Tightened the vertical gap between the running workout pill and the bottom navigation bar — reduced internal margin from 20dp to 8dp and Positioned bottom offset from `36 + navBarHeight` to `20 + navBarHeight`, eliminating the excessive dead space.

## [1.0.0-alpha.10] - 2026-07-14

### Fixed
- **iCloud Container Entitlements:** Resolved the container entitlement mismatch by removing the obsolete `$(TeamIdentifierPrefix)` macro from the ubiquity container identifiers list in `Runner.entitlements`, fixing the `E_CTR` invalid container errors on iOS.
- **iCloud Sync Stream Completion:** Reworked the upload and download operations to wrap `ICloudStorage` calls in a `Completer` that listens to the `onProgress` stream. This prevents the operations from resolving prematurely, fixing a bug where restoring from iCloud would always fail because the app tried to read the downloaded database snapshot before it was fully written.
- **SQLite Database Lock:** Fixed an issue where running manual backup or auto-backup concurrently caused a `SqliteException(1) output file already exists` crash, by checking if the snapshot file exists and calling an asynchronous `.delete()` on it before starting `VACUUM INTO`.
- **Flutter Stack Trace Assertion:** Resolved a crash where `debugPrintStack(stackTrace: st)` would trigger a Flutter framework assertion error due to `package:stack_trace` formatting conflicts. Replaced it with a standard `debugPrint("iCloud StackTrace: $st")` statement.
- **Progress Overlay Exception Interception:** Fixed a bug where native exceptions thrown during the `LongRunningOperationOverlay` run were thrown out of the dialog context as unhandled event loop errors, crashing the app. Exceptions are now caught within the async closure, closing the overlay gracefully and propagating errors to the card UI.
- **Static Analysis & Test Suite:** Resolved all `use_build_context_synchronously` warnings across onboarding and workout views by adding proper `mounted` checks. Fixed test suite failures related to missing `SharedPreferences` mock initialization, timeout issues in the Pulse Tracking test, string capitalization mismatches in the nutrition recommendation test after typography changes, and corrected expected assertion values in the recommendation repository.
- **Sleep Detail View Alignment:** Fixed a layout inconsistency in the daily sleep detail screens (Duration, Interruptions, Regularity, Depth, Heart Rate) where the top header text (value, status, subtitle) was shifted further to the right than the charts below it. This was caused by an accidental double-padding within the `SleepDetailPageShell`; the redundant inner padding has been removed, perfectly aligning the entire screen to the left edge of the cards.

### Changed
- **Sleep Target Range Visualization:** Upgraded the horizontal target range visualization bar (`SleepBenchmarkBar`) on the Sleep Duration and Heart Rate detail screens. Replaced the binary visualization (Green/Gray) with a highly detailed 3-color segmented representation (Green/Orange/Red) that perfectly maps to the domain model (Optimal/Warning/Critical). Added exact numerical text indicators at the color transitions. Extracted the previously hardcoded threshold values into a centralized `SleepThresholds` configuration file.
- **iCloud Sync Progress UI & Error Handling:** Integrated the blocking `LongRunningOperationOverlay` during manual backup to display real-time upload progress (e.g., "Uploading... 45%"). If the synchronization fails, the app now launches the project-standard full-screen `GlassMenu` overlay containing localized descriptions, a copy action, and dismiss actions.
- **Multi-language Localization:** Added localized strings for the glassmorphism error menu title, help info, and buttons inside the `.arb` files, ensuring full localization support across all 5 supported languages (English, German, French, Italian, and Japanese).
- **Background Auto-Backup:** Disabled periodic SQLite auto-backups explicitly for iOS/macOS devices to prevent execution conflicts, keeping this feature active only for Android.
- **Backup File Visibility:** Transitioned the local snapshot file ('icloud_backup.sqlite') path from user-visible documents storage to the hidden internal `Application Support` directory, cleaning up the iOS Files app experience.
- **Database Refresh:** Implemented a forced UI refresh and state reset immediately after a successful iCloud database restore, ensuring the newly downloaded data is instantly visible and connected.
- **App Settings Synchronization:** App settings stored in `SharedPreferences` (like the iCloud sync toggle itself, UI preferences, and goals) are now seamlessly bundled into a temporary `system_preferences` table inside the Drift SQLite database right before a backup, and extracted immediately upon restore. This guarantees that app configurations survive an iCloud or local restore alongside the database.
- **Aligned Onboarding Restore Pipeline:** The iCloud database restore sequence in the Onboarding flow has been perfectly aligned 1:1 with the standard local backup restore flow. After a successful database replacement, the Drift connection is closed safely, and the user is funneled through the standard permission checks (Apple Health, Camera, Notifications) before executing a clean app re-initialization via `main()`.
- **iCloud Sync Timestamp:** The iCloud Backup Card in Data Management now persistently tracks and displays a localized "Last synced" / "Letztes Backup" timestamp, informing the user of the exact time of their last successful upload.
- **Forced Restoring Overlays:** Integrated the blocking `LongRunningOperationOverlay` natively into all local JSON imports and iCloud database restores during Onboarding. This prevents users from navigating away or interrupting the process while large database files are being written or decrypted.
- **Cross-Platform UI Parity:** Ensured the "Restore from iCloud" option during onboarding is strictly hidden on Android devices, exclusively rendering for iOS and macOS.
- **Automated Onboarding Permission Sequence:** Implemented a fully compliant permission sequence following a backup restore in the Onboarding flow. The app now reads the restored preferences and sequentially loops through all previously active integrations (Apple Health/Health Connect, Steps, Pulse, Sleep). It reuses the existing custom Glass Bottom Menu explanation widgets to preface each native OS prompt, ensuring compliance with App Store guidelines before finalizing the clean initialization via `main()`.
- **Global Button System:** Migrated all platform-specific standard buttons (`ElevatedButton`, `FilledButton`, `OutlinedButton`) to the unified, custom-designed `AppButton`. This ensures a single, cohesive, premium aesthetic with consistent 12.0dp border radii, standard heights, and native-feeling tap animations across all platforms. `TextButton` instances were intentionally preserved.
- **AppButton Refinements:** Further polished the `AppButton` design system: (1) The `danger` variant now uses `DesignConstants.brandRedColor` (`#E5253A`) — a vivid, saturated red — instead of the muddy Material error color. (2) Labels now support `maxLines: 2` with `textAlign: TextAlign.center`. (3) `AppButtonSize.small` is now more compact at 32dp height / 8dp horizontal padding. The routine list "Start" button now renders as `AppButtonSize.small` for a sleek, card-native look.
- **Brand Red Color Upgrade:** `DesignConstants.brandRedColor` updated from `Colors.red` to `Color(0xFFE5253A)` — a rich, warm red that pops across all danger buttons, swipe-to-delete actions, and error indicators.
- **Danger Button Audit:** Corrected all destructive actions across the app to consistently use `AppButton.danger` (vivid red) instead of the default primary green. Affected locations: `local_data_deletion_card.dart` ("Alle lokalen App-Daten löschen"), `settings_screen.dart` (inline delete card and typed-DELETE confirmation sheet), `glass_bottom_menu.dart` (`showDeleteConfirmation` confirm button and "Verwerfen" in the active-workout-conflict dialog).
- **AppButtonSize.medium:** Added a new `medium` size tier (40dp height, 12dp horizontal padding) between the existing `small` (32dp) and `regular` (48dp). Used for the "Start" button on Workout Hub routine cards — provides a balanced presence without dominating the compact card layout.
- **Running Workout Overlay Buttons:** Fixed `RunningWorkoutOverlay` (`running_workout_overlay.dart`) to use compact `size: AppButtonSize.small` buttons that fit cleanly inside the 74dp glass-pill bar. "Verwerfen" now correctly renders as `AppButton.danger` (red) to signal the destructive discard action. "Fortsetzen" uses `AppButton.primary` (green).
- **Recipe Card Edit Button:** The "Bearbeiten" button on Nutrition Hub recipe cards (`nutrition_hub_screen.dart`) is now `AppButton.secondary(size: AppButtonSize.small)` — a subtle outline style that fits the compact horizontal card without a dominant green block.
- **Workout Hub Start Button Size:** Routine cards in the "Meine Pläne" horizontal scroll list now use `AppButton.primary(size: AppButtonSize.medium)` (40dp), replacing the previous `small` (32dp) which appeared too compact for the 160dp-tall card.
## [1.0.0-alpha.9] - 2026-07-13

### Added
- **iCloud Auto-Backup (iOS):** Added automated iCloud Drive backup support. When enabled in Settings → Data Management, the app silently snapshots the Drift SQLite database using `VACUUM INTO` and uploads it to the user's iCloud container whenever the app is sent to the background.
- **iCloud Restore on Onboarding:** The onboarding Welcome screen now asynchronously checks for an existing iCloud backup on first launch. If one is found, a "Restore from iCloud" button appears (with a green dot indicator), allowing users to restore their data after a reinstall or on a new device — without manual file picking.
- **iCloud Sync Card in Data Management:** Added an iOS-only `ICloudSyncCard` to the Data Management screen with a toggle to enable/disable automatic sync and a "Backup to iCloud Now" button with live success/error feedback.
- **Icon Button Tooltips:** Added accessibility tooltips to icon-only buttons across the app (e.g., in the workout sets list) to improve screen reader support and general usability.

### Fixed
- **Database Update Prompt Snooze:** Implemented a 30-day snooze mechanism when the user declines a database update prompt to prevent aggressive reprompting across screen changes.

### Changed
- **Typography:** Updated the inner typography styling of `ValueSummaryCard` to use the exact same TextStyle used in standard `ProgressBar` labels, unifying the visual design.
- **Sleep Hub Statistics:** Updated the sleep widget in the Statistics Hub to use a grid of `ValueSummaryCard`s for displaying sleep duration, bedtime, and interruptions, while preserving the sleep score ring.
- **Recovery Analytics Typography:** Adapted the typography in the Recovery Tracker and Recovery Section Cards to match the updated `ValueSummaryCard` typography (removed caps-lock, adjusted text sizes and weights).
- **Dependencies Update:** Updated various Flutter and Dart packages to their latest versions to maintain platform compatibility and security.
- **Website CTA:** Replaced the iOS TestFlight Beta link and label with the official App Store link.
- **Design System:** Centralized color constants into `DesignConstants` and unified all primary red elements (such as Failure set states and delete dialogs) to use the consistent brand red color.
- **Adaptive Icons:** Introduced a platform-adaptive share icon (`share_2` on Android, `share` on iOS/macOS) globally across the app to better align with native OS expectations.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Food Search Relevance & Performance:** Completely reworked the food search priority scoring to use pure SQL aggregations (Common Table Expressions) over the user's nutrition logs instead of iterating through them in Dart memory. This restores the highly accurate frequency-based search prioritization (frequently eaten foods appear at the top) while guaranteeing lightning-fast query speeds.
- **Daily Nutrition Calculation Performance:** Optimized the `CalculateDailyNutritionUseCase` by eliminating expensive $O(N \times M)$ list iterations and redundant exception handling, significantly improving the render performance of the daily diary summary.
- **Edit Routine Drag & Drop:** Disabled drag-to-reorder functionality for exercises in the Edit Routine screen while not explicitly in Edit Mode. This prevents users from accidentally reordering exercises when just browsing the routine.
- **Unit System Fixes:** Implemented full system-wide support for Imperial units (lbs, inches, miles). Fixed issues where unit labels and weight conversions were hardcoded to metric (kg) in the Edit Routine screen, Profile Goals, Onboarding, and Analytics Dashboards. Imperial steps are now cleanly adapted (e.g., 0.5 lbs increments) and accurately mapped to the underlying metric domain logic.
- **Workout Pause Timer:** Fixed a bug where the in-app pause timer would go out of sync when the app was pushed to the background on iOS. Also ensured that the timer is completely discarded when a workout is finished, prevented the timer from automatically starting after completing the final set of an exercise, and fixed the +/- 15 seconds adjustment buttons not working.
## [1.0.0-alpha.8] - 2026-07-10

### Added
- **Date/Time Picker Quick Actions:** Added a "Today" ("Heute") button to the adaptive date picker and a "Now" ("Jetzt") button to the adaptive time picker for faster data entry. The duration picker remains unaffected.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Sleep Duration Mapping:** Fixed Apple Health integration to properly map iOS 16 sleep stages (Core, Deep, REM) and `asleep_unspecified`, resolving an issue where sleep duration displayed as 0h 0min on iOS devices.
- **Food Detail Screen:** Fixed a bug where a 0g portion size would prevent users from switching back to the per 100g view, by automatically defaulting to the 100g view when the tracked portion is 0g.
- **Exercise Catalog:** Increased the display limit of the exercise catalog search from 50 to 100 entries.
- **Backup Import Flow:** Modified the backup import flow in the onboarding and data management screens so that restoring a backup successfully redirects the user to the onboarding region selection and health permission screens, ensuring proper regional data downloads and API authorizations are established on the new device.
- **Health Permissions UI:** Unified the health permission status UI across the Settings screens. The Pulse and Steps settings now correctly use the `SleepPermissionController` architecture to display a clear connection status (e.g., a red exclamation mark if permission is missing or denied), matching the reference implementation on the Sleep settings screen, and allowing users to trigger a new permission request by tapping the tile.
- **Measurements Dropdown Scrolling:** Limited the adaptive measurement chart dropdown menu to the available screen height so long measurement lists become scrollable and all options remain selectable.

### Changed
- **Sleep and Pulse Detail Refinements:** Simplified the sleep and pulse screens to reduce visual noise and improve readability. The sleep week and month views now use a monochrome score style with clearer tap targets, the month grid no longer repeats the "Sleep score" label, the daily heart-rate tile now shows the `bpm` unit directly in the value, and the pulse/duration benchmark bars now include explicit x-axis labels. The pulse detail screen now opens with a compact `⌀` average label and removes the extra summary cards below the header.
- **Unified Legal Screen:** Consolidated the Terms of Service directly into the main Legal Screen using the same collapsible accordion design as the Privacy Policy. This removes the need for a separate Markdown-based Terms of Service screen, streamlining the legal section and providing a single unified view for all legal documents. The initial consent screen has been updated to route correctly to this unified view.
- **Dynamic KPI Card Heights:** Removed fixed aspect ratios and hardcoded heights from `ValueSummaryCard` components across the analytics screens (Sleep, Pulse, Body & Nutrition Correlation, Nutrition Recommendation). The cards now dynamically adapt their vertical size (e.g., taking up less vertical space for 2 items vs. 3 items) while using `IntrinsicHeight` to ensure all cards within the same row stretch perfectly to match the tallest item, creating a tighter and cleaner "Anti-Slop" aesthetic.
- **Analytics Pulse Cards Density:** Modified the Pulse metric cards in the Statistics Hub to append the "bpm" unit directly to the value text rather than dedicating a separate subtitle line for it. This forces the cards into the compact 2-item layout, significantly reducing vertical bloat.
- **Measurements Screen and Bottom Menu Overhaul:** Reworked the Measurements screen and its add/edit bottom menu to match the food-entry flow more closely, including the fixed date/time header, fixed save action, improved swipe alignment, and the shared compact bottom-sheet height.
- **Measurement Sheet Layout and Swipe Alignment:** Moved the measurement date/time controls and save action out of the scrollable form area so they stay fixed in the bottom sheet, matched the flat green date/time treatment used by the food logging flow, and aligned measurement swipe actions with the card edge so the dismiss backgrounds start flush with the summary cards.
- **Energy Density Card Layout:** Removed the manual aspect ratio height constraint from the "Effective Energy Density" card in the Nutrition Recommendation screen, allowing it to stretch full-width while preserving its natural, compact height.
- **Diary Scroll Position:** Added a persistent scroll controller to the Diary screen to maintain the scroll position when navigating between different dates.
- **Diary Share Flow:** Streamlined the share action on the Diary screen to instantly trigger text-sharing of the daily summary, removing the intermediate selection menu.
- **App Bar Icons:** Refined the App Bar icons for better visibility. The profile placeholder and share icons now use pure white/black colors depending on the theme. The profile placeholder also received a subtle background and border to integrate better with the background.
- **Adaptive Share Icon:** The share icon is now adaptive, displaying the native iOS share icon on iOS devices and the standard share node icon on Android and other platforms.
## [1.0.0-alpha.7] - 2026-07-09

### Added
- **Cardio PR Logic & Badges:** Integrated cardio-specific personal records (Max Distance, Max Duration, Fastest Pace) into the `LiveWorkoutScreen`, `WorkoutSummaryScreen`, and `WorkoutLogDetailScreen`. Cardio sets now properly display PR badges upon completion.
- **Heart Rate Summary Grid:** Implemented a new three-column grid layout for Min, Avg, and Max Heart Rate inside the `WorkoutLogDetailScreen`, matching the visual style of the pulse analysis screens.
- **Muscle Name Localization:** Fully localized all anatomical muscle names across the app using arb files to support 5 languages.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Cardio Analytics Isolation:** Strictly isolated Cardio exercises from bodybuilding and hypertrophy metrics. Cardio data points are now filtered out of weekly set volumes, tonnage charts, consistency trackers, and muscle readiness states to prevent analytics pollution.
- **Cardio UI Data Artifacts:** Fixed a bug on the `ExerciseDetailScreen` where cardio PRs and time-series history displayed as "0" due to queries incorrectly falling back to strength constraints. Passed `isCardio` explicitly down the repository stack to retrieve duration, distance, and pace properly.
- **Cardio Heatmap Exclusion:** Completely removed the `DualBodyHighlighter` distribution map and primary/secondary muscle chip sections from the `ExerciseDetailScreen` when viewing a Cardio exercise.
- **Unified Cardio Duration Input:** Standardized cardio input fields across the Live Workout, Edit Routine, and Log History screens. The `Duration` field now uniformly opens the `showAdaptiveDurationPicker` with immediate UI feedback, while the `Distance` and `Intensity` fields retain standard native keyboard text inputs.


### Changed
- **Default Timeframes for Health Trackers & Hub:** Updated the default timeframes for the health trackers (Steps, Sleep, Pulse) to start on "Today" (Daily scope) instead of the previous default. Adjusted the Statistics Hub default timeframe to "Last 7 days" (Rolling Week) for a more immediate overview of recent data.
- **Fixed Timeframe Picker Scroll Jump:** Removed an internal scroll lock (`PageStorage`) in the `TimeRangeFilter` that previously prevented the active timeframe pill from properly re-aligning when scrolling up and down through the Statistics Hub, ensuring perfect edge alignment upon view reconstruction.
- **Cleaned up "MAX" Timeframe Pill Design:** Removed the redundant `< MAX >` date navigation sub-elements from the `TimeRangeFilter` when the "MAX" block is selected, resulting in a cleaner, solid primary-colored pill across all analytics screens.
- **Fixed Rolling Data Ranges:** Fixed an issue where "Last 30 Days" and "Last 7 Days" timeframes queried the database for the *entire* calendar month or week (e.g., July 1-31) instead of computing a true 30-day or 7-day rolling window from today. The `isRolling` context is now properly passed from the view models down to `StatisticsRangePolicyService.resolve()`.
- **Live Workout Default Pause Time:** Changed the default pause/rest time for newly added exercises and restored workout sessions from 90 seconds to 0 seconds (no pause).
- **Adaptive Pickers Haptics:** Implemented haptic feedback for the iOS-style Cupertino time, date, and timeframe pickers (`CupertinoDatePicker`, `CupertinoTimerPicker`, `CupertinoPicker`) when scrolling through options, automatically respecting the user's global haptic settings.

## [1.0.0-alpha.6] - 2026-07-08

### Changed
- **Unified Timeframe Traversal & Default State Order:** Standardized timeframe traversal across `StatisticsHubScreen`, `PRDashboardfluttScreen`, `MuscleGroupAnalyticsScreen`, `BodyNutritionCorrelationScreen`, and `ConsistencyTrackerScreen` to match a strict chronological order: `..., April, May, June, 08 June - 08 July (Rolling), July |`.
- **Fixed Statistics Hub Timeframe Traversal:** Upgraded the `shiftTimeframe` traversal in `StatisticsHubViewModel` to handle switching into and out of rolling states on left/right click, matching the behavior of detail screens.
- **Fixed Statistics Hub Timeframe Picker & Label Formatting:** Integrated `TimeframeLabelFormatter` inside `_unifiedRangeLabel` on the Statistics Hub so that the rolling timeframe displays correctly as `"dd. MMM - dd. MMM yyyy"` rather than repeating the static month name. Also passed `initialIsRolling` to `showAdaptiveTimeframePicker` so the picker preserves rolling selection states.
- **Enabled Rolling Month as Default Timeframe:** Changed the default view of all analytics screens (Statistics Hub, PR Dashboard, Muscle Group Analytics, Body/Nutrition Correlation, and Consistency Tracker) to start with the rolling month timeframe ("Last 30 days" / "Letzte 30 Tage") rather than the static calendar month ("July").

## [1.0.0-alpha.5] - 2026-07-07

### Changed
- **High-Resolution Timeframe Support:** Added `TimeframeBlock.day` to explicitly support granular day-by-day navigation for the Steps, Sleep, and Pulse modules.
- **Fixed Picker DST Freeze & Localization:** Resolved a critical Application Not Responding (ANR) infinite-loop freeze in the timeframe picker caused by traversing Daylight Saving Time boundaries on specific days. Also fixed missing localization so that dates and months in the wheel picker now render correctly according to the system language rather than defaulting to English.
- **Migrated Sleep & Pulse Navigation UI:** Upgraded the Pulse and Sleep sections to use the new unified `TimeRangeFilter` master-pill layout, entirely removing redundant external date selection rows and securely connecting the internal navigation logic to eliminate crashes.
- **Shiftable & Adjustable Timeframe Selection in Statistics Hub:** Upgraded the timeframe filter on the Statistics Hub from static filters to shiftable, natural calendar blocks (Week, Month, 3M, 6M, Year, Max) utilizing an adaptive Cupertino Wheel Picker. Standardized timeframe badges ("pills") across all analytics cards for visual consistency, while omitting the pill on the Recovery card entirely.
- **Refactored Hub Analytics Cards to Grid Layout:** Completely overhauled the Body & Nutrition, Pulse, and Recovery cards on the Statistics Hub. Replaced the disparate layout styles and heavy `SummaryCard` wrappers with a unified, flat `ValueSummaryCard` grid layout. The new design natively supports multi-line text (via `IntrinsicHeight`), cleanly eliminates all double-shadow nesting artifacts, and precisely matches the aesthetic of their respective detailed sub-screens.
- **Fixed Hub Timeframe Picker Index Shift:** Fixed an off-by-one mapping error in the Statistics Hub's timeframe picker that incorrectly shifted the user's selection (e.g. selecting "1 Year" showed "6 Months"). The issue was caused by the introduction of the granular `day` timeframe in sub-screens, which shifted the global enum index. The Hub now explicitly maps selections against a dedicated array of valid blocks.
- **Rolled out `SeamlessLoadingOverlay` Global Pattern:** Implemented a non-stuttering loading pattern (`SeamlessLoadingOverlay`) across 16 screens (Consistency Tracker, Muscle Group Analytics, PR Dashboard, Recovery Tracker, Measurements, Sleep Month/Week, Steps Module, General Food Selection, Create Exercise, Supplement Hub, AI Settings). The screens now keep the UI mounted and warp/animate smoothly when updating date ranges or swapping views, replacing the previous full-screen loading spinners.
- **Decontainerized Fluids Card in Diary:** Removed the individual `SummaryCard` wrappers from fluid entries in the Diary Screen. The fluid items now stretch edge-to-edge with 1px dividers inside the main unified `AppCardContainer`, perfectly matching the "Anti-Slop" design of the food meal cards (Breakfast, Lunch, etc.).
- **Added Profile Button Tooltip:** Added a missing semantic `Tooltip` to the Profile avatar button in the Main Screen AppBar, ensuring accessibility features and hover states display the localized "Profile" label correctly.
- **Fixed Routine Delete Bug:** Fixed a critical bug in the Routines Screen where swiping to delete a routine would trigger the confirmation dialog twice, leading to a crash or data error on the second prompt. The swipe-to-delete gesture now correctly triggers the confirmation only once and performs the background deletion safely.
- **Decontainerized Chart Widgets (Anti-Slop Phase):** Removed `SummaryCard` wrappers from all charts and graphs across analytics screens (Consistency Tracker, Recovery Tracker, PR Dashboard, Muscle Group Analytics, Statistics Hub, etc.), allowing them to sit directly on the scaffold background for a cleaner, high-density look.
- **Refactored Analytics KPIs to Grid Layout:** Replaced heavy `SummaryCard` and custom containers with a standardized `ValueSummaryCard` inside a precise 2-column grid format across the Consistency Tracker, Recovery Tracker, and PR Dashboard. Fixed alignment, spacing, and clipping issues using a robust `Column > Row` layout structure.
- **Fixed Recovery Tracker State Pill UI:** Corrected an issue where the background color tint for the "In Recovery", "Ready", and "Fresh" state pills only filled the inner padding. The widget now uses a solid `ValueSummaryCard` with a colored translucent border for a unified, clean aesthetic.
- **Restored Timeframe Selectors in Consistency Tracker:** Re-added the dynamic 30 days, 3 months, 6 months, and All Time choice chips above the Consistency Tracker KPI grid. Connected the chips securely to the repository fetch logic, bypassing the fixed 12-week global policy so the chart data reloads correctly on tap.
- **Updated Consistency Default Timeframe:** Changed the default window view for the Consistency Tracker chart to 6 months for better immediate historical context.
- **Decontainerized BodyHighlighter Widgets:** Removed the heavy `SummaryCard` wrappers from the `BodyHighlighter` widget across the app (Exercise Detail, Workout Log Detail, Workout Summary, Muscle Group Analytics, and Recovery Tracker screens) to embrace a flatter, edge-to-edge "Anti-Slop" design aesthetic.
- **Standardized DualBodyHighlighter:** Introduced a shared `DualBodyHighlighter` widget to ensure front/back silhouette diagrams have the exact same size and structure across `ExerciseDetailScreen`, `WorkoutLogDetailScreen`, `WorkoutSummaryScreen`, and Analytics screens.
- **Flattened Muscle Legends:** Removed the redundant "Vorne" / "Hinten" text labels, and flattened the primary/secondary muscle legends from background colored chips to clean typography in `ExerciseDetailScreen`.
- **Refactored Body & Nutrition Correlation Interpretation:** Replaced the heavy `SummaryCard` for the interpretation section on the Body & Nutrition Correlation Screen with a flat, minimal `AppInfoRow` widget, matching the cleaner design of the section.
- **Decontainerized Sleep Module Charts:** Removed `SummaryCard` wrappers from `SleepTimelineCard`, `WeekWindowCard`, `SleepScoreBreakdownCard`, and `SleepScoreCard` to adopt the flat, edge-to-edge "Anti-Slop" design. Increased the height of the sleep timeline chart by 25% for better visibility.
- **Refactored Sleep Module KPIs to Grid Layout:** Standardized textual summaries across Week and Month views into the `ValueSummaryCard` grid layout.
- **Redesigned Sleep Quality Header:** Refactored `SleepScoreCard` in the daily view to use `AppSectionHeader` and `AppInfoRow` styling, enlarging the score ring to 80x80 with bolder typography for prominence.
- **Fixed Sleep Module Styling & Spacing:** Enforced strict padding alignment between headers and chart limits. Aligned grid cell heights perfectly using `GridView` with fixed `childAspectRatio`, and ensured equal spacing (`8px`) between progress bars in the score breakdown card to match the grid below.
- **Adjusted Sleep Score Chip Text Colors:** Changed the daily score text color inside the weekly and monthly timeline chips to adaptively use the primary text color (`onSurface`), improving readability against dynamic background pill colors.
- **Refactored Pulse History for Week & Month Views:** The Pulse Analysis Screen now automatically aggregates intra-day heart rate samples by local day for weekly and monthly timeframes. The chart dynamically downsamples to plot only the estimated **Resting Heart Rate** per day (represented as a cleaner, easier-to-read trend line) instead of the extremely dense, noisy full intraday pulse history.
- **Dynamic Pulse Chart Titling:** The title above the pulse chart now dynamically changes from "Pulsverlauf" (Pulse History) on the daily view to "Ruhepuls" (Resting Heart Rate) on the weekly and monthly views to accurately reflect the aggregated data points being plotted.
- **Fixed Workout Drag-and-Drop 300ms Delay Bypass:** Removed the immediate `setState(_isDragging = true)` call from the `onReorderStart` callback in `edit_routine_screen.dart`, `live_workout_screen.dart`, and `workout_log_detail_screen.dart`. Previously `onReorderStart` was bypassing the intentional 300ms long-press delay (already implemented via `onPointerDown` timer), causing the card-collapse animation to snap in the instant the drag lock-in occurred instead of after the full delay.
- **Fixed Workout Drag-and-Drop Collapsing on Scroll:** Added `onPointerMove` handling to the `Listener` wrappers in all three workout reorder screens and their corresponding card widgets (`EditRoutineExerciseCard`, `WorkoutExerciseLogCard`). If the pointer moves more than 4px before the 300ms timer fires, the timer is cancelled immediately. This prevents the cards from collapsing into drag-mode when the user taps the exercise title and immediately scrolls — the app now correctly treats this as a scroll gesture with no side effects.
- **Fixed Localization — Analytics Muscle Set Labels (FR/IT/JA):** Corrected the French, Italian, and Japanese translations for `analyticsWeeklySetsByMuscle` and `analyticsWeekTotalEquivalentSets` to match the German and English reference style (using the `Ø` prefix and correct fitness terminology — e.g. French "séries" instead of the incorrect "ensembles", Italian "Serie" with the `Ø` prefix added).
- **Muscle Group Analytics — Timeframe Applies to Chart:** Connected the period selector in the Muscle Group Analytics screen so that the selected timeframe is applied consistently to both the KPI summary values and the weekly sets-by-muscle bar chart below, ensuring the chart data always reflects the chosen date range.

## [1.0.0-alpha.4] - 2026-07-07

### Added
- **iOS App Store Rating Prompt:** Implemented a native App Store rating prompt for iOS users using the `in_app_review` package. The prompt seamlessly appears in the background after 7 days of app usage without interrupting the user's workflow.

### Changed
- **Fixed Measurement Chart Shimmer:** Removed the condition that disabled the underlying gradient shimmer for edge-to-edge measurement charts. The shimmer is now universally visible underneath the line graph, matching the aesthetic of the Body & Nutrition Correlation trend charts.
- **Fixed Glass Bottom Menu Scrolling:** Moved the bottom safe area inset from the outer wrapper to inside the scrollable content lists (`SingleChildScrollView`). This fixes a UI bug where the scrolling content stopped short of the screen's bottom edge (leaving a ~14-34px gap inside the glass menu) instead of extending fully to the bottom.
- **Refactored Body & Nutrition Correlation UI:** Removed the outer summary card wrapper to allow the KPI widgets to sit freely in the layout. Extracted the small value box widget from the Nutrition Hub into a generic `ValueSummaryCard` in `common.dart` and applied it to the weight and calorie metrics for visual consistency. Converted the section title to use `AppSectionHeader` and the interpretation text below to use `AppInfoRow` for a cleaner, unified minimal-info design.
- **Fixed Reordering to the Bottom across Workout Screens:** Removed the unnecessary `newIndex -= 1` adjustment during drag-and-drop sorting across the Live Workout, Edit Routine, and Workout Log Detail screens. The custom reorder list implementation already passes the exact drop index, so the manual offset reduction was causing items to incorrectly drop one slot early (second to last) when dragged downwards.
- **Fixed Live Workout Screen Reorder Live Updates:** Wrapped the reorderable list of the Live Workout Screen inside a `Consumer<LiveWorkoutViewModel>` within the local `OverlayEntry`. This guarantees that changes to the exercise order in the view model are immediately reflected on-screen without requiring users to exit and resume the workout.
- **Removed Drag Shadows across all Workout Screens:** Set the drag proxy `Material`'s elevation to `0.0` in both `edit_routine_screen.dart` and `workout_log_detail_screen.dart`, completely removing the default drop shadows during reordering to match the design style of the Live Workout Screen.
- **Fixed Live Workout FAB Disappearing:** Refactored the Floating Action Button (FAB) on the Live Workout Screen to render as a direct `Positioned` widget inside the parent Scaffold's `Stack` rather than using `OverlayPortal`. This avoids issues where the FAB disappears due to local overlays or layout rebuilds.
- **Fixed Workout History Save Action and Data Persistence:** Fixed a bug where edited values (weight, reps, rir, etc.) in the Workout Log Detail Screen (History View) were not persisted to the database. Changed `updateSetLogs` in the data source from `batch.update` (which failed to apply correctly on updates due to schema mappings) to individual, transaction-wrapped await-writes. Added missing fields for cardio tracking (`distance` and `durationSeconds`) to ensure cardio sets save correctly as well. Also allowed saving when the header `Form` key returns a null state, and wrapped the transaction in a robust try-catch handler with visual feedback.
- **Fixed Missing Persistence for Reordered Exercises and Sets in History:** Implemented `logOrder` reassignment during the save process in the Workout Log Detail Screen. Reordered exercises and sets will now correctly persist their new positions in the database instead of reverting upon screen reload.
- **Fixed New Sets and Exercises Not Saving in History:** Fixed a bug where newly added sets and exercises during the Edit Mode of a completed workout weren't being saved to the database. Changed the temporary UI ID generator to use negative timestamps (`-DateTime.now().millisecondsSinceEpoch`), which properly triggers `INSERT` logic in `insertSetLog` instead of executing a silent `UPDATE` on non-existent positive ID rows.

## [1.0.0-alpha.3] - 2026-07-06

### Changed
- **Removed Exercise Drag Shadows and Stabilized Drag Layer z-Ordering:** Removed the drop shadow underneath the active highlighted exercise card during drag-and-drop actions on the Live Workout Screen by setting the drag proxy Material's elevation to `0.0`. Wrapped the reorderable exercise list in a local `Overlay` to ensure that dragging exercise cards remain visually underneath the sticky Floating Action Button (FAB) layer while still drawing over other non-draggable exercises.
- **Removed Redundant Set Completion Checkmarks from Workout History:** Removed the green checkmark icon from set rows in the Workout Log Detail Screen (History View) since all sets in a completed workout log are completed by definition.
- **Replaced Supplement Hub with Supplement Settings Screen:** Replaced the legacy daily tracking/logging screen in the Supplement Hub with the Supplement Settings Screen. Users can now view the full list of available supplements, edit goals/limits, create new supplements, or delete them directly from the hub. All daily logging has been removed from this screen, as the Diary remains the designated place for supplement logging. Removed `SupplementTrackScreen`, `ManageSupplementsScreen`, and their corresponding test files. Removed the fish icon and added a green/grey check circle indicator showing whether a supplement is currently actively tracked. Configured the list to sort and display tracked supplements on top.
- **Refactored Sleep Settings Screen Layout and Sync Behavior:** Consolidate health connection status, details on missing permissions, and request access action into a single interactive ListTile to simplify the UI. Removed the obsolete developer-facing "View raw sleep imports" feature. Extended default lookback period for manual sleep imports to 365 days (1 year) and the default automated sync lookback to 90 days to better capture historical sleep data. Fixed a HealthKit permission check bug on iOS where read-only authorizations (Sleep & Heart Rate) would incorrectly evaluate to "Denied" due to limitations in `HKHealthStore.authorizationStatus`. It now correctly checks overall HealthKit availability as a fallback.
- **Refactored Feedback Screen Privacy Notice:** Replaced the heavy `SummaryCard` and redundant page header with a clean, flat `AppInfoRow` layout for the privacy notice on the Feedback Report Screen.
- **Renamed Meal Templates to Recipes:** Renamed all user-facing references for custom meal templates and quick-log combinations from "Mahlzeiten" (Meals) to "Rezepte" (Recipes / My Recipes) across all supported localization files (German, English, French, Italian, and Japanese). Tapping "Als Rezept sichern" (Save as recipe) will now create a recipe template, helping users distinguish saved templates from daily logs.
- **Refactored Diary Meal Layout:** Removed the nested `SummaryCard` container wrapper around individual food entries inside a meal. Instead, food entries are rendered flat within the parent meal card, separated by a thin `Divider` for a cleaner look while maintaining full swipe actions and perfect alignment. Removed the divider line between the macro badges and the first food entry in the list to make the design cleaner.
- **Fixed Recipe Card Layout and Spacing:** Refactored the recipe list in `add_food_screen.dart` and `meals_screen.dart` from a `GridView` with fixed cell height to a dynamically sizing `ListView.builder`. This completely resolves bottom layout overflows for long recipe titles or wrapped macro badges, while ensuring shorter recipe cards remain compact without empty space. Restored standard margins on `MealItemCard`.
- **Localized Exercise Names across Summary and Sharing Flows:** Localized exercise names on the workout summary screen (including records/trophies and the exercise overview lists) using resolved exercise data lookups. Integrated translation resolution in `WorkoutShareFormatter` (text sharing and share cards) so shared workouts display exercise names in the user's current locale (German, English, etc.) rather than defaulting to raw English database names.

## [1.0.0-alpha.2] - 2026-07-05

### Changed
- **Restricted Drag-and-Drop Touch Areas and Stabilized Viewport Scrolling:** Restricted the drag-and-drop sort gesture trigger strictly to the exercise title on the Live Workout Screen, Edit Routine Screen, and Workout Log Detail (History) Screen by wrapping only the title with `Listener` and `ReorderableDelayedDragStartListener`. Enabled viewport scroll stabilization via custom scroll controllers, scroll height pre-collapse calculations, dynamic bottom padding to prevent clamping, and post-frame scroll position matching upon drag drop. Configured `OverlayPortal` layout positioning for the Glass FABs to ensure they render above the drag-proxy decorator layer.
- **Refactored Settings & About Screens to Flat Layout:** Replaced heavy `SummaryCard` container panels and nested list tiles with clean, flat `AppLinkRow` and `AppInfoRow` components in the About Screen, AI Settings Screen, and Data Management Screen (including CSV Export, Data Backup, Auto Backup, Exercise Mapping, and Workout Import card views) to improve UI elegance and hierarchy.
- **Created Common AppInfoRow Widget:** Added a new reusable `AppInfoRow` component to standardize formatting of non-interactive status or description fields.
- **Removed Repetitive Icons from Summary Cards:** Removed the redundant leading icons/emojis (calendars, dumbbells, stars/archives) from the summary list cards in Workout History (workout-verlauf), Exercise Catalog (Übungskatalog), and Food Catalogs (Allgemeiner Food-Katalog / Explorer / Lebensmittel hinzufügen via `FoodItemSearchTile`) to clean up the UI and avoid repetitive graphics.
- **Glass Bottom Menu Visual Polish:** 
  - Adjusted background to match the exact dark gray of the summary cards by defining `DesignConstants.summaryCardDarkMode` (`Color(0xFF2A2A2A)`) and using it consistently across both components and the custom date/time pickers (`_GlassPickerSheet` with `0.95` opacity in dark mode) to clearly separate the menu sheet from the background content.
  - Added a clean top and side border (`1.5` width) that adapts to light/dark themes to define the sheet boundary, and updated it to fade out smoothly from top to bottom (opacity 1.0 to 0) so that there is no hard border cutoff where the rounded corners of the device screen begin at the bottom.
  - Changed the drag handle color to adaptively use `onSurface` with `0.3` opacity, improving visibility in both light and dark modes.
- **Settings Section Card Consolidation:** Reworked the Settings screen so each section now uses one unified SummaryCard with dividers between its existing rows, matching the card grouping style used in Appearance settings.
- **Localized Food Titles in Dialogs & Lists:** Updated the food quantity bottom sheets (`_showQuantityMenu` in both `diary_screen.dart` and `main_screen.dart`), the ingredient logs in `ConfirmLogMealBottomSheet`, the ingredient card/edit list in `MealScreen`, and the AI validation review widgets (`AiMealReviewScreen` / `MealReviewComparisonCard`) to dynamically fetch and display the user's localized base food names (based on the language chosen in the settings) instead of showing the raw database/German names. Also resolved the root localization issue in the main diary list (`FoodEntryTile` / `getProductsByArchiveIds`) by dynamically enriching archived food entries with their name translations from the primary database products table.
- **Nutrition Recommendation Card Alignment:** Synced the "Data quality" heading with the same section-header treatment used by "Recommended targets" and matched the effective energy density card height, spacing, and text treatment to the target tiles.

## [1.0.0-alpha.1] - 2026-07-03

### Changed
- **Edge-to-Edge Chart Layout:** Refactored `MeasurementChartWidget`, `BodyNutritionNormalizedTrendChart`, and the Body & Nutrition correlation chart to render without a card container, extending the chart canvas from the left to the right screen edge — matching the Trade Republic–style full-bleed chart aesthetic.
- **Chart Line Right Boundary:** The chart line now ends just before the Y-axis label area rather than at the very right screen edge, leaving a small visual gap consistent with the reference design.
- **Weight History Widget Title Removed (Diary & Measurements Screens):** Removed the redundant "Weight History" section title from the Diary and Measurements screens since the section header directly above the chart already provides context.
- **Exercise Detail Chart:** Extended the exercise progress chart in the Exercise Detail Screen to the same edge-to-edge layout as the other charts.
- **Y-Axis Labels on Top of Chart Lines:** Fixed Z-ordering so Y-axis label text always renders above the chart's line and area data. Previously, labels were injected into fl_chart's internal paint pipeline and appeared behind lines; they are now placed as Flutter `Stack` overlay widgets drawn after the chart canvas.
- **Hard-Edged Axis Label Knockout:** Replaced soft Gaussian blur (`blurRadius: 6`) text shadows with a multi-directional `blurRadius: 0` shadow grid (±2 px in all directions) that produces a sharp, text-shaped background mask — so axis labels remain readable where they overlap chart lines without a blurry halo or a rectangular block.
- **Exercise Detail Empty State:** The "Not enough data" placeholder in the Exercise Detail Screen no longer uses the old `SummaryCard` container. It now renders in the same open, edge-to-edge style as when data is present.
- **Exercise Detail Y-Axis Clipping Fixed:** Added `clipBehavior: Clip.none` to the `SingleChildScrollView` in `ExerciseDetailScreen` so the chart's `OverflowBox` can reach the screen edges without being clipped by the scroll view.
- **Body & Nutrition Bottom Axis Edge Labels Fixed:** In edge-to-edge mode the chart domain is now padded by ±1 day (`minX: -1`, `maxX: maxX + 1`) so the first and last date labels are no longer centered at the very edge of the canvas, preventing them from being half-clipped and showing as lone digits ("4" / "0").
- **Localized Chart Range Filters:** Localized the chart range selector buttons (`30d`, `90d`, `180d`, `All`) across all supported languages (English, German, French, Italian, Japanese).
- **Tooltip Rendering Order:** Adjusted Stack Z-ordering in the body & nutrition trend chart so the tooltip overlay renders on top of the Y-axis labels.
- **Enhanced Chart Lines Styling:** Increased line thickness (bar width) on all main line charts and added a subtle, minimal curvature (`curveSmoothness: 0.15`) for smoother edges.
- **Monotonic/Overshoot-Free Splines for Line Charts:** Configured `curveSmoothness: 0.05` across all line graphs. This tighter curvature removes hard edges and rounds corners cleanly, while preventing overshoots and loops over large data gaps without the flattening artifacts of standard overshoot prevention.
- **TDEE Notification Scheduling & First-Launch Filtering:**
  - Configured `AppInitializerScreen` to asynchronously trigger a recommendation refresh check in the background on startup, ensuring TDEE recalculation alerts can be sent without requiring the user to open the nutrition screen.
  - Added a first-launch guard to `saveLatestRecommendationSnapshot` in the repository so that the initial default TDEE setup does not fire a system notification to new users on their very first app launch.
- **Database Catalog Import Performance Optimization:**
  - Configured `_performBatchImport` in the database manager to temporarily disable SQLite foreign key checks (`PRAGMA foreign_keys = OFF;`) during bulk batch imports of base foods, exercises, and OFF products. This significantly speeds up the catalog sync and update process by bypassing constraint validation on each inserted row, restoring the original state afterwards.
- **Repeat Onboarding Option Location:**
  - Moved the "Repeat Onboarding" (tutorial) card from the profile screen to the Settings Screen, placing it directly under the "Restart App Tour" card.
- **Container-Slop Hunting (Design Level 1):**
  - Dissolved the `SummaryCard` container wrapper around the adaptive nutrition recommendation views in `NutritionRecommendationCard` to render them inline/flat with minimalist margins.
  - Eliminated chunky card containers from the Legal and About section navigation options in the Profile Screen, converting them into clean, flat text links with inline chevrons and hover/ink tap responses.
  - Removed section headers ("About", "Legal") and leading icons from the minimal links at the bottom of the Profile Screen.
  - Replaced the "Today in focus" section header on the Nutrition screen with an uppercase "ADAPTIVE RECOMMENDATION" header, removing the redundant duplicate title inside the card.
  - Refactored "Estimated maintenance" and "Recommended targets" grids/tiles in the recommendation card to use the standard, premium `SummaryCard` widget.
  - Removed the outer container panel around the "Data quality" block so it renders flat and clean.

## [0.9.37] - 2026-06-29

### Added
- **Point-in-Time OFF Product Archive:** Introduced a transactional, append-only table `off_products_archive` storing immutable snapshots of Open Food Facts (OFF) products with content hashing (SHA-256) to ensure absolute historical consistency of user food logs.
- **Archive Verification Suite:** Created `offline_food_archive_test.dart` verifying auto-archiving, duplicate deduplication, override immutability, 3-tier lookup resolution, and backup/restore round-trip integrity.

### Changed
- **Write Path Auto-Archiving:** Configured `DiaryLocalDataSource` to automatically resolve, hash, and archive food item and override snapshots at write time transparently during `insertFoodEntry` and `updateFoodEntry` calls.
- **3-Tier Product Resolution Chain:** Refactored nutritional calculations, view models, stats charts (`getFoodCaloriesByDayForDateRange`), Apple Health exports (`HealthExportDataSource`), and daily log sharing (`ShareService`) to resolve product details using a 3-tier priority lookup: archived snapshot first, catalog product second, and legacy barcode fallback third.
- **Backup & Restore Format (v5):** Bumped the backup schema version to `5`. Updated `BackupManager` and `TrainLibreBackup` models to serialize, deserialize, clear, and restore archived product records and foreign keys.
- **OFF Lifecycle Pruning Protection:** Integrated `off_products_archive` distinct barcodes query inside `RetainHistoricalOffProductsUseCase` to protect historically logged barcodes from database pruning passes.
- **My Goals Citation Integration:** Added the `AlgorithmInfoButton` to the "My goals" settings screen's "Daily Goals" section header (matching the card layout from the nutrition screen), configured to display scientific citations for Mifflin-St Jeor and Kevin Hall energy balance models, and appended an in-line italicized non-clinical disclaimer at the bottom of the screen's scroll view.
- **1RM Citation Integration:** Integrated a non-intrusive `AlgorithmInfoButton` on the Exercise Detail chart header (visible when the Est. 1RM metric is selected) and on the Workout Summary accomplishments section header, providing clear scientific context and Epley equation disclosures.
- **QR Scanner Upstream Migration:** Removed the temporary local path override for `qr_code_scanner_plus` and migrated to the official upstream stable release (`v2.2.0`) on pub.dev, which resolves the iOS NSError codec serialization crash.
- **Database Catalog Import Optimizations:** Refactored the bulk database import sequence (`BasisDataManager._performBatchImport`) to execute all chunks in a single native database transaction, dynamically loosen disk synchronization guarantees during import (`PRAGMA synchronous = OFF;` and `PRAGMA journal_mode = MEMORY;`) with automatic restoring, and tune chunk size to `5000` to minimize isolate IPC overhead.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Food Entry Alignment in General Food Selection Screen:** Resolved an issue where food entry cards in the general food selection screen had double horizontal padding, causing them to be narrower and misaligned with the search bar.

## [0.9.36] - 2026-06-26

### Added
- **In-App Markdown Asset References:** Added dedicated scientific references and sources sections with clickable DOI links directly within the in-app markdown documentation assets (`muscle_recovery_model.md`, `bayesian_tdee_estimator.md`, and `sleep_scoring_engine.md`).
- **Localization Keys:** Introduced `infoScientificReferencesButton` and `infoScientificDisclaimer` translations in English, German, French, Italian, and Japanese ARB files.
- **Onboarding Region Selection Slide:** Introduced a new region/country selection step (`RegionSelectionSlide`) at the start of onboarding to allow users to select their local database region before any download.
- **Device Locale Autodetection:** Added automatic detection of the user's home country from `Platform.localeName` to pre-select the dropdown default value.
- **Onboarding Region Localization:** Added translation strings for the new selection screen in English, German, French, Italian, and Japanese ARB files.

### Changed
- **In-App Information Transparency & Citations:** Upgraded the `AlgorithmInfoButton` widget and bottom sheet to render clinical disclaimers and clickable scientific citation external links when a `citationUrl` is provided.
- **Algorithm Call Site Citation Wiring:** Wired up `citationUrl` properties for the Adaptive TDEE Engine (`nutrition_recommendation_card.dart`), Muscle Recovery Tracker (`recovery_tracker_screen.dart`), and Sleep Health Score (`sleep_score_card.dart` and `sleep_period_scope_layout.dart`) to deep-link users to relevant website evidence pages.
- **Website Citations Expansion:** Expanded the `#evidence` sections on the public-facing website pages (`adaptive-nutrition`, `recovery`, and `sleep-score`) with peer-reviewed medical and sports science references (including Mifflin, Harris-Benedict, Ratamess, AASM, SATED, and Buysse).
- **Splash Screen Database Prompt Removal:** Removed the automatic first-launch database catalog prompt from the initializer splash screen (`AppInitializerScreen`) to avoid showing it before onboarding.
- **Region-scoped Database Download:** Configured the onboarding "Next" action on the region selection screen to actively write the user's chosen region configuration and prompt for the regional database download/unpacking cycle.
- **Onboarding Widget Tests:** Updated the test suites in `onboarding_test.dart` and `adaptive_recommendation_settings_flow_test.dart` to support the updated page indices and bypass the dialog in test environments.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **LaTeX Parser Crash in Recovery Info Dialog:** Resolved a KaTeX rendering crash (`Parser Error: Can't use function '$' in math mode`) inside markdown headings in the Muscle Recovery Tracker details sheet by replacing greedy inline `$` math delimiters with markdown-compatible `\(...\)` delimiters.


## [0.9.35] - 2026-06-25

### Added
- **Dedicated Support Page (`support.html`):** Created a premium, localized developer support page resolving Apple App Store Review Guideline 1.5 (Safety - Support URL):
  - Integrates direct email support (`support@schotte.me`), GitHub issue tracking and bug report links, and expected response time commitments.
  - Styled with the branded dark theme background, theme switching logic, and transparent glassmorphic card containers matching the "Developed in public" layout blocks.
  - Added full multi-language translations for the Support page copy in English, German, French, Italian, and Japanese (`script.js`).
- **Apple-Compliant Lazy Database Catalog Loading:** Decoupled local exercise database initialization from remote nutrition database sync to address Apple Guideline 4.2.3(ii):
  - Exercise database is pre-seeded quietly on first launch using local assets and is guarded by a preference flag.
  - Added dynamic file size extraction for remote exercise and nutrition catalogs using lightweight network checks.
  - Introduced a centralized glassmorphic bottom sheet (`promptOffDatabaseDownloadIfFirstTime`) that displays dynamic sizes and lets the user choose between download and postponed state.
  - Integrated premium fallback placeholder layouts (`DatabasePlaceholderWidget`) with download CTAs across food logs, diary searches, barcode scanner, and AI meal capture.

### Changed
- **Footer Navigation Integration (All HTML files):** Added the new "Support" page link next to Privacy Policy and Imprint across all footers, inheriting identical styling, hover states, and font sizing.
- **Removed F-Droid Footer Link:** Cleaned up the footer by removing the "Android APK / F-Droid" link across all page footers to keep the bottom navigation focused.
- **Strict Non-Dismissible Health Pre-Permissions:** Refactored Sleep and Pulse settings pre-permission dialogues to be non-dismissible (removing "Cancel" / "Abbrechen", expanding action buttons to full width, and blocking dismiss gestures).
- **First Launch Database Sheet:** Added a cold-start prompt to invoke the dual-catalog download sheet once on onboarding/splash.
- **Relaxed Backup Import Constraints:** Permitted full backup imports as long as the base exercise database is initialized, removing locks if the nutrition database download was postponed.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Camera & Health Pre-Permission Refactoring for App Store Compliance (`scanner_screen.dart`, `permission_dialogs.dart`):** Refactored permission-request screens and dialogs to strictly comply with Apple App Store Review Guidelines 5.1.1(iv):
  - Made the Camera Pre-Permission screen non-dismissible by hiding the back button in the App Bar and blocking pop gestures / Android hardware back button.
  - Updated the Camera primary action button text from "Grant Permission" to "Continue" (localized across all supported languages).
  - Made the Steps/Health Pre-Permission dialog non-dismissible (disabling outside clicks, drags, and back gestures) and removed the "Cancel" option, leaving only a full-width "Continue" button.
- **Database Download Abort Loop:** Fixed a critical bug in `AppInitializerScreen` where manual triggers (e.g. "Jetzt herunterladen" or "Download Now") were aborted instantly due to an incorrect status check fallback.
- **Pulse Test Suite:** Updated `pulse_settings_screen_test.dart` to support the pre-permission flow.
- **Steps / Health Sync Lifecycle & Navigation Fix (`steps_sync_service.dart`, `diary_health_sync_coordinator.dart`, `steps_settings_screen.dart`, `steps_aggregation_repository.dart`):** Resolved issues where the app blindly triggered steps-sync or health-permission prompts during screen transitions:
  - Defaulted steps tracking setting to disabled (`false`) on fresh installs so background sync is not automatically triggered on startup.
  - Removed the implicit permission request from the steps repository `refresh()` method so background checks run silently and handle lack of permissions gracefully without prompting the user.
- **Barcode Scanner Crash on Camera Unavailable (`QRView.swift`, `scanner_screen.dart`):** Fixed a `SIGABRT` crash triggered whenever the camera could not be initialized (e.g. iOS Simulator, hardware failure):
  - Root cause: `QRView.swift` passed a raw Swift `Error` (bridged as `NSError`) as the `details` field of `FlutterError`. `FlutterStandardMethodCodec` cannot serialize `NSError` objects and asserts, aborting the process.
  - Fix: converted `error` to `error.localizedDescription` (a `String`) in the `catch` block of `startScan`. Applied via a local package override (`local_packages/qr_code_scanner_plus`) pending upstream patch in `qr_code_scanner_plus`.
  - Additional hardening in `scanner_screen.dart`: decoupled permission status-checking (`_checkPermission`) from permission requesting (`_requestPermission`) so the native QRView lifecycle is never entangled with the permission dialog. Added an `_isRequestingPermission` guard and inline spinner on the CTA button to prevent re-entrancy.
- **Onboarding Database Download Race Condition (`basis_data_manager.dart`):** Fixed a navigation race condition where tapping "Download" in the first-launch catalog prompt caused onboarding to advance immediately without downloading:
  - Root cause: the download button called `Navigator.of(ctx).pop()` inside the sheet closure, which immediately resolved the outer `await showGlassBottomMenu(...)` in `AppInitializerScreen._initialize()`, causing it to continue and navigate to `OnboardingScreen` before `AppInitializerScreen(isModal: true)` could be pushed.
  - Fix: the download button now returns `true` via `Navigator.of(ctx).pop(true)` (using the typed `showGlassBottomMenu<bool>` return value). The `AppInitializerScreen(forceUpdate: true, isModal: true)` push is performed sequentially after the sheet fully resolves, eliminating the race.
- **Pause Time Edit Resets Unsaved Exercise Values (`edit_routine_screen.dart`):** Fixed a critical state bug where saving a pause time change reloaded the full exercise list from the database, overwriting all in-progress user edits (reps, weight, RIR) with persisted values:
  - Replaced `_loadExercisesForRoutine()` call after pause time save with a targeted in-memory `setState` update using `RoutineExercise.copyWith(pauseSeconds: …)`, preserving all `TextEditingController` state.
- **Missing Drag Handle on Glass Pickers (`platform_adaptive_pickers.dart`):** Added a visual drag handle pill (`44×5`) to `_GlassPickerSheet`, matching the existing design in `_GlassBottomMenuSheet` for consistent sheet UX.
- **Pause Time Wheel Picker (`routine_pause_time_dialog.dart`, `live_workout_screen.dart`):** Replaced the `TextField` + `TimerInputFormatter` text input with an iOS-native `CupertinoTimerPicker` (minutes:seconds scroll wheel) for pause/rest timer editing:
  - Matches the glass picker styling used in the food-logging bottom sheets.
  - Refactored inline dialog code in `live_workout_screen.dart` to reuse `RoutinePauseTimeDialog`, eliminating duplicate text field and `StatefulBuilder` logic.
  - Removed unused `_parsePauseTime` helper and `time_util.dart` dependency from the dialog.

## [0.9.34] - 2026-06-21

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Live Workout Screen Layout & Spacing (`live_workout_screen.dart`):** Resolved layout alignment and spacing issues on the live workout screen:
  - Restored the bottom `Column` layout containing the rest timer bar and the Wger attribution widget.
  - Enforced a constant `32.0` logical pixel height wrapper for the attribution widget, preventing layout shifts when the text wraps to two lines on narrow screens.
  - Positioned the active rest timer bar and the active FAB at constant offsets (`bottom: 134.0` for the FAB), maintaining a perfect `8.0` logical pixel gap between them on all devices.
  - Configured `_LiveWorkoutFabShadowClipper` to clip the FAB's drop shadow exactly at `8.0` logical pixels below the FAB edge, making the shadow terminate cleanly at the top of the rest bar without translation offsets.
- **Active Workout Conflict Handling (`workout_hub_screen.dart`, `routines_screen.dart`, `main_screen.dart`, `glass_bottom_menu.dart`):** Handled the edge case where a user attempts to start a new workout while a workout session is already running in the background:
  - Introduced a glass-styled dialog (`showActiveWorkoutConflictDialog`) presenting options to resume the current workout, discard it, or cancel the action.
  - Intercepted workout start requests from the Workout Hub, Routines Screen, and the Main FAB menu to show the conflict resolution dialog when necessary.
  - Discarding an active workout cleanly deletes the previous workout log from the database and clears the view model session state, preventing mismatched active state errors.
  - Added localized strings for the conflict dialog in English, German, French, Italian, and Japanese.

## [0.9.33] - 2026-06-20

### Added
- **Platform-Adaptive Glass Pickers & Dropdowns (`platform_adaptive_pickers.dart`, `platform_adaptive_dropdown.dart`):** Introduced a unified, design-system-compliant date picker, time picker, and popup menu layer that renders glass-themed Material 3 dialogs on Android and native-feeling `GlassModalSheet` / `GlassMenu` overlays on iOS:
  - **`showAdaptiveDatePicker`:** Accepts `initialDate`, `firstDate`, `lastDate`, and optional `Locale`; renders a themed Material `DatePickerDialog` on Android and a `CupertinoDatePicker` spinner inside a `GlassModalSheet` with localized "Select Date" / "Select Time" confirm/cancel controls on iOS.
  - **`showAdaptiveTimePicker`:** Mirrors the date picker architecture with a `CupertinoTimerPicker` on iOS wrapped in glass-styled confirm/cancel chrome.
  - **`PlatformAdaptivePopupMenu<T>`:** A generic popup/context menu button that renders a Material 3 `PopupMenuButton` on Android and a `GlassMenu` morphing from the trigger icon on iOS, with support for optional leading icons and destructive-action styling per item.
  - All picker and dropdown callsites across the app — fluid/quantity/water dialogs, meal editor, supplement screens, measurement screens, goals screen, profile screen, AI settings, routine import, workout log detail, create exercise, onboarding slides — migrated from stock Flutter `showDatePicker`/`showTimePicker`/`PopupMenuButton` to these adaptive wrappers, delivering consistent Liquid Glass styling everywhere.
- **`SpringyScale` Widget (`springy_scale.dart`):** Added a reusable animated wrapper widget that provides a "springy" scale-down animation with haptic feedback when tapped or when its selection state changes. Used throughout the redesigned onboarding slides (goal cards, unit system options, welcome slide actions) to make interactive elements feel tactile and responsive.
- **Onboarding Localization Expansion:** Added 40+ new localization keys and translations across all five supported languages (English, German, French, Italian, Japanese) for the redesigned onboarding flow, covering goal descriptions, unit system explanations, profile prompts, and welcome slide content.

### Changed
- **Settings Appearance — Theme Mode Dropdown (`appearance_settings_screen.dart`):** Replaced the previous dark/light mode toggle switch with a fully localized dropdown menu (`System`, `Light`, `Dark`), integrated with the new `PlatformAdaptivePopupMenu`, providing clearer theme state communication and a cleaner settings layout.
- **Main Screen FAB Animation Overhaul (`main_screen.dart`, `speed_dial_menu_overlay.dart`):** Refactored the floating action button and speed-dial menu overlay with improved animation curves, smoother morphing transitions, and better overlay dismissal behavior — delivering a more polished and responsive FAB experience on the main screen.
- **Onboarding Complete Overhaul (`onboarding_screen.dart`, all onboarding slide widgets):** Redesigned the entire onboarding flow with a modern, polished aesthetic:
  - **Welcome Slide:** Added a drop shadow to the app logo, refined typography and spacing, and improved the "Get Started" CTA with springy-scale interaction.
  - **Profile Slide:** Refined layout, added localized descriptive text, and improved input field styling.
  - **Goal Slide:** Replaced static goal cards with `SpringyScale`-wrapped interactive tiles featuring haptic feedback, spring animations on selection, and localized goal descriptions; added a "Continue" confirmation button.
  - **Unit System Slide:** Completely redesigned from a basic toggle into a visually rich dual-card layout with `SpringyScale`-wrapped metric/imperial options, animated selection transitions, and localized unit descriptions.
  - Unified all slides under consistent glass-styled containers, adaptive padding, and platform-appropriate picker/dropdown usage.
- **Food Detail Screen Refinements (`food_detail_screen.dart`):**
  - **App Bar Redesign:** Improved the app bar layout with better spacing, icon placement, and adaptive styling for a cleaner header.
  - **Vegan/Vegetarian Badge:** Enhanced the dietary preference badge with improved iconography, refined color treatment, and better alignment within the nutrition header.
  - **General Layout Polish:** Refined spacing, divider placement, and scroll behavior throughout the nutrition detail view.
- **Recommendation Banner Color Fix (`recommendation_banner.dart`):** Adjusted the banner's background and text color values to ensure proper contrast and readability in both light and dark themes.
- **Glass Progress Bar Coloring (`glass_progress_bar.dart`):** Tweaked the progress fill color treatment for improved visibility and consistency with the Liquid Glass design system.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Live Workout Rest Timer & FAB Padding (`live_workout_screen.dart`):** Fixed incorrect bottom padding on the rest timer bar and glass FAB overlay, resolving a layout issue where these elements could overlap with the safe area or be clipped on devices with home indicators.
- **iOS Podfile (`Podfile`):** Resolved an iOS build configuration issue in the CocoaPods Podfile that affected dependency resolution.
- **Test Suite Stability:** Fixed test regressions in `platform_adaptive_recommendation_settings_flow_test.dart` and `workout_log_detail_reactive_test.dart` to align with the new adaptive picker and dropdown architecture.

## [0.9.32] - 2026-06-16

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **`isFluid` Detection Overhaul — Beverage vs. Non-Beverage Classification (Data Forensics):** Completely rewrote the fluid-detection pipeline that determines whether a food item triggers the liquid-tracking UI. A forensic audit of the Open Food Facts parquet dataset revealed that **~30 % of products in the bundled DB** (≈70,500 items) were incorrectly flagged as beverages, including Tabasco, Sriracha, Ketchup, Mustard, BBQ Sauce, Soy Sauce, Balsamic Vinegar, Salad Dressings, Mayonnaise, Ice Cream, Olive Oil, Chicken Broth, Peanut Butter, and Hazelnut Spread:
  - **Root cause:** The old heuristic in `create_off_food_db.py` used `product_quantity_unit ∈ {ml, l, cl}` as the sole primary trigger, with no category-based veto. Sauces, vinegars, and desserts — which routinely carry volume units — bypassed the category check entirely.
  - **Three-tier algorithm:** Replaced both the Python DB generator (`script/create_off_food_db.py`) and the Dart runtime layer (`lib/core/infrastructure/basis_data_manager.dart`) with a unified allowlist → blocklist → volume-unit-fallback heuristic:
    - **Tier 1 – Allowlist:** If any `categories_tags` entry contains a verified beverage taxonomy substring (`en:beverages`, `en:waters`, `en:fruit-juices`, `en:beers`, `en:wines`, `en:teas`, `en:coffees`, `en:milks`, `en:smoothies`, etc.), the product is a beverage candidate.
    - **Tier 2 – Blocklist (decisive veto):** If any `categories_tags` entry exactly matches a known non-beverage tag (`en:condiments`, `en:sauces`, `en:ketchup`, `en:vinegars`, `en:soups`, `en:ice-creams`, `en:creams`, `en:spreads`, `en:fats`, `en:oils`, `en:snacks`, `en:meals`, `en:dietary-supplements`, etc.), `isFluid` is forced to `false`, overriding any Tier 1 match.
    - **Tier 3 – Volume-unit fallback:** Only applied when `categories_tags` is entirely absent; uses `product_quantity_unit` as a weak heuristic (same as before).
  - The fix covers both the bundled DB (effective on the next GitHub Actions release build) and all products discovered live via the OFF barcode scanner API (effective immediately).
- **Portion Selector Initialization Fix (`food_detail_screen.dart`):** Resolved an initialization bug where opening food items via the General Food Explorer instead of a Diary Log caused the portion selector to display "Portion (100g)". The local state initialization now correctly extracts the `productQuantity` serving size from the `FoodItem` model into `_trackedQuantity` and sets the default view option (`_showPer100g`) accordingly when portion info exists.

### Changed
- **Nutrition Portion-Scaling View Refactor (`food_detail_screen.dart`):** Refactored the portion-scaling UI into an ultra-compact, high-fidelity inline control to reduce vertical layout height by ~68px:
  - **Inline Segmented Control:** Replaced the heavyweight `SummaryCard` container, its 16px gap, and the detached text heading with a unified horizontal `Row`. This row houses a custom `GlassPillButton` segmented toggle sitting inline next to the localized heading.
  - **L10n Multi-Language Support:** Fully localized the dynamic portions header with custom key structures (`nutritionPer100g`, `nutritionPerPortion`) across English, German, French, Italian, and Japanese `.arb` translation tables.
  - **Layout Constraints & Visibility Heuristics:** Resolved visual layout bugs by adjusting portion toggle guards to support scaling for any food with a `productQuantity > 1.0`, regardless of whether the product was accessed via the Diary or the Food Catalog.


## [0.9.31] - 2026-06-15
### Added
- **Android Website Release & Centralized Link Routing:** Upgraded the product website (`docs/`) to add explicit, premium Android and F-Droid release links alongside existing iOS and FOSS deployment options:
  - **Centralized Routing Contract:** Implemented a unified `APP_LINKS` registry in `docs/script.js` to dynamically bind URLs across all HTML files via `data-link` attributes, decoupling structural markup from hardcoded links.
  - **Parallel Hero CTAs:** Integrated a new primary "Download for Android" button next to the iOS TestFlight CTA using a custom Lucide-style download icon. Preserved Obtainium as a secondary glass button.
  - **Navigation & Footer Links:** Added an "Android APK" header nav-link and an "Android APK / F-Droid" footer link next to the existing GitHub links across all subpages.
  - **Localization Invariants:** Localized all new CTA elements and links across English, German, French, Italian, and Japanese translations in `docs/script.js`.
- **Custom Foods Parity & Database CRUD:** Mirrored the robust "Custom Exercise" functionality into the Nutrition module to allow user-created custom food items:
  - Implemented visual indicators with a styled "Custom" badge next to food names in search results and `FoodDetailScreen`.
  - Added an "Eigene Lebensmittel" ExpansionTile on the nutrition dashboard landing page.
  - Implemented full SQLite CRUD repository pipelines for user-created custom foods with backup/restore support.
- **Macro-based Calorie Calculator & Caffeine Exposure:**
  - Added a dynamic calorie calculator hook (`(Protein * 4) + (Carbs * 4) + (Fat * 9)`) in the Create/Edit Food screen, triggerable via a new rotate icon next to the calories input field.
  - Exposed the database-backed `caffeine` metric in food input forms and detail screens.

### Changed
- **App-wide Localization Audit & Hardcoded German String Elimination:** Audited and refactored multiple UI and service layers to completely clean and translate hardcoded German text literals across English, German, French, Italian, and Japanese:
  - **Dynamic Progress Mapping in App Initializer:** Implemented a dynamic lookup mapper `_getLocalizedProgress` in `app_initializer_screen.dart` to translate raw German progress/status strings streamed from `BasisDataManager` (e.g., "Prüfe Übungen...", "Basis-Produkte", "Kategorien", and entry counts) at the UI boundary.
  - **Localized Import Defaults:** Refactored `import_manager.dart` and `data_management_screen.dart` to accept dynamic, localized fallback workout and exercise titles (via `l10n.importedWorkout` and `l10n.unknownExercise`) rather than hardcoded German fallbacks.
  - **Profile Semantics:** Translated the hardcoded `'Profile'` semantics label in the app bar to `l10n.profile` in `main_screen.dart`.
  - **Extended Translations:** Added all corresponding localization keys, placeholders, and definitions to the `app_*.arb` files and regenerated localizations successfully.
- **Website CTA Icon Swap & F-Droid / Obtainium Vector Assets:** Corrected the download CTA button icons on the homepage:
  - Embedded the official Inkscape-cleaned F-Droid Client vector SVG logo on the F-Droid button.
  - Embedded the official colored Obtainium vector SVG logo (cropped to bounding viewBox) on the Obtainium button.
- **Liquid Glass Design System Performance Hardening:** Implemented a systemic plan to eliminate scroll-stutter, input lag, and rendering invalidations caused by backdrop filter overlays and layout-thrashing:
  - **Global Render Isolation:** Wrapped central glass components and direct `BackdropFilter` instances in `RepaintBoundary` widgets. This forces the Flutter engine to cache backdrop filter pixel-blur buffers on the GPU, preventing surrounding viewport scroll offsets or animations from forcing the GPU to re-evaluate the background pixels on every frame. Affected widgets include `GlassFab`, `GlassPillButton`, `GlassBottomMenu` main cards and option tiles, `RunningWorkoutOverlay` container, `GlobalAppBar`, `RecommendationBanner`, `PRCelebrationBanner`, `SpeedDialMenuOverlay`, and localized water logging dialogs.
  - **Structural Layout Decoupling:** Refactored main screens to completely decouple floating/sticky bottom navigation and action bars from the main scroll views. Removed standard `Scaffold` properties (`bottomNavigationBar` and `floatingActionButton`) from `live_workout_screen.dart` and `edit_routine_screen.dart`, instead moving those floating layers into the body `Stack` layout as Layer 2 overlays. Wrapped scrollable viewports (Layer 1) and bottom overlays (Layer 2) in separate `RepaintBoundary` widgets, isolating their layout and paint operations.
  - **Safe-Area Content Padding:** Adjusted scroll view bottom content paddings dynamically to accommodate both safe-area heights and floating bar overlays, ensuring that list items at the end of lists are never permanently clipped or covered by the bottom bar.
  - **Main Screen Render Isolation:** Wrapped `Scaffold` (holding all page views), the running workout overlay, and the bottom navigation bar / FAB layout in `main_screen.dart` inside separate `RepaintBoundary` layers, completely decoupling page scrolls from floating menu repaints.
- **LucideIcons:** migrated the last missing Cupertino icon to icon from LucideIcons.
- **Unified Food Search Viewport:** Replaced the multi-tab food search layout with a unified single-scroll track viewport, grouping search results sequentially into three vertical sections: Custom Food matches, Base Food matches, and Other/Open Food Facts matches.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **AI Meal Capture Image Layout:** Fixed a layout issue where the horizontal image preview list was constrained by the screen's outer padding. Removed horizontal padding from the parent scroll view and applied it directly to the list container and label, enabling edge-to-edge scrolling for captured meal images.
- **Exercise Catalog Never Seeding (Critical):** Resolved a three-layered bug that caused the entire wger exercise catalog to remain empty on fresh installs and after iOS sandbox resets:
  - **Missing bundled asset:** `assets/db/train_libre_training.db` was a 0-byte placeholder file. The bundled SQLite database is now populated from the latest stable wger release (`202606151047`, 852 exercises). Added a 0-byte guard in `BasisDataManager` that aborts the import with a clear error instead of silently opening an empty database.
  - **Relational schema not handled:** The asset DB stores translations in a separate `exercise_translations` table, but `_mapExerciseBundle` only handled the legacy flat-column format (`name_de`/`name_en` on the exercise row). As a result, all 852 exercises were inserted with zero translations, making them invisible to `searchExercises` (which LEFT JOINs on translations). Added a dedicated relational translation pass in `_performBatchImport` that reads `exercise_translations` directly from the source DB after the exercise loop completes.
  - **Stale pref after partial import:** After previous broken imports (exercises present, translations absent), `_keyVersionTraining` in SharedPreferences reflected an up-to-date version, preventing any re-import. Added a translation health-check in `checkForBasisDataUpdate` that detects when the translation count is below the exercise count and forces a full re-seed by clearing the stored version key. Also updated the bundled `wger_catalog_manifest.json` to match the current stable release.
- **Edit Routine Screen Layout Polish:**
  - Reduced the vertical gap between the routine name field and the exercise list divider (`spacingM` → `spacingXS`) to eliminate the excessive blank space below the input.
  - Moved the `WgerAttributionWidget` out of a free-floating `Align(bottomCenter)` overlay (which was visually overlapping the Add Exercise FAB) into a `Positioned(bottom: 8 + safeAreaBottom)` layer, pinning it cleanly below the safe area without colliding with the FAB.
- **Exercise Catalog Screen Layout Polish:**
  - Reduced the search bar vertical padding from `24px` to `8px` (top and bottom) and removed the redundant `spacingS` gap above the search row, bringing the search field tight against the app bar.
  - Aligned the `WgerAttributionWidget` text style with `live_workout_screen` by adding a drop shadow (`Shadow` with 50 % opacity, 1×1 offset, 4px blur).
  - Refactored the screen `body` from a plain `Column` to a `Stack`, placing the wger attribution as a `Positioned` widget at the bottom of the safe area — preventing it from being obscured by or clashing with the \"Create Custom Exercise\" FAB.
- **Food Search Tile Brand Overflow:** Fixed a critical horizontal RenderFlex overflow caused by long brand names (e.g., "Flying Goose Brand") clipping calorie metrics in search results:
  - Re-architected subtitle layouts across `FoodItemSearchTile`, `GeneralFoodSelectionScreen`, and `FoodExplorerScreen` list items to position calorie and volume metrics (`[X] kcal / 100g`) at the absolute left of the subtitle row.
  - Placed a bullet separator (` • `) between calorie text and brand name, and wrapped the brand text widget in an `Expanded` layout with `TextOverflow.ellipsis` and `maxLines: 1` to safely truncate long brand names.

## [0.9.30] - 2026-06-15
### Changed
- **Viewport Scroll Performance & Layout Isolation (Issue #457):** Eliminated scroll-stutter and frame drops during active scrolling:
  - Added `cacheExtent: 1500` to `ReorderableListView.builder` inside both `EditRoutineScreen` and `LiveWorkoutScreen` to pre-render exercise and set input cards off-screen, shifting CPU and GPU work away from active scrolling frames.
  - Refactored `DiaryScreen` main `ListView` to `CustomScrollView` with layout-isolated slivers. Placed the upper dashboard (macros, summaries) in a `SliverToBoxAdapter` wrapped in a `RepaintBoundary`, and isolated the weight custom-painter chart in its own sliver/repaint boundary, preventing layout changes in the active food log from invalidating cached GPU textures.
  - Conducted a global scroll performance audit and implemented viewport pre-rendering (`cacheExtent: 1500`) on candidate list views in `workout_history_screen.dart`, `exercise_catalog_screen.dart`, `food_explorer_screen.dart`, `add_food_screen.dart`, and `general_food_selection_screen.dart`.
  - Added `RepaintBoundary` wrappers to isolate repaint logic for complex body maps, vector diagrams, and charts in `recovery_tracker_screen.dart`, `muscle_group_analytics_screen.dart`, `consistency_tracker_screen.dart`, `body_nutrition_correlation_screen.dart`, `exercise_detail_screen.dart`, and `statistics_hub_screen.dart`, caching GPU raster layers and preventing layout invalidation cascades.
- **Live Workout FAB Layout & Shadow Clipping:** Resolved excessive bottom spacing of the Floating Action Button (`GlassFab`) on `LiveWorkoutScreen` and fixed drop shadow bleed overlapping the bottom rest timer bar:
  - Removed manual bottom padding calculations from `_LiveWorkoutFabState`, allowing `Scaffold`'s layout system to natively place the FAB exactly `16.0` logical pixels above the bottom bar.
  - Implemented a dynamic `Transform.translate` downward translation of `8.0` logical pixels and a custom shadow clipper `_LiveWorkoutFabShadowClipper` when the rest timer bar is active. This narrows the spacing to exactly `8.0` logical pixels to match the Diary Screen's bottom layout, while cleanly cropping the drop shadow at the rest bar's top edge to prevent overlapping visual smudges.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Profile Picture Lazy Loading on Startup:** Resolved an issue where the profile picture avatar in the main screen app bar did not load on a fresh app startup unless the user manually navigated to another screen. Added a reactive `Consumer<ProfileService>` wrapper around the avatar to dynamically update as soon as the asynchronous profile service initialization completes.

## [0.9.29] - 2026-06-14
### Added
- **Dynamic Time-Based Meal Pre-Selection (Issue #460):** Added a new quality-of-life feature that maps the current system hour dynamically to the most logical meal type: Breakfast (05:00 - 10:59), Lunch (11:00 - 15:59), Dinner (16:00 - 20:59), and Snack (21:00 - 04:59). Integrated the helper across the global FAB food-adding flow and natural language logs.
- **Natural Language Meal Keyword Detection (Issue #460):** Added a keyword-matching utility inside the AI meal capture pipeline (`ai_meal_capture_screen.dart`) that scans user input description text for meal mentions (e.g. "breakfast", "Frühstück", "Lunch", "Mittagessen", "dîner") in English, German, French, Italian, and Japanese, falling back to the time-based pre-selection if no keyword is found.
- **Maestro Screenshot Translation Bridge:** Added a robust utility script at `script/sync_screenshots.sh` that automatically maps, renames, and stage-copies raw Maestro screenshot outputs (supporting name-based matching and alphabetical fallback) to our permanent assets. Supports atomic overwrites and stale file cleanup under `fastlane/metadata/android/.../phoneScreenshots/` to prevent bloated store packages, and integrates with the Pillow-based framing script (`generate_store_screenshots.py`) via a temporary workspace to generate framed screenshots dynamically.
- **F-Droid App Registry Configuration:** Added a minimalist F-Droid app registry configuration at `fdroid/metadata/com.rfivesix.trainlibre.yml` to declare categories, GPL license, website, source code repository, and issue tracker links.
- **Themed Muscle Focus Highlights Utility:** Added an in-app utility `MuscleColorHelper` that maps raw or slug-based muscle workloads dynamically to 5 dynamic alpha/saturation tiers of the active theme's primary color (`0.15`, `0.35`, `0.55`, `0.75`, and full intensity `1.0`), ensuring complete visual unification with the premium Liquid Glass style.

### Changed
- **Performance Hardening of Core Screens (Issue #457):** Resolved residual micro-stutters, frame drops, and input latency under heavy loads on the `DiaryScreen`, `EditRoutineScreen`, and `LiveWorkoutScreen` by benchmarking against the rendering architecture of the `StatisticsScreen`:
  - Implemented a 16ms coalescing debounce timer and a serialization lock (`_isCalculating` and `_needsReRun`) in `DiaryViewModel._updateCalculatedState()` to batch database watcher stream events and eliminate overlapping async query races.
  - Isolated keyboard view inset changes by refactoring global `MediaQuery.of` calls to `MediaQuery.paddingOf` and extracting the keyboard Done bars and FAB elements into private, isolated stateless widgets listening only to `MediaQuery.viewInsetsOf`. This prevents rebuilding the entire reorderable list of exercises, cards, and input rows during keyboard transitions.
  - Eliminated full-tree repaints on `LiveWorkoutScreen` by removing the legacy ViewModel listener and `setState` loop from `initState`/`dispose`. Workout and rest timer ticks are now isolated to lightweight `Consumer` and `AnimatedBuilder` elements, leaving the list of exercises and set inputs completely static.
- **Diary Card Preservations (Issue #460):** Preserved explicit localized card overrides (e.g. tapping the `+` action button inside the dedicated Breakfast, Lunch, or Dinner cards) by strictly forwarding their hardcoded context and bypassing the time-based fallback logic.
- **Workout Share Card Muscle Focus (Issue #455 & #456):** Replaced the legacy cluttered radar graph painter (`_ShareRadarPainter`) with front and back side-by-side `BodyHighlighter` widgets dynamically shaded in theme-reactive primary colors.
- **Analytics & Recovery Screen Layouts (Issue #455 & #456):** Deleted the obsolete `MuscleRadarChart` widget and stripped out all top-level tab controller wrappers and TabBars. Distribution heatmaps and status maps are now rendered directly side by side inside the cards.
- **Recovery Screen Isolation:** Fully isolated the Recovery Screen's body maps from the theme color unification, explicitly retaining its original readiness color codes (Green for fresh, Yellow/Orange for fatigued, Red for sore) to preserve its diagnostic capability.
- **Workout Detail & Summary Heatmaps:** Updated the workout summary heatmap and workout log detail heatmap blocks to shade muscle activation groups using `MuscleColorHelper`.
- **Draft-Based GitHub Release Workflow:** Refactored `script/deploy_release.sh` to generate the GitHub Release container as a draft (`--draft`), upload compiled assets, and publish the release (`gh release edit --draft=false`) only when all uploads are fully complete. This eliminates the race condition where the F-Droid update pipeline triggered before APK binaries finished uploading.
- **Dynamic Fastlane Metadata & Changelogs:** Configured `.github/workflows/fdroid-repo.yml` to copy the Fastlane metadata folders dynamically to the F-Droid workspace, allowing `fdroid update` to natively import descriptions, summaries, and store graphics. Added a Python script to parse the active build number from `pubspec.yaml` and dump the dynamic GitHub Release notes directly into localized Fastlane changelogs.
- **Dynamic iOS Build Number Injection:** Refactored `ios/fastlane/Fastfile` to parse the active build number from the root `pubspec.yaml` and configure it dynamically using `increment_build_number` before uploading to Apple TestFlight.

## [0.9.28] - 2026-06-13
### Changed
- **Liquid Glass Rest Timer Bar:** Upgraded the visual styling of the bottom rest timer bar on the live workout screen to use the premium liquid glass design system. Configured the countdown bar and green completion banner in a `SizedBox` and inner `Container` of exactly `74.0` height and `37.0` border radius to match `GlassFab` layout dimensions. Wrapped them in `GlassAdaptiveScope`, `AdaptiveGlass`, `GlassGlow` using `DesignConstants.liquidGlassSettings` and unified neutral tint (`DesignConstants.glassNeutralTint`) or green glass color mapping. Integrated `ShadowOuterClipper` to clip drop shadows from behind the transparent glass elements.
- **Workout Screen Rebuild Performance Optimization:** Significantly optimized the `LiveWorkoutScreen` rendering pipeline to minimize unnecessary widget rebuilds:
  - Refactored the root `LiveWorkoutScreen` to consume state reactively via granular `context.select` wrappers (for `isLoading`, `isActive`, `routineName`, `exercises`, and `showRestBar`) instead of an all-encompassing `context.watch<LiveWorkoutViewModel>()` subscription.
  - Wrapped `WorkoutSummaryBar` in a localized `Consumer` so duration, volume, and progress updates rebuild only the summary bar rather than the entire screen.
  - Wrapped each exercise row card in a `RepaintBoundary` to optimize GPU raster cache.
  - Isolated the set templates list of each exercise within a targeted `Selector<LiveWorkoutViewModel, Map<int, SetLog>>` with custom equality checks (`shouldRebuild` checking changes to `setType` and `isCompleted`), ensuring set interactions only rebuild the specific exercise card's sets rather than refreshing the entire page.
- **Diary Screen Rebuild & Scroll Performance Optimization:** Optimized the rendering and scrolling performance of the diary screen (`DiaryScreen`) to eliminate lag and frame drops when viewing days with a large amount of logged entries:
  - Replaced the root `context.watch<DiaryViewModel>()` with a non-listening `context.read<DiaryViewModel>()` and granular `context.select(...)` observers for configuration toggles (Steps, Sleep, Pulse, Workouts).
  - Wrapped card components (Nutrition, Supplements, and Workout summaries) in targeted `Selector` widgets to isolate rebuilds.
  - Converted the inline meal card and fluid card builders into self-contained private stateful widgets (`_MealCard` and `_FluidsCard`) with localized expansion states, preventing screen-wide repaints when cards are toggled.
  - Implemented deep collection equality helpers in selectors to prevent redundant card rebuilds.
  - Wrapped `_MealCard`, `_FluidsCard`, `StepsSummaryCard`, `SleepSummaryCard`, `PulseSummaryCard`, and `WeightChartCard` in `RepaintBoundary` widgets, caching complex card layouts and chart canvas vectors on the GPU to ensure butter-smooth scrolling.

## [0.9.27] - 2026-06-13
### Added
- **Austria ('at') OFF Database Region Integration:** Added support for Austria (`at`) to the Open Food Facts (OFF) database compiler pipeline, automatic weekly refresh workflows, and the client application settings screen, complete with German language fallback resolution and full localized descriptions in English, German, French, Italian, and Japanese.
- **Microwave-Style Digit Entry Pattern:** Implemented a new intuitive microwave-style digit entry pattern for workout rest timers in both the active workout edit dialog and the routine builder edit dialog. It restricts inputs to digits using a numeric keypad and automatically formats inputs right-to-left (e.g. typing `5` formats to `00:05`, `130` to `01:30`).
- **Rest Timer Suffix Clear Button:** Added a red accent clear button (`Icons.clear` with `Colors.redAccent`) inside the duration input field decoration. Tapping it instantly clears the text and disables the rest timer.
- **Cardio Set Time Input:** Integrated the microwave-style digit entry pattern (`TimerInputFormatter` mapping right-to-left `MM:SS`) for cardio sets in the active workout (`LiveWorkoutSetRow`), the routine builder template builder (`RoutineSetRowWidget`), and the log editor (`WorkoutLogSetRow`), using a numeric keyboard for quick input.
- **Cardio Distance Decimal Formatting:** Optimized cardio distance input to stay in km and display up to 3 decimal places without trailing zeros (e.g. `1.234` or `1,234`), supporting parsing of both dots and commas.
- **Interactive OFF Region Search:** Added a minimalist, reactive search bar inside the Open Food Facts region selection bottom sheet to filter supported countries dynamically by name or country code, optimizing navigation density as the catalog list expands.

### Changed
- **Base Food Startup Initialization Gating:** Optimized the startup pipeline for the base food database (`train_libre_base_foods.db`) and categories by gating checks on the runtime app build number (`packageInfo.buildNumber`), completely eliminating expensive asset file copy, open, and query overhead when launching the application on the same app build.
- **Database Versioning Alignment:** Aligned the base food database version checks to mirror the OFF catalog versioning mechanism, storing the migration state locally and bypassing write transactions if the asset database version matches the installed version.
- **Routine Editor Rest Timer Alignment:** Replaced the separate text display and timer icon in the routine builder exercise card with a unified rest timer button (matching the active workout screen's design) which displays the formatted rest duration text button (e.g. `01:30`) if configured, or the standard timer icon button if empty.
- **Global Rest Duration Format:** Updated all rest timer duration displays and labels across both active workout and routine building screens to show formatted minutes and seconds (`mm:ss` like `01:30` and `00:10`) instead of raw seconds (like `90s` and `10s`).
- **Cardio Log View Formatting:** Updated the log details screen (`WorkoutLogDetailScreen`) and set row (`WorkoutLogSetRow`) to format distance with up to 3 decimal places and duration as `MM:SS` format.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Foreground Rest Timer Notifications:** Configured local notifications shown when the app is in the foreground to play sound and vibrate without presenting a visual heads-up drop-down banner (via `DarwinNotificationDetails` alert silencing on iOS, and a dedicated auto-canceling channel with default importance and priority on Android).
- **Foreground Sound Cut-off:** Extended the auto-cancel delay for foreground notifications to 10 seconds to allow the notification sound and vibration pattern to play to completion before the notification is cleared from the system.
- **Vibration Settings Compliance:** Wired rest timer notification details to retrieve and check the global `haptics_enabled` preference from `SharedPreferences`, ensuring notification vibrations respect the user's settings.
- **Routine Builder Clear Rest Timer:** Fixed a bug in the routine builder edit dialog where saving an empty rest duration did not update the database, preventing users from clearing and disabling configured rest timers.

## [0.9.26] - 2026-06-12
### Changed
- **Global Lucide Icons Migration:** Replaced all 387+ instances of legacy native Material icons across the entire `lib/` directory with crisp, unified vector icons from the Lucide Icons library via an automated regex refactoring pipeline. This eliminates platform-dependent emoji rendering discrepancies, enforces a cohesive, modern visual language across all feature tabs (Diary, Workout, Settings, Profile, Analytics), and significantly streamlines the application's minimalist design identity.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Markdown Export Accuracy:** Fixed a critical bug where beverage nutrition (calories, sugar, carbs) was double-counted when logged as both food and fluid.
- **Fluid Calorie Calculation:** Corrected an error in the share service where fluid calories were incorrectly scaled by quantity, leading to inflated totals.
- **Nutrition Summary Metrics:** Added daily user targets (Calories, Protein, Carbs, Fat, Sugar, Water) to the Markdown export summary, matching the interactive Diary UI format.
- **Date-Specific Goals:** Ensured the Markdown export uses historical goal snapshots from the database to reflect the targets active on the specific day shared.

## [0.9.25] - 2026-06-12
### Added
- **Diary Day Export & Sharing Hub:** Introduced a comprehensive "Day Export" feature directly accessible via a new context sheet in the Diary screen, allowing users to share their daily logs in two distinct formats:
  - **Visual Image Export:** Generates a high-resolution PNG snapshot of the top macro, calorie, water, and sugar summary cards using a native `RepaintBoundary` composition render tree, routing it seamlessly into the native system share sheet.
  - **Granular Localized Markdown Export:** Compiles a deep-dive, human- and LLM-readable Markdown document containing full nutritional breakdowns per food item (including sugar, salt, and fiber), total fluid intake tracking, complete workout logs with routine names, weights, and RIR/RPE metrics, as well as a full sleep analysis.
- **Detailed Sleep Phase & Timing Mapping:** Enhanced the text export data engine to fetch and extract exact falling-asleep and waking-up timestamps alongside floating-point duration metrics for all tracked sleep phases (Deep, Light, REM, and Awake/Interruptions).
- **Multi-Region Localization Strings:** Fully localized all day-sharing components, summary headers, and placeholder metrics across English, German, French (`app_fr.arb`), Italian (`app_it.arb`), and Japanese (`app_ja.arb`) resource bundles to ensure strict compliance with the global localization pipeline.

### Changed
- **Decoupled Exercise / Wger Catalog Sync:** Extracted the exercise database sync and update logic from the default automatic startup path (`checkForBasisDataUpdate()`) into a new public `importExerciseCatalog()` method. The exercise database is now only updated when manually triggered by the user or during database initialization, preventing startup slowdowns.
- **Unified Settings Sync Action:** Combined the exercise update action with the manual food database update card in Settings, which now triggers a sequential update of both the food and exercise databases with unified progress tracking.
- **Refactored Interactive Diary AppBar:** Streamlined the top navigation layout of the main Diary scaffold to maximize interactive ergonomics and reduce visual noise:
  - Transformed the static date title into a fully interactive core navigation control, wrapping the left and right date-increment chevrons (`Icons.chevron_left` / `Icons.chevron_right`) directly around the central date string.
  - Converted the date string itself into a trigger target that invokes the primary calendar date picker sheet upon touch, completely eliminating the redundant central calendar icon button.
  - Relocated and consolidated all primary trailing actions cleanly into the right header container, positioning the new `Icons.share_outlined` button immediately to the left of the static profile picture avatar.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Sleep Sync Freeze & Progress Bar Repair:** Resolved a database deadlock that froze the manual 90-day Sleep Sync at the last iteration (e.g. "Importing Night 58/58...") by removing nested `_db.transaction(...)` blocks from the custom sleep database access objects (`SleepRawImportsDao`, `SleepCanonicalSessionsDao`, `SleepCanonicalStageSegmentsDao`, `SleepCanonicalHeartRateSamplesDao`, `SleepNightlyAnalysesDao`). Refined the pipeline progress calculation to allocate `totalSessions + 5` total steps and report an out-of-bounds progress value (`-1.0`) at initialization, enabling an active indeterminate scanning animation during heavy background isolate calculations before transitioning to determinate progress updates through the database writing phase.
- **Multilingual Database Sync Labels:** Updated settings database sync labels (`settingsUpdateFoodDatabase`, `settingsUpdateFoodDatabaseSubtitle`, `settingsUpdateFoodDatabaseSuccess`, `settingsUpdateFoodDatabaseError`) in Japanese (`app_ja.arb`) to refer to both the food and exercise databases rather than just the food database, aligning with German, English, French, and Italian translations.

## [0.9.24] - 2026-06-12
### Added
- **Unified Long-Running Operation UI & Cooperative Cancellation:** Introduced a reusable progress overlay (`LongRunningOperationOverlay`) wrapping operations in `PopScope(canPop: false)` to prevent route popping. Added `CancellationToken` and `OperationCanceledException` utilities to support cooperative cancellation of intensive background tasks.
- **Multilingual Support for Progress States:** Integrated fully localized progress strings across German, English, French, Italian, and Japanese resource bundles for all long-running stages.

### Changed
- **Optimized Sleep Import Windowing:** Re-introduced a rolling 72-hour delta-sync lookback window for standard UI and Diary interactions to keep page transitions fluid and prevent main-thread lag.
- **Manual Deep History Sync:** Explicitly delegated historical syncs (90 days) to a manual action via the Sleep Settings screen using a new `forceFullSync` parameter.
- **Transactional Backup & Import Safety:** Updated the database backup export/import features to accept cancellation tokens and report table-level progress. Extended backup import to execute inside a single Drift SQLite transaction with savepoints to guarantee an atomic database rollback if canceled.
- **Preferences State Rollback:** Implemented automatic state restoration for `SharedPreferences` if a backup import operation is cancelled mid-way.
- **Test Suite Realignment:** Updated mock test classes (`FakeSleepImportService` and `_FakeSleepSettingsService`) across the widget and unit test suites to align with the updated `importRecent` method signature.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Health Connect Permissions Crash (`ActivityNotFoundException`):** Patched a native Android runtime crash caused by unsupported contract intents when requesting permissions under the standard `FlutterActivity`. Refactored `MainActivity.kt` to dispatch requests using the native `ActivityCompat.requestPermissions` utility and handle results uniformly in `onRequestPermissionsResult` and `onActivityResult`.
- **Static Analysis Warnings:** Resolved unused fields and variables (`_isFullBackupRunning`, `_isSleepImporting`, and `unknown` exercise list) and addressed `use_build_context_synchronously` warnings across settings screens using `context.mounted`.
- **Android Predictive Back Gestures:** Resolved a platform-specific issue where the native predictive back gesture would fail or freeze on Android/GrapheneOS devices. Refactored the core Android container `MainActivity` to inherit from the standard `FlutterActivity` instead of `FlutterFragmentActivity`, eliminating fragment lifecycle dispatcher conflicts. Ported the internal Health Connect permissions launcher and Storage Access Framework directory picker launcher to use the base SDK `startActivityForResult` and `onActivityResult` callbacks to maintain full compile-time compatibility with standard activity lifecycles.
- **Sleep Data Import Ingestion (7 out of 90 nights):** Resolved a critical bug causing long historical imports to starve or skip valid entries by correcting lookback window truncations.
- **Idempotent Sleep Session Overlaps:** Refactored overlapping session rules to prevent shorter naps or duplicate records from being completely discarded. Non-enveloping sleep sessions can now safely coexist, and identical boundaries trigger precise updates instead of omissions.

## [0.9.24-beta.1] - 2026-06-09
### Added
- **Nested Locked Glassmorphic Adaptive Scopes**: Introduced nested, locked `GlassAdaptiveScope` wrappers (`minQuality: GlassQuality.premium, maxQuality: GlassQuality.premium`) around the bottom navigation bar, workout overlay, and FAB. This prevents these core elements from being downgraded by the performance-driven global adaptive quality ceiling during frame-dropping screen transitions.
* **Global App Localization (FR, IT, JA):** Expanded native multi-language support across the entire frontend architecture, incorporating over 1,300 fully translated keys per language (`app_fr.arb`, `app_it.arb`, `app_ja.arb`).
* **Dynamic Web Template i18n:** Implemented client-side localized script dictionaries within `docs/script.js` and expanded selection dropdowns across all HTML compliance pages (landing page, privacy, terms, recovery, etc.).
* **Targeted Country Pipelines:** Upgraded the Open Food Facts pipeline (`create_off_food_db.py`) to generate dedicated localized SQLite asset databases for France (`fr`), Italy (`it`), and Japan (`jp`), prioritizing local language tags.

### Changed
* **Relational Database Migration (v22 -> v23):** Refactored the rigid, fixed-column translation model into a highly scalable, modular **1:N relational schema** for exercises and user-food overrides (`exercise_translations` and `user_food_override_translations`).
* **Relational Fallback Resolvers:** Replaced old static queries with robust SQLite `LEFT JOIN` and `COALESCE` statements to dynamically resolve active UI strings with graceful fallback chains down to English and German.
* **Automated Catalog Workflows:** Updated the weekly `wger` Python catalog fetcher (`create_wger_exercise_db.py`) and corresponding GitHub Actions to automatically export into the new 1:N relational layout.
* **Web Screenshot Fallbacks:** Configured the localized web templates to dynamically map `fr`, `it`, and `ja` screenshots directly to the existing verified `en-US` directory, avoiding duplicate storage overhead.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Bottom Navigation Bar Quality Degradation**: Fixed a bug where returning from route transitions (such as speed dial option screens) demoted the navigation bar to medium quality (frosted fallback) while leaving the sibling action button in premium quality.
- **Static Analysis Cleanup**: Resolved all remaining static analysis warnings by removing the unused `_isRouteActive` field, deleting redundant `didPushNext()` and `didPop()` overrides, cleaning up unnecessary `dart:ui` imports, and globally suppressing `experimental_member_use` warnings for the liquid glass widgets API.
* **Recovery Screen Muscle Tracking:** Patched the muscle fatigue calculation algorithm by updating the workout history queries to join the new `exercise_translations` table, resolving a bug where exercise names evaluated to null.
* **Base Food Language Toggle:** Fixed a localization lock in the settings menu by refactoring `BasisDataManager._performBatchImport` to correctly ingest the precompiled flat columns (`name_fr`, `category_ja`, etc.) from `train_libre_base_foods.db` and adding dynamic runtime entity getters.

## [0.9.23] - 2026-06-08
### Changed
- **SpeedDial Overlay Quality Isolation**: Decoupled the speed dial action buttons from dynamic performance telemetry and forced them to render with standard quality (`GlassQuality.standard`), eliminating dynamic quality degradation or toggling.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Bottom Navigation FAB Glassmorphic Blur Mismatch**: Fixed a visual discrepancy where the bottom navigation bar's circular FAB lost background blur (rendering flat white) when quality downgraded to `minimal`. Refactored `main_screen.dart` to bypass the package's built-in `extraButton` parameter, instead implementing a layout composition with a custom sibling `AdaptiveGlass` widget configured with `isInteractive: false` to guarantee consistent glassmorphic blur across all rendering quality levels.
- **Fix:** Restricted calorie adjustment notification banner strictly to the current date view in Diary.
- **UX:** Configured 3-Zone master cards in Recovery Tracker to be collapsed by default for faster scanning.
- **UI:** Removed leading food icons and converted vertical meal lists into space-adaptive horizontal grids.
- **Nutrition Hub Card Overflow Fix**: Removed 12px default nested padding from horizontal meal overview cards, preventing layout overflows when translated action strings wrap to multiple lines.
- **Light Mode Bottom Sheet Container Harmonization**: Corrected white-on-white visibility issues in workout and supplement selection bottom sheets under Light Mode by resolving card backgrounds to a transparent black color, ensuring outlines are clearly visible.

## [0.9.22] - 2026-06-08
### Added
- **Dynamic Glassmorphic Shader Quality Degradation**: Implemented `GlassPerformanceManager` singleton to dynamically adjust glass rendering quality (`premium`, `standard`, `minimal`) based on sliding-window raster FrameTiming performance and hardware frame budgets.
- **Route-Aware Render Complexity Gating**: Integrated invisible route-aware quality transitions to apply quality downgrades on push-route transitions and quality upgrades on pop-route re-entry.
- **Fade-Transition Shader Cross-Fade Shield**: Refactored the persistent `RunningWorkoutOverlay` to perform quality shader swaps at zero opacity via a 120ms `FadeTransition` animation shield to eliminate quality "pop-in" visual flicker.
- **Speed Dial Quality Binding**: Wired the `SpeedDialMenuOverlay` action buttons to consume active manager quality dynamically using a `ValueListenableBuilder`.
- **Expanded Recovery Tracker Muscle Groups**: Expanded the master tracking array to track 13 primary muscle groups, adding `Muscle.adductors`, `Muscle.lowerBack`, and `Muscle.forearms` to target lists, status badges, and recovery calculations.

### Changed
- **Centralized Design Constants**: Migrated and refactored all glassmorphic widgets (`GlassBottomNavBar`, `GlassFab`, `GlassPillButton`, `RunningWorkoutOverlay`, `GlassBottomMenu`, `SpeedDialMenuOverlay`) to utilize unified styling tokens defined in `DesignConstants` (`glassShadow`, `glassNeutralTint`, `glassColor`, and `liquidGlassSettings`).
- **Removed Android Bottom Bar Quality Override**: Removed target platform checks that restricted the bottom navigation bar's tap indicator to standard/medium quality on Android devices, allowing it to leverage dynamic/configured quality settings.
- **3-Zone Accordion Compacting Architecture for Recovery Tracker**: Refactored the scrollable list layer in `recovery_tracker_screen.dart` to group all 13 core muscle metrics into exactly three master expandable categories based on recovery status: "In Erholung" (In Recovery - expanded by default), "Gemischt / Bereit" (Mixed / Ready - expanded by default), and "Frisch" (Fresh - collapsed by default). Each zone card features a color-coded status dot, a horizontal minimalist muscle preview chip loop, an animated rotation disclosure chevron, and smooth expansion/collapse cross-fade transitions.


### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Liquid Glass Shadow Clipping**: Integrated `ShadowOuterClipper` across all Liquid Glass components (bottom navigation, FAB, workout overlay, speed dial actions) to strictly clip drop shadows from behind the transparent glass elements, keeping the backgrounds bright and translucent.
- **Anatomical Body Highlighter Canvas Mappings**: Synchronized SVG path mappings in local package `flutter_body_highlighter` (and bumped version to 1.0.3) to resolve blank forearms, map lateral head triceps (front view), neck muscles (back view), erector spinae (lower back), isolated tibialis anterior (shin-adjacent), and inner-thigh adductors insertion (back view).
- **Neck & Traps Visual Merge**: Merged the posterior neck SVG paths directly into the `trapezius` map entry in `flutter_body_highlighter` (v1.0.3) and routed all legacy neck/lower neck raw mappings to the `trapezius` token to eliminate the uncolored gap on the back view.
- **Adductor Logging Pipeline Repair**: Fixed the state query aggregation pipeline to resolve naming variance drops for adductors by mapping raw input strings to major muscle groups before fatigue load evaluation threshold filtering.

## [0.9.21] - 2026-06-07
### Changed
- **Default Visual Style Swap**: Swapped the out-of-the-box visual style preference default from "Flüssig (Liquid Glass)" (index `1`) to "Standard (Glas)" (index `0`) in `ThemeService` so new app installations default to the frosted standard glass style.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Standard Glass Shader Pipeline Upgrade**: Migrated the standard visual style (`visualStyle == 0`) branch across multiple components (`GlassBottomNavBar`, `GlassFab`, `GlassPillButton`, `RunningWorkoutOverlay`, `GlassBottomMenu`, `SpeedDialMenuOverlay`) from legacy native `BackdropFilter` and solid container fallbacks onto the unified `AdaptiveGlass` shader pipeline from the `liquid_glass_widgets` package.
- **Light Mode Tint Harmonization**: Fixed Light Mode background burnout/clipping issues where the bottom bar and FAB appeared muddy, dark, and dirty-grey or clipped into raw white by aligning their background `neutralTint` to a clean, bright, semi-transparent white (`Colors.white.withValues(alpha: 0.10)`), matching the functioning `RunningWorkoutOverlay` background exactly.
- **Ambient Shadow Matrix Unification**: Unified and applied the deep physical depth shadow matrix (`BoxShadow` with `blurRadius: 12`, `offset: Offset(0, 6)`, `Colors.black` at `30%` opacity) across both standard (`visualStyle == 0`) and liquid (`visualStyle == 1`) navigation components to eliminate visual rift and restore parity with the workout overlay.
- **Liquid Mode Shadow & FAB Refinement**: Added physical drop shadows to the navigation bar, workout overlay, and speed dial action buttons in Liquid Glass mode for visual parity. Fixed the muddy dark grey appearance of the Floating Action Button in Liquid Mode by removing the redundant solid black background layer..

## [0.9.20] - 2026-06-07
### Added
- **Glassmorphic UI Library Migration**: Integrated the `liquid_glass_widgets` package (v0.15.0) as the primary engine for the application's premium glassmorphic layouts.

- **Lucide Icons Migration & Color State Refactor**: Transitioned the primary application navigation shell (`GlassBottomBar`) and the active workout tracking overlay (`RunningWorkoutOverlay`) to the `flutter_lucide` asset system.
  - Implemented the **Pure Color State Toggle** principle: icons now retain identical tokens across active and inactive states to eliminate layout jitter.
  - State differentiation is now exclusively handled via color mutations: `brandAccentColor` (Chartreuse) for active states and muted `onSurface` for inactive states.
  - Integrated `LucideIcons.notebook`, `LucideIcons.dumbbell`, `LucideIcons.chart_no_axes_column`, and `LucideIcons.utensils` into the navigation deck.
  - Deployed `LucideIcons.clock` (size 20) in the active workout tracking overlay.
- **Dependency Overhaul**: Added `flutter_lucide: ^1.11.0` and removed previous experimental icon sets.


### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Navigation Label Typography & Scaling**: Fixed a regression in the `GlassBottomBar` where uninherited Material context caused text labels to scale disproportionately large and render with yellow error underlines. Wrapped the component in a `Material` widget and applied an explicit `DefaultTextStyle` mapping directly to our absolute compact design token (`fontSize: 11.0`, `fontWeight: FontWeight.w600`, `fontFamily: 'Inter'`, `letterSpacing: -0.2`).
- **Layout & Typography in RunningWorkoutOverlay**: Fixed a critical layout collision where the workout tracking bar overlapped the new `GlassBottomBar` by introducing an 8px layout offset. Fixed a visual regression by realigning the elapsed duration typography with the centralized `titleMedium` system style, ensuring `Inter` font rendering, correct boldness, and consistent tracking.

## [0.9.19] - 2026-06-06
### Added
- **Save Workout as Routine**: Implemented a "Save Workout as Routine" feature in the historical workout log details screen (`WorkoutLogDetailScreen`).
  - Added repository contract and transaction method (`createRoutineFromWorkout`) to safely copy completed sets, sort warmup sets first, exclude incomplete sets, and map logged rest times to exercise pause durations.
  - Implemented a subtle "Save as routine" action button and a customized routine name entry bottom sheet menu using the custom glass panel (`showGlassBottomMenu`).
  - Deployed localized string keys (`saveAsRoutineButton`, `saveAsRoutineTitle`, `saveAsRoutinePrompt`, `saveAsRoutineSuccess`, `snackbarRoutineSavedAction`) across German and English dictionaries.
- **One-Click Routine Navigation**: Integrated a dynamic SnackBar action ("Ansehen" / "View") to immediately navigate (`Navigator.push`) to the routine's editor screen (`EditRoutineScreen`) both upon creating a new routine from history and after applying contextual routine delta synchronization.
- **Integration Testing**: Added integration test `createRoutineFromWorkout correctly creates a routine from a workout log` in `workout_database_helper_query_test.dart` to verify dataset cloning, warmup sorting, and rest-time mapping precision.
- **Global Exercise Catalog Overhaul & wger Isolation**:
  - Implemented database schema migration (v22) adding a `replacesExerciseId` column to track user clones of system exercises.
  - Added a smart-forking cloning factory `Exercise.duplicateAsCustom` to copy read-only system exercises into customizable user-created copies.
  - Overhauled repository queries (`getExerciseByUuid`, `getExerciseByName`, and `searchExercises`) to exclude overridden system exercises and prioritize resolving user-created custom overrides.
  - Implemented strict database write guards to prevent direct modification of read-only wger system catalog entries.
  - Added a comprehensive database integration test suite validating cloning behavior, search exclusion, and priority override resolution.

- **Sleep Day Overview Screen**: Added a new [SleepDayOverviewPage](file:///Users/richardgeorgschotte/Projekte/train-libre/lib/features/sleep/presentation/day/sleep_day_overview_page.dart) screen detailing nocturnal sleep architecture, duration, cycles, efficiency indicators, and scoring, utilizing dynamic translations and localized strings.
- **Nightly Sleep Analysis Domain**: Added the [NightlySleepAnalysis](file:///Users/richardgeorgschotte/Projekte/train-libre/lib/features/sleep/domain/derived/nightly_sleep_analysis.dart) model to handle high-precision calculations of physiological sleep data.
- **Isolate Offloaded Excel Export Engine**: Completely refactored the Excel generation pipeline to run inside a background isolate (`compute()`), utilizing fully serialized Dart DTOs (`ExcelExportData`) to decouple database queries from spreadsheet construction, eliminating thread lock and memory sharing failures.
- **High-Fidelity Sport Science Metrics (Sheet 2: "Workouts & Exercises")**:
  - Implemented strict compliance for reps in reserve (RIR) and rate of perceived exertion (RPE) null-value serialization, writing empty string cells (`""`) instead of defaulting to `0` (which clinically represents muscular failure).
  - Added a dedicated "Set Notes" column (`setLog.notes`) right before the exercise comments to prevent data loss.
  - Standardized workout labeling using the chronological name format `Routine Name (Date)` or `Workout (Datetime)`.
- **Chronological Outer-Join Wearables Matrix (Sheet 4: "Biometrics & Wearables")**:
  - Engineered an in-memory chronological outer-join matrix grouping sparse wearable and biometrics streams by local date (`YYYY-MM-DD`).
  - Added dedicated columns for `[Weight (kg)]` and `[Body Fat (%)]` to the master wearables layout.
  - Integrates policy-based daily step merging supporting both `autoDominant` and hourly `maxPerHour` aggregation in pure Dart.
  - Automatically averages multiple daily weight/body fat measurements when present and safely writes empty cells for missing telemetry dates.
- **Dedicated Physical Measurements Sheet (Sheet 5: "Measurements")**:
  - Added a dedicated, chronologically sorted sheet outputting a raw, granular log of all user measurements with columns: `[Date] | [Time] | [Measurement Type] | [Value] | [Unit]`.

### Changed
- **Liquid Navigation Overlay**: Swapped the custom bottom row in `main_screen.dart` to use the native `GlassBottomBar` with organic liquid-glass blending and a right-anchored quick-action FAB (`extraButton`).
- **Core Component Refactoring**: Shifted custom widgets (`GlassBottomNavBar`, `GlassFab`, `GlassPillButton`, `RunningWorkoutOverlay`, `GlassBottomMenu`, `SpeedDialMenuOverlay`) onto the package's `AdaptiveGlass` and `GlassButton` APIs to deprecate legacy low-level shaders.
- **3-Tier Performance and UX Overhaul**:
  - **Tier 1 (Database Ingestion Isolate)**: Shifted massive SQLite database row parsing, companion mapping, and object instantiation into a dedicated background isolate during remote catalog synchronization, completely eliminating UI thread locking and frame drops.
  - **Tier 2 (SQLite Computational Pushdown)**: Refactored expensive Dart-side collection loops in the `getVolumeByMuscleGroup` analytics queries to utilize raw SQLite queries with `json_each` functions. Muscle volumes are now natively grouped and aggregated via database engine optimizations before crossing the FFI bridge, significantly reducing heap memory allocation.
  - **Tier 3 (Logical Day Offset & Debounce Refactoring)**: Altered the global logical day boundary for diaries and sleep tracking from `00:00` to a `04:00 AM` offset utilizing a custom `dateOnly` extension, correctly associating late-night meals and workouts with the active wake cycle. Fixed heavy UI stuttering across `FoodExplorerScreen` and `GeneralFoodSelectionScreen` by isolating text debouncers from synchronous `setState` rebuilds and wrapping inputs in `ValueListenableBuilder`.
- **Relational Delta-Synchronization Engine & Contextual 1-Tap Sync**:
  - Overhauled the workout-to-routine template synchronization framework from a destructive "wipe-and-rebuild" logic to a high-fidelity, non-destructive Relational Delta-Synchronization Engine running in a single SQLite transaction block inside `routines_queries.dart`.
  - Implemented surgical sequence updates to realign the `order_index` of matching routine exercises, safely delete skipped exercises, and absorb newly added exercises with their live logged metrics.
  - Introduced split-type positional comparison separating warmup and working sets, preserving baseline template targets (weight, reps, RIR, notes) on overlap, deep-copying configurations from the last known template on expansion, and deleting trailing excess templates on contraction.
  - Implemented post-synchronization re-ordering sequence to guarantee newly added warmup sets are always sorted and loaded sequentially before working sets (by resetting `localId` ordering while preserving original UUIDs and metadata timestamps).
  - Added a premium contextual synchronization banner on the workout summary screen when structure or sequence alterations are detected, allowing a 1-tap template update with haptic feedback and real-time confirmations.
- **Exercise Catalog & Detail UX Refinements**:
  - Hid the `[System]` badge on cards in the exercise catalog list view, displaying only the `[Custom]` badge for custom user exercises.
  - Removed the prominent inline warning card on the exercise detail screen to declutter the layout.
  - Made the AppBar "Edit" button always visible; clicking it on a system exercise opens a premium glass bottom sheet menu with options to clone and edit.
- **Real-Time Weight & Measurement Chart Updates**: Refactored the profile repository and database helper to expose reactive data streams, enabling the measurements chart on the Diary/Profile screens to auto-update in real-time when new entries are added, eliminating the need for manual refreshes.
- **Product Search Engine Optimizations**: Overhauled search query structures in the product local data source to significantly accelerate lookups and improve fuzzy-matching quality against the localized food database.
- **Exercise Search Engine Overhaul**: Refactored the local exercise search pipeline inside `exercises_queries.dart` to support word-order invariant token parsing, 90-day lookup window training history rescoring (via correlated subqueries on set and workout logs), and hierarchical priority ranking (exact match > history score > custom overrides > prefix match > alphabetical fallback). Added dedicated integration tests validating search tokenization, scoring weight math, and ranking.
- **Sleep Pipeline & UI Realignment**: Deeply refactored the sleep pipeline service, sleep session entity, and sleep day repository to implement a pure mathematical interval-merging algorithm to resolve overlapping nocturnal sleep intervals, and corrected sleep classification using a $\ge$ 3-hour threshold. Overhauled the Schlafintervalle (Sleep Intervals) card component in the UI with bedtime/snooze vector icons for list items, premium green count badge styling, and clean vertical alignment with the header moon icon removed.

- **Save as Meal Template Shortcut**: Added a minimalist section footer link ("Als Mahlzeit sichern" / "Save as meal") to each expanded meal card in the Diary Screen.
  - Renders exclusively when a meal section contains at least one solid food entry (liquid-only sections such as Water are suppressed) to eliminate visual clutter.
  - Tapping the link creates a blank meal stub in the database, pre-populates `MealScreen` with the filtered solid entries (barcode + logged gram amount), and opens the meal creation flow in edit mode with name and notes fields intentionally left blank so the user authors their own template title.
  - Styled as a zero-padding `TextButton` with `FontWeight.w700` and `colorScheme.primary` foreground, matching the "Mahlzeit bearbeiten" app bar action on `MealScreen`.
  - Performs best-effort cleanup of the DB stub if the user discards the flow without saving a name.
- **`MealScreen` Pre-population API**: Extended `MealScreen` with an optional `prefillItems` parameter (`List<Map<String, dynamic>>?`). When provided, the screen skips the DB ingredient fetch, loads the supplied rows directly, and opens automatically in edit mode — enabling the diary shortcut workflow without any separate creation screen.

### Changed
- **Meal Template Explorer Empty State**: Replaced the plain greyed-out icon/text placeholder in `MealsScreen` with a premium, on-brand empty state:
  - 88×88 circular container with 12 % opacity primary color background wrapping `Icons.restaurant_menu_outlined`.
  - Bold `titleLarge` headline: "Keine Mahlzeiten gespeichert" / "No meal templates saved".
  - `bodyMedium` subtext at 75 % opacity (line height 1.45) explaining the diary shortcut workflow as the recommended first step.
  - `OutlinedButton.icon` CTA ("Mahlzeit manuell erstellen" / "Create meal manually") wired to the existing `_createMealAndOpenEditor` flow for users who prefer to build templates from scratch.
  - Padding accounts for `topPadding` so the layout centres correctly behind the navigation bar.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Static Analysis**: Resolved the `use_build_context_synchronously` lint warnings inside `_showSaveAsRoutineDialog` by capturing repository and navigation handlers prior to the async bottom sheet UI transitions.
- **Deprecated Opacity APIs**: Fixed the `deprecated_member_use` compiler warning by replacing `withOpacity` with the modern `withValues(alpha: ...)` API.

### Removed
- **Legacy Glass Renderer**: Fully removed the deprecated `liquid_glass_renderer` package and its references from the codebase.

## [0.9.18] - 2026-06-02
### Added
- **Smarter Contextual Recommendation Banner**: Implemented an in-app context banner at the top of the Diary Screen that dynamically alerts users to updated TDEE targets.
- **Dynamic Calorie Delta Formatting**: The banner automatically evaluates discrepancies between active profile targets and newly computed recommendations, displaying a real-time signed delta string (e.g., "+200 kcal" or "-120 kcal").
- **One-Tap Target Application**: Integrated an immediate "Apply" / "Anwenden" action button within the banner that directly invokes `applyLatestRecommendationToActiveTargets()`, updating the local database schema and smoothly refreshing the dashboard.
- **Version-Locked Persistent Dismissal**: Engineered an intelligent state-hiding mechanic keyed explicitly to the recommendation's structural identifier (`dismissed_tdee_banner_${recommendationKey}`). This ensures that dismissing a banner permanently silences it for that specific TDEE release window while guaranteeing it automatically reappears when a fresh recalculation occurs.
- **Sleep, Steps, and Heart Rate CSV Exports**: Introduced missing CSV serialization endpoints. Tapping the measurements export trigger now generates and shares a multi-file collection containing `measurements.csv`, `sleep_history.csv`, `steps_history.csv`, and `heart_rate_history.csv` chronologically ordered.
- **Multi-Sheet Master Excel Workbook Overhaul**: Rewrote the Excel generation engine to compile a comprehensive, 4-sheet workbook:
  - **Nutrition & Drinks**: All foods and beverages logged with complete macronutrients, caffeine, dynamic fluid flags, and exact timestamps.
  - **Workouts & Exercises**: Set-by-set training logs with reps, weight, RIR, session durations, and user-provided training comments/notes.
  - **Sleep Architecture**: Canonical and raw sleep windows, sleep efficiency, WASO (Wake After Sleep Onset), and sleep score indices.
  - **Biometrics & Wearables**: A chronologically consolidated matrix blending daily steps, resting heart rates, and workout-specific heart rates.

### Changed
- **Zero-UI Complete Export Overhaul**: Fully refactored the background serialization and file-generation pipelines for backups and reports without altering the existing "Data Hub" UI/UX interface.
- **High-Fidelity Monolithic JSON Backups**: Upgraded the JSON import/export engine with absolute restore fidelity. Dynamic tables lacking standard compile-time bindings (such as sleep nightly/canonical/raw records, hourly pulse aggregates, user food overrides, and cardio activity logs) are now dynamically serialized and fully restored using dynamic `INSERT OR REPLACE` statements.
- **Expanded Nutrition and Workout CSV Layouts**: Upgraded `nutrition_history.csv` to merge food and fluid logging with full nutritional values, and enhanced `workout_history.csv` with set-level metrics and contextual training comments.
- **Full Database Purge & Restore Isolation**: Expanded `clearAllUserData` to completely clean dynamic sleep, pulse, user food overrides, and cardio tables, preventing residual data pollution during database restorations.
- **Nutritional Companion Serialization**: Enhanced food companion imports to preserve complete nutritional profiles, including liquid categorization, caffeine contents, and localized designations.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Widget Integration Regression Testing**: Fully updated the presentation test suite (`recommendation_banner_test.dart`) to validate delta mathematical prefix logic, click-to-apply database updates, and multi-week isolation rules. All test specifications executed successfully with zero failures.

## [0.9.17] - 2026-06-01
### Added
- **iOS Keyboard Done Accessory Bar**: Implemented a custom keyboard accessory overlay bar for iOS numeric inputs, aligning a localized **"Done" / "Fertig"** button (`doneButtonLabel`) above the soft keyboard for quick dismissal.
- **Global Keyboard Tap-to-Dismiss**: Wrapped the root of the app in a global translucent `GestureDetector` that automatically closes the keyboard on tapping any non-interactive empty background space.
- **Smart Keyboard-Aware UI Hiding**: Automatically hides the "Add Exercise" floating action button (FAB) on workout tracking and routine builder screens while the keyboard is open to prevent overlapping layout issues.

### fixed
- **Supplement Backup Serialization Mismatch (#418)**: Fixed a data loss vulnerability within the data management engine where the `is_tracked` boolean attribute for supplements was dropped during export serialization. Restoring from a backup now perfectly retains the original tracking configurations across all custom supplement entries.
- **Health Connect Delayed Sleep Correction (#419)**: Overhauled the wearable data synchronization pipeline to support non-destructive upserts for modified records. Delayed sleep session adjustments and retroactive accuracy updates from Apple Health/Health Connect are now correctly captured and refreshed within a rolling 72-hour synchronization window instead of being permanently blocked by stale local database caches.
- **Health Connect Step Deduplication (#424)**: Implemented an Android native source-prioritization filter for Health Connect steps. The ingestion engine now explicitly prioritizes premium tracking origins (Google Fit / Samsung Health) and filters out multi-device telemetry to eliminate double-counted step spikes.
- **Progressive Sleep Sync & Daytime Nap Protection (#419, #424)**: Overhauled the sleep pipeline to handle progressive tracker updates sharing identical start boundaries by dynamically preserving the longest consolidated record. Introduced a localized nocturnal time-window heuristic (20:00 - 12:00) to safely isolate overnight tracking cleanups while fully preserving daytime naps from cascading deletions.
- **Offline OFF Ingestion Fluid Heuristic (#421)**: Corrected a parsing bug within the static database ingestion manager where solid foods defaulted to liquids. The mapper now strictly evaluates nutrition baseline units (100g vs 100ml) and primary category tags to enforce accurate fluid flagging.
- **EAN Master Record Custom Overrides (#423)**: Introduced a new local isolation table (`user_food_overrides`) under database schema v21. Modifying a food item now automatically triggers an execution upsert, ensuring custom user corrections dynamically take precedence over weekly static database syncs during barcode scans and searches.
- **Native iOS Barcode Scanning Overhaul (#420)**: Replaced the resource-heavy C++ FFI `flutter_zxing` engine with `qr_code_scanner_plus` to leverage Apple's hardware-accelerated AVFoundation framework via native `UiKitView`. This completely eliminates background stream rotation anomalies and zero-detection macro lens issues on iOS devices, resulting in instantaneous EAN-8/EAN-13 recognition while maintaining full FOSS compliance and preserving the custom dark-glassmorphic laser viewfinder overlay.

## [0.9.16] - 2026-05-28

### Added
- **Onboarding Legal Double-Lock**: Upgraded the initial consent screen to require explicit, separate acceptance of both the Privacy Policy and the Terms of Service before entering the application.
- **Interactive Legal Navigation**: Integrated an active inline hyperlink framework within the onboarding checkboxes, allowing users to review the localized Terms of Service completely offline via the internal Markdown viewer.
- **Adaptive Exercise Creation Framework**: Enhanced the custom exercise creation pipeline by dynamically merging a comprehensive, local muscle registry with database entities. This permanently ensures that essential muscle groups absent from external APIs (such as Adductors and Forearms) are always natively available as selection chips.
- **Comprehensive Latin Nomenclature Mapping**: Integrated robust data-boundary translation wrappers to correctly map and preserve foreign API fallback nomenclature (including *Brachialis*, *Obliquus externus abdominis*, *Serratus anterior*, and *Soleus*), routing them into accurate core recovery calculations and visual coordinates.

### Changed
- **Evidence-Based Synergist Recalibration**: Adjusted the secondary/overlapping muscle workload coefficient from `0.5x` down to a sports-science-standard `0.3x` scaling multiplier within all background analytical queries, preventing artificial fatigue accumulation spikes in cumulative recovery tracking.
- **Multi-Perspective Muscle Visibility**: Removed restrictive single-view viewport constraints from the visual rendering layer, allowing dual-aspect muscle groups like Adductors and Forearms to dynamically illuminate on both the anterior (front) and posterior (back) model silhouettes.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Compliance Enforcement Gaps**: Fixed a verification vulnerability by ensuring the "Continue" button remains strictly disabled until active cryptographic acceptance tokens are verified for both distinct legal frameworks.
- **Biceps Brachii Visual Disconnect**: Resolved a structural pipeline mismatch within the local SVG template rendering framework by linking generic biceps inputs to target and color both the long-head and short-head anatomical path coordinates concurrently.
- **Anatomical Dropout and Mappings**: Patched an ingestion leak where unmapped compound muscle components were either completely discarded or misattributed to parent groups, stabilizing long-term data integrity for core training logs.

## [0.9.15] - 2026-05-26

### Added
- **Interactive Anatomical Visualization**: Integrated the `flutter_body_highlighter` package across all training vectors (`RecoveryTrackerScreen`, `WorkoutSummaryScreen`, `WorkoutLogDetailScreen`, and `MuscleGroupAnalyticsScreen`).
- **Dynamic Gender Mapping**: Implemented a reactive mapping layer that automatically adapts the anatomical silhouette (Male/Female) to the user's biological preference saved in their profile.
- **Configurable AI Timeout**: Added a user-facing slider in AI Settings allowing manual adjustment of the request timeout (10s to 300s) to support variable hardware performance during local model validation.
- **Anatomical Lower Leg Tracking**: Added official support for the **Tibialis Anterior** muscle to the highlighter library and mapped it to calf training for a more accurate front-view leg highlight.
- **Full AI Provider Registry Restoration**: Restored **Google Gemini**, **xAI Grok (Grok)**, and **Mistral** back to the settings selection dropdown in `ai_settings_screen.dart` alongside OpenAI, Anthropic, Ollama, and Custom, making all 7 supported AI providers fully selectable for on-device food analysis.

### Changed
- **Relative Heatmap Intensity**: Refactored workout heatmaps to use session-normalized intensity (1-5). The most-trained muscle in a session now always displays at maximum vibrancy, regardless of total volume.
- **Vibrant Visualization Palette**: Deployed a custom "Heat" color ramp (Yellow → Orange → Red) for workout sessions and high-contrast accents (Cyan/Green) for recovery states to maximize readability.
- **Standardized Analytics UI**: Unified the `TabBar` design across all analytics screens with consistent icons and localized labels (**Involved Muscles** and **Analysis**).
- **Sleep Scoring Engine LaTeX Refactoring**: Refactored the 3 complex multi-line `cases` equations in `sleep_scoring_engine.md` (Sleep Duration, Light Sleep Penalty, and Circadian Timing) into clear bulleted text conditions and single-line display math blocks (`$$ ... $$`). This completely bypasses markdown backslash-escaping and HTML entity conversion bugs to guarantee robust, beautifully styled green math blocks on all viewports without any KaTeX compiler crashes or text overflows.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Shoulder Highlight Bug**: Resolved a library-level mismatch between SVG path keys and enum mappings, restoring correct anterior/posterior deltoid highlights.
- **Core Tracking Gaps**: Re-enabled **Abs**, **Obliques**, and **Core** in the recovery tracking engine. Tapping "Abs" now correctly highlights the entire core region on the body model.
- **Workout Summary Scroll Lock**: Moved all summary elements into a unified `ListView`, eliminating the "tiny window" scrolling limitation on compact viewports.
- **Stale Muscle Mapping**: Fixed a state-leak bug in `WorkoutLogDetailScreen` where deleted exercises would leave "ghost" highlights on the body model.
- **Dropdown Visibility Regression**: Resolved a settings screen filter issue that inadvertently hid registered production AI providers from the user-facing settings screen.


## [0.9.14] - 2026-05-23

### Added
- **Clinical Algorithm Disclosure Engine**: Implemented a reusable, asynchronous asset-backed disclosure system (`AlgorithmInfoButton`) that dynamically loads and natively renders deep-dive architectural specifications directly from project markdown repositories.
- **Embedded Technical Specifications**: Authored and integrated uncompressed, high-density mathematical engineering documents under `documentation/features/` covering the Bayesian TDEE Estimator, Hybrid BYOK AI Verification, and the newly formulated Muscle Recovery Model.
- **Dynamic Hydration Scaling**: Replaced the legacy static 3000 ml water intake default with a personalized, weight-dependent metabolic formula:
  $$\text{Daily Water (ml)} = \left(\frac{\text{Body Weight in kg}}{20}\right) \cdot 1000$$
  Integrated seamlessly across onboarding tracking vectors and active asset dashboards (`OnboardingScreen`, `GoalsScreen`).
- **Mathematical Rendering Pipeline**: Expanded dependencies in `pubspec.yaml` to include `flutter_markdown_plus_latex` and `markdown` to support native, on-device parsing of high-precision math inside modal views.
- **Interactive Web Analytics Hub**: Deployed a massive responsive update to the `docs/` architecture, featuring a premium dark-glassmorphic, interactive KaTeX-powered calculator allowing users to live-simulate Bayesian TDEE decay and process noise variance expansions ($Q = 40$).
- **Data Access Layer Extensions**: Added a specialized `getLatestWeight()` asynchronous retrieval routine within `lib/data/database_helper.dart` to safely supply active user metrics to dynamic calculation engines.

### Changed
- **Algorithmic Information Transparency**: Deployed educational info triggers (ℹ️) across four core interfaces: `RecoveryTrackerScreen`, `AiMealCaptureScreen`, `NutritionRecommendationCard`, and `SleepScoreCard` to grant users full mathematical visibility.
- **Localization Architecture Hardening**: Expanded localized string dictionaries (`app_de.arb` and `app_en.arb`) by over 20 new high-density technical prose entries. Completely purged raw LaTeX syntax and legacy academic/clinical citations from translation assets to enforce bulletproof UI rendering.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Information Screen Layout Overflows**: Refactored the `ExpansionTile` headers inside `algorithm_info_sheet.dart` into a single text-wrapped flexible row, completely eliminating right-side pixel clipping and horizontal layout breaking on compact viewports.
## [0.9.13] - 2026-05-xx

### Added
- **UI Modularization Milestone**: Completed an epic, 11-phase modularization of the core presentation layer. 
  - Decomposed massive screen files (Onboarding, Edit Routine, Steps, Sleep, Settings, AI Review, Live Workout, and Statistics Hub) into isolated, highly reusable components within `presentation/widgets/`.
  - Established a dedicated widget library for the Statistics Hub, isolating dashboard cards (Pulse, Sleep, Performance, etc.) for better maintainability.
- **Enhanced Data Layer Architecture**:
  - Decomposed the monolithic 3,100+ LOC `WorkoutLocalDataSource` into specialized part-files: `exercises_queries.dart`, `routines_queries.dart`, `workout_logging_queries.dart`, and `workout_stats_queries.dart`.
  - Isolated the mathematical engine of the Bayesian TDEE estimator into dedicated domain models (`estimator_models.dart`, `observation_model.dart`, `regression_engine.dart`).
- **Advanced Sleep Diagnostics**:
  - Deployed a continuous, on-device Sleep Continuity fallback architecture ($S_{C, fallback}$) for commercial smartwatches that do not supply explicit SE/WASO (Efficiency/Awake minutes) data, leveraging light sleep distribution ($90\%$) and total duration ($10\%$).
  - Added `multiplierBottleneck` diagnostics to `SleepScoringResult` to pinpoint the exact physiological domain limiting the sleep health index.
  - Upgraded the UI Clinical Protection Banner to dynamically fetch the bottleneck key and display precise, contextual biological explanations (tailored warnings for REM, N3, TST, or Circadian delays).

### Changed
- **Service Decomposition**: Successfully decoupled `AiService` and its validation logic into focused modules (`ai_network.dart`, `ai_parsing.dart`, `ai_prompts.dart`), improving testability and scalability.
- **Architecture Hardening**: Achieved a massive technical debt reduction by auditing ~132k total lines of code.
- **UI Code Optimization**: Relocated over 15,000 lines of inline UI code into structured sub-widgets, reducing core file sizes by up to 68% in critical performance paths.
- **Sleep Health Score v3.5 (SHS v3.5)**:
  - Shifted from a rigid, binary hard-cap framework (forcing scores to a flat 60/40) to the continuous, multi-domain **Sleep Health Score v3.5 (SHS v3.5)** using dynamic soft-cap multipliers (`_linear` interpolation maps).
  - Calibrated the Light Sleep Percentage Penalty ($P_{light}$) curve to real-world smartwatch limitations (blending N1 and N2) by shifting the optimal threshold to $\le 65\%$ with a precision decay standard deviation of $7.0\%$.
  - Smoothed out the Sleep Duration ($S_D$) low-end clipping boundary by completely removing the artificial $4.0\text{h}$ hard-zero floor, allowing continuous Gaussian calculation across the entire short-sleep spectrum.
- **UI Layout Cleanups**: Removed the restrictive nested Card containers from the Detail-Analyse section, turning it into a clean native Section Header with edge-to-edge, full-width `GlassProgressBar` fields.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Zero-Warning Compliance**: Resolved all remaining lint warnings and static analysis issues across the entire codebase, reaching 100% compile-time safety.
- **Code Verification**: Validated all architectural changes against the full suite of 610+ regression tests, ensuring 100% green status.
- **Memory & Persistence Optimization**:
  - Eliminated native Android Out-Of-Memory (OOM) memory exhaustion crashes inside the Health Connect / Kotlin ingestion lines through an intelligent downsampling mechanism that aggregates raw, high-frequency data streams into dense 1-minute epoch segments before channel transfer.
  - Resolved critical local SQLite persistence conflicts and foreign key failures across Drift schema migrations (v19 to v20) by enforcing proper table recreation and non-nullable column defaults.

### Documentation & Testing
- **Mathematical Architecture Disclosure**: Created `documentation/features/sleep_scoring_engine.md` detailing the entire mathematical architecture of SHS v3.5 using explicit, publication-grade LaTeX formulas.
- **Test Suite Synchronization**: Synchronized the test suite to match the refined curves, pushing the project past 610+ verified, green unit and repository tests.

## [0.9.12] - 2026-05-22

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **iOS Barcode Recognition & Xcode Strip Style (#399)**: Resolved a critical issue where the barcode scanner ran smoothly but failed to recognize any barcodes on iOS release builds.
  - Corrected Xcode **Strip Style** from `All Symbols` to `Non-Global Symbols` in Build Settings, preventing the aggressive compilation pipeline from stripping the essential C++ (`zxing-cpp`) native function symbols required by Dart FFI.
  - Retained the optimized `ReaderWidget` configuration (720p `ResolutionPreset.high` and `0.55` crop factor), drastically increasing the scan frame decoding speed and reducing data processing overhead over the FFI bridge without losing scanning accuracy.

## [0.9.11] - 2026-05-22

### Added
- **Optional Colorful Macro Badges (#397)**: Introduced a vibrant new visualization for macronutrients to improve data readability at a glance.
  - Added the dynamic `MacroBadgeRow` theme extension for high-contrast nutritional summaries.
  - Integrated a global preference toggle in Appearance Settings (defaulting to ON for all users).
  - Implemented smart-hiding logic that automatically cleans up the UI by suppressing zero-value badges for fluids and beverages.
- **Unified Search & Scan UX (#401/#402)**: Completely refactored the search interface in `AddFoodScreen` and `GeneralFoodSelectionScreen`.
  - Implemented a smart toggle mechanic that displays the barcode viewfinder when the field is empty and switches to a 'clear' cross icon during active typing.
  - Streamlined the layout to eliminate icon clutter and improve one-handed navigation efficiency.

### Privacy & Security
- **Android Ghost Permission Removal (#405)**: Hardened the application's privacy profile by explicitly stripping third-party injected microphone permissions.
  - Added `tools:node="remove"` for `RECORD_AUDIO` and `MODIFY_AUDIO_SETTINGS` in the `AndroidManifest.xml`.
  - Guarantees 100% privacy compliance by ensuring the app cannot access the microphone even if required by transitive dependencies.

### Changed
- **Statistics UI Refinements**: Polished the layout and data visualization in the Statistics module, including improvements to the normalized trend charts for better readability.
- **Theme Service Optimization**: Refactored `ThemeService` to persist and manage the new macro badge preferences across app sessions.
- **Localization Updates**: Synchronized and expanded localized strings (DE/EN) to support the new UI components and privacy disclosures.

## [0.9.10] - 2026-05-21

### Added
- **Next-Gen AI Meal Capture**: Completely overhauled the analytical AI capture pipeline. Recognition is now backed by an advanced "Top-N Fuzzy Alternatives" Jaro-Winkler candidate selection loop, ensuring zero hallucinations by strictly matching against the local food database.
- **Holistic Calorie Anchors**: Integrated a `mealContext` calorie anchor that cross-checks AI weight estimations against expected dish-type benchmarks to prevent extreme outlier errors.
- **AI Validation Logic (C1-C4)**: Implemented multi-dimensional cross-check validation rules to automatically verify ingredient compatibility, portion density, and logical consistency.
- **Macro Badges & Deep Inspection**: Added compact P/C/F macro badges to ingredient result cards and a read-only deep inspection view for granular verification of matched database entries.
- **Resource Monitoring**: Integrated a token cost indicator for transparency on API consumption and an isolated `AiMatchingLanguageService` to decouple AI matching from the app's UI locale.

### Removed
- **Generative AI Coach**: Deprecated and removed the generative AI Meal Recommendation/Coach pipeline to focus exclusively on local-first analytical accuracy.
- **Global Custom Prompts**: Excised custom prompt settings and dead localization strings to streamline the AI configuration flow.

### Changed
- **UX Layout Optimization**: Relocated the meal-type selector to the bottom navigation save bar, reclaiming vertical screen real estate for ingredient lists.
- **UI Refinements**: Fixed overlapping layout margins in the AI settings dialog and improved the visual hierarchy of the AI capture review screen.
- **Privacy Policy v1.3**: Upgraded the global Privacy Policy to version 1.3 to reflect the new analytical-only hybrid matching engine and local-first data integrity.

## [0.9.9] - 2026-05-20

### Added
- **Reactive UI Architecture**: Completed a multi-phase migration (Phase 1-3) of the core feature layers (Supplements, Diary/Nutrition, Workouts) to a stream-based reactive architecture using Drift watchers, eliminating manual UI refresh cycles.
- **Workout Set & Exercise Notes**: Extended the training domain models and database schema (`SetLogs`, `RoutineSetTemplates`, `WorkoutExerciseLogs`) to support granular text observations with direct tap-to-edit interactions in `LiveWorkoutScreen`.
- **Unsaved Changes Interceptor**: Implemented a navigation guardian in `EditRoutineScreen` with a `showGlassBottomMenu` confirmation dialog to prevent data loss during complex template modifications.
- **Algorithmic Transparency Matrix**: Integrated technical disclosure matrices into the documentation and in-app views, detailing Bayesian TDEE estimation and local deterministic AI matching invariants.
- **LaTeX Math Integration**: Integrated KaTeX (`docs/katex.min.css`, `docs/script.js`) for high-precision rendering of metabolic and statistical formulas across documentation and technical UI views.
- **Technical Documentation Overhaul**: Completely restructured the `documentation/` directory to align with Pure Clean Architecture, separating developer-facing architectural guides from feature overviews.
- **Attribution Inventory**: Added a comprehensive license and attribution inventory to the `AboutScreen` for bundled open-source dependencies.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Fluid Deduplication**: Resolved a critical analytics error in `BodyNutritionAnalyticsDataAdapter` where fluid logs linked to food entries were double-counted in daily totals.
- **Supplement Tracking Stability**: Fixed a mapping regression in `SupplementRepositoryImpl` that caused tracking status and daily goal visibility to be lost during reactive state transitions.
- **Android SAF Target Resolution**: Corrected `BackupManager` logic for Android Storage Access Framework (SAF) to ensure reliable archive writing to secure, user-selected external directories.
- **Haptic Preference Enforcement**: Hardened `HapticFeedbackService` to strictly respect `AppConfig` settings, preventing unrequested vibration events during graph and chart interactions.

### Security & Compliance
- **Privacy Policy v1.2**: Synchronized localized (DE/EN) GDPR/DSGVO compliant policies across the mobile `LegalScreen` and web documentation.
- **Secure Storage Hardening**: Improved data isolation and reset logic in `LocalAppDataResetService` to ensure the complete erasure of sensitive AI provider credentials and model selections.

## [0.9.8] - 2026-05-19

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed mapping regression where supplements lost tracking status and daily goals, disappearing from the Diary screen and Supplement Hub.
- Fixed database-level fluid food double-counting across the analytics compilation pipeline and correlation charts.
- Fixed failing auto-backup process by resolving target directory structures through secure application documents paths.
- Fixed haptic feedback on graph screens to strictly respect the app-wide disabled setting configuration.
- Fixed exercise notes UI layout flaws by removing duplicate edit action buttons and eliminating emoji assets from text wrappers.

### Added
- Added direct tap-to-edit interactions to exercise note display cards across live tracking and history screens.
- Added explicit note deletion capabilities to easily clear text values and update database rows back to null.

## [0.9.7] - 2026-05-18
### Added
- **Reps-in-Reserve (RIR) Enhancement**: Improved RIR data propagation and null-safety during workout logging.
- **Rep Range Fallback**: Implemented mathematical average calculation for rep ranges (e.g., "8-12" defaults to 10 reps) in workout templates and live logging.
- **Global TimeRangeFilter**: Extracted a reusable horizontal ChoiceChip-based filter for consistent timeframe selection across Analytics and Steps modules.

### Changed
- **Diary Summary Harmonization**: Refined summary cards for Sleep, Pulse, and Workouts to use a consistent, emoji-free design with improved typography and spacing.
- **Progress Bar Readability**: Implemented dual-layer clipping and contrast-aware text rendering in `GlassProgressBar` to ensure legibility across all progress levels.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Analytics Layout**: Fixed various UI issues in analytics dashboards, including legend shape consistency, edge clipping in horizontal scrolls, and proper current-day filtering in body/nutrition trends.
- **Navigation**: Resolved inconsistencies in exercise selection routing within routine and live workout editors.

## [0.9.7-alpha.2] (90020) - 2026-05-18
### Added
- **Localized feature-bound DataSources**: DiaryLocalDataSource, WorkoutLocalDataSource, SupplementLocalDataSource, ProfileLocalDataSource, StepsLocalDataSource communicating directly with the core Drift database client.

### Refactored
- **The Great Migration**: Complete dissolution of the monolithic product_database_helper.dart and workout_database_helper.dart files. Moved architectural infrastructure utilities (backup, seeding, import/export managers) into a unified lib/core/infrastructure/ grid.
- **Pure Domain Models**: Established total Domain Purity by removing Drift database model leaks (e.g., db.DailyGoalsHistoryData) from repository contracts and use cases, mapping them cleanly to pure Dart entities (like DailyGoal) within the Data layer.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Runtime & Testing**: Eliminated the critical Drift multiple-instances database runtime warning by enforcing a strict single-instance initialization with constructor dependency injection via Provider. Adjusted timestamp delays to 1.1s to accommodate SQLite's CURRENT_TIMESTAMP clock resolution. Fixed day-inclusive range selections for diary queries.

### Removed
- **Dead Code Pruning**: Permanently deleted 3 obsolete legacy screens (home.dart, nutrition_screen.dart, measurement_session_detail_screen.dart) with zero remaining active layout compiler links. Relocated health_export to the local feature scope folder.

## [0.9.7-alpha.1] - 2026-05-17
### Added
- **Open Food Facts (OFF) Enrichment**: Significantly expanded food data with Caffeine content, Vegan/Vegetarian/Palm-oil tags, and full Ingredients lists.
- **Smart Database Sync**: New offline-first strategy where the product database is synced during app updates or manually via settings, reducing background overhead.
- **Auto-Fluid Detection**: Intelligent classification of products as fluids for easier hydration tracking.
- **Adaptive Calorie UI**: Improved calorie recommendation UI with new fields for actual calorie density visualization.

### Changed
- **Dietary Badges**: Added visual indicators for vegan, vegetarian, and palm-oil-free products in the food detail screen.
- **Database Architecture**: Migrated core product storage to Drift for better performance and type safety.
- **Settings Overhaul**: Added manual database sync trigger and improved OFF region settings.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **App Tour Stability**: Fixed edge cases where the app tour could crash on specific navigation flows.
- **Health Export**: Resolved minor synchronization issues with third-party health platforms.

## [0.9.7-alpha] - 2026-05-17
### Added
- **Isolate Offloading**: Performance-intensive tasks like sleep pipeline processing, CSV/Excel decoding, and muscle analytics are now offloaded to background threads (isolates) using `compute()`, ensuring a butter-smooth UI.
- **Global AI Instructions**: Added a persistent text field in settings for custom AI behavioral instructions, replacing the previous 7-day history transfer for better privacy and performance.
- **Unified AI Ingredient Cards**: New visual representation for ingredients in AI-generated meals for better clarity.
- **Legal Information**: Integrated Impressum and Privacy Policy directly into the app.

### Changed
- **3-Tier Diary Loading**: Optimized the diary screen with a 3-tier loading strategy: Tier 1 (instant macro/workout summary), Tier 2 (deferred exercise/meal lists), and Tier 3 (background health data sync).
- **AI Prompt Hardening**: Improved strict constraint adherence for AI recommendations, fixing issues with dietary preferences (e.g., Skyr/dairy exclusion).
- **Workout UI**: Major overhaul of the live workout and workout history screens for better usability and performance.
- **Design Language**: Updated "Liquid Glass" theme as the standard and improved text visibility across various UI elements.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Navigation Stability**: Hardened navigation lifecycle with strict `if (!mounted)` guards to prevent crashes during rapid screen transitions.
- **Metric/Imperial System**: Fixed unit system inconsistencies in onboarding and various screens (#337).
- **Database Hardening**: Fixed multiple SQL issues in the OFF database and improved batch processing stability.
- **Supplement Tracking**: Fixed default time for supplement entries in the diary (#354).
- **Scanner Reliability**: Improved barcode scanner logic and permission handling.
- Numerous bug fixes (Issues #322, #323, #334, #335, #338, #339, #340, #341, #342, #343, #344, #345, #347, #348, #349, #352, #353, #356, #357, #358, #361).

## [0.9.6] - 2026-05-15
### Added

* **Imperial Units Support:** Full support for Imperial units (lbs, inches) across the app, including height and weight tracking during onboarding and in settings.
* **External App Import:** Enhanced universal CSV and Excel import functionality with automatic unit conversion and improved data mapping.
* **PR & Achievement Tracking:** Integrated Personal Record (PR) badges and achievement banners in the Live Workout and Workout History screens.
* **e1RM Analytics:** Real-time Estimated 1RM (e1RM) calculation and visualization integrated into workout tracking.
* **Usage-Based Search Ranking:** Exercise and nutrition search results are now intelligently ranked based on individual usage patterns for faster access.

### Changed

* **Diary Screen Optimization:** Decoupled Pulse and Sleep data loading from the main Diary view. Primary nutrition and workout data now load instantly while health data populates in the background.
* **Refined Workout Interface:** Updated the Live Workout and History screens for better interaction and visual clarity.
* **Visual Style Improvements:** Adjusted spacing, chart defaults, and text visibility across the Liquid Glass theme.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.


* **Database Hardening:** Optimized SQLite operations and strengthened reload logic to prevent data inconsistencies during concurrent actions.
* **Supplement Default Time:** Fixed an issue where the Supplement Diary FAB defaulted to 00:00 instead of the current time.
* **Initialization Flow:** Improved the app initialization sequence to reduce startup latency.

## [0.9.5] - 2026-05-13
### Added

* **Linked Nutrition Logic:** Integrated a system to link fluid entries with nutrition logs. The `DatabaseHelper` now resolves UUIDs to local IDs, ensuring that calories and macros are not double-counted when a drink is part of a tracked meal.
* **Refined Progress Bars:** Replaced standard indicators in `CompactNutritionBar` with the custom `GlassProgressBar` for a more consistent visual language across the dashboard.

### Changed

* **UI Performance Optimization:** Removed `BackdropFilter` and `ImageFilter.blur` from several core widgets, including `SummaryCard`, `FrostedContainer`, and `GlassProgressBar`. These now use high-opacity solid surfaces to reduce GPU strain and improve frame rates.
* **Visual Polish:** * Updated `GlassBottomNavBar` and `GlassFab` to use refined background colors (`summaryCardDarkMode`/`summaryCardWhiteMode`) and adjusted rim borders for better visibility.
* Simplified background decorations in `LegalScreen` by replacing gradients with solid surface colors.


* **Scanner Enhancements:** Optimized `ScannerScreen` by restricting barcode formats to **EAN-8** and **EAN-13**. Increased resolution to `veryHigh` while adjusting scan delays to balance detection speed and thermal impact.
* **Default Settings:** The default `visualStyle` has been updated to `1` in `ThemeService`.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.


* **Calorie Calculation:** Fixed a bug where liquid calories were duplicated; the app now filters out fluid entries linked to food logs when calculating total daily intake.
* **Test Stability:** Updated `SleepSettingsScreen` tests to include the explicit confirmation step required by the glass bottom menu and fixed locale-dependent string matching.
* **Dark Mode Accessibility:** Adjusted contrast and shadow depths in `FrostedContainer` and `SummaryCard` to ensure elements remain distinct from the background in dark mode.

### Removed

* Unused `dart:ui` imports across multiple widget files to clean up the codebase.

## [0.9.4] - 2026-05-13
### Added
- Integrated legal information (Imprint and Privacy Policy) directly into the app for better transparency and accessibility.
- Introduced the "Liquid Glass" theme as the new default visual style, providing a modern and premium look.
- Added a "Supplement Tracker" to the daily overview, supporting both daily goals (checkmark style) and daily limits (progress bar style).

### Changed
- Improved visual clarity and text visibility on progress bars when using glass-inspired themes.
- Enhanced database stability and reload performance for a smoother user experience.
- Refined food and exercise mapping logic for better accuracy.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed Issue #323: Improved deletion logic for water and drinks to prevent orphaned database entries and enabled direct editing.
- Fixed Issue #322: Resolved a crash occurring during certain nutrition summary updates.
- Fixed barcode scanner issues and added necessary network permissions for catalog refreshes.
- Hardened database actions to prevent potential data inconsistencies during concurrent operations.

## [0.9.3] - 2026-05-10
### Added
- Replaced the barcode scanner with a FLOSS-compatible ZXing-based implementation, improving privacy and removing dependencies on proprietary Google Play Services.

### Changed
- Simplified the onboarding nutrition recommendation flow: generated targets are now automatically applied when continuing through setup.
- Improved localized display names for exercises and food items where translations are available.
- Updated screenshots and README/website documentation to reflect the latest design and privacy-first positioning.
- Refined the primary color in light mode for a more polished visual experience.
- Set scanner resolution to maximum to improve barcode detection reliability across devices.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed a crash when manually adding food items during AI meal review.
- Fixed inconsistent border radius for uploaded images in the AI recommendation screen.
- Improved layout and input handling on the onboarding calorie recommendation page.

### Internal
- Removed Google ML Kit / Google Play Services from the barcode scanner dependency path.
- Updated website and README wording to clarify Train Libre’s privacy-first, offline-first positioning.

## [0.9.2] - 2026-05-09
### Added
- Added a macro and caffeine summary to the Water & Drinks section in the Diary.
- Added comprehensive localization for missing user-facing strings across workout, nutrition, and settings screens.

### Changed
- Redesigned "Today in Focus" layout with improved spacing, better visual hierarchy, and polished macro/micro nutrient rendering.
- Minor UI polish and accessibility improvements across Nutrition and Statistics screens.
- Improved offline catalog import resilience for certain published SQLite artifacts.
- Performance improvements for Statistics and Pulse aggregate queries.
- Deferred non-critical startup initialization to reduce first-frame work.
- Removed unused microphone and speech recognition permission declarations and documentation references.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed several layout overflows on small screens and compact devices.
- Fixed backup restore edge cases for some legacy backup variants.
- Fixed hydration and caffeine totals not updating correctly after editing tracked foods/drinks.
- Fixed the edit dialog not correctly restoring liquid toggle, caffeine, and sugar states.
- Fixed kcal missing in the Water & Drinks section for food-derived liquid entries.
- Fixed default entry time being incorrectly set to 00:00 for new entries.
- Miscellaneous bug fixes and stability improvements.

### Internal
- Documentation audit and cleanup: removed outdated behavioral statements, fixed broken links, and updated privacy policy.
- Permission metadata audit: verified iOS and Android manifests for accuracy and removed obsolete entries.
- Dependency updates and additional test coverage.

## [0.9.1] - 2026-05-06
### Changed
- Redesigned the Nutrition Recommendation UI: improved layout, clearer action affordances, and more consistent responsive behavior across device sizes.
- Fixed visual overflow and alignment issues on small screens.
- Improved accessibility and localization support for the nutrition recommendation controls.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Minor bug fixes and performance improvements in the nutrition recommendation flow.

## [0.9.0] - 2026-05-05
### Added
- Initial Train Libre release with offline-first workout logging, reusable routines, nutrition tracking, hydration, supplements, body measurements, statistics, and local backups.
- Integrated Open Food Facts and wger-based catalog sources for food and exercise data.
- Added optional AI meal features using the user's own API key.
- Added one-way export of supported app-recorded data to Google Health Connect.
- Added native sharing for completed workouts and routines, including localized text exports and branded image share cards.

### Changed
- Renamed the app and repository branding from Hypertrack to Train Libre across Flutter, Android, iOS, widgets, documentation, package metadata, and local catalog filenames.
- Improved Statistics, Pulse, Diary, Add Food, workout history, and backup import/export performance for larger local datasets.
- Refined recovery, sleep, pulse, and nutrition analytics to make training guidance more transparent and robust.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Preserved compatibility for legacy Hypertrack backups and catalog files while migrating new installs to Train Libre naming.
- Hardened loading and error handling across Statistics, Diary, Sleep, Pulse, AI meal save, feedback-report, and active workout flows.
- Reduced Android UI stalls and ANR risk by moving production Drift database work to a background isolate and reducing repeated database lookups.

## [0.9.0-beta.6] - 2026-05-05
### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed severe Pulse loading lag in Statistics by caching hourly heart-rate aggregates instead of repeatedly reprocessing large raw sample histories.
- Hardened Pulse aggregate cache coverage so small recent caches cannot be mistaken for complete older or larger ranges.

### Changed
- Pulse Hub summaries now use cached aggregate rows for range, average pulse, and resting-pulse estimates.
- Pulse detail charts now render from capped aggregate chart points while preserving the selected time range.

### Internal
- Added Drift persistence for hourly Pulse aggregates and aggregate metadata.
- Added regression coverage for large Pulse histories, incremental refresh, leading backfill, weighted aggregate metrics, chart point caps, and disabled tracking behavior.

## [0.9.0-beta.5] - 2025-05-05
### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Renamed bundled and remote catalog database artifacts to Train Libre filenames while preserving legacy Hypertrack fallback compatibility.
- Added English iOS permission usage descriptions for camera, microphone, speech recognition, photo library, and Apple Health access, with German InfoPlist localization kept alongside them.
- Fixed Sleep day overview week/month loading helper wiring so analyzer, tests, and debug builds compile cleanly.
- Fixed a Diary water logging refresh issue where adding water after a refresh could trigger broad app reloads, causing lag or persistent loading states across tabs.
- Kept the selected Diary date stable when adding water from the Diary action path.

### Changed
- New installs now use Train Libre catalog database filenames by default, including `train_libre_training.db`, `train_libre_base_foods.db`, `train_libre_off_<country>.db`, and `train_libre_prep_<country>.db`.
- WGER and Open Food Facts refresh workflows/scripts now publish Train Libre database artifact filenames.
- Base-food sharing/export subjects now use the Train Libre database filename.
- activated minification so the size of the app shrinks

### Compatibility
- Existing local Hypertrack-named catalog files are migrated by copying to the Train Libre filename, verifying the copied size, and removing the old file only after verification.
- Remote catalog refresh prefers Train Libre artifact URLs and falls back to legacy Hypertrack artifact URLs when needed.
- Backup restore compatibility for legacy Hypertrack metadata and filenames remains intact.

### Internal
- Added regression coverage for Train Libre default filenames, explicit legacy fallback constants, local legacy file migration, remote fallback resolution, iOS InfoPlist permission strings, and legacy backup restore compatibility.
- Documented canonical Train Libre catalog filenames and legacy fallback behavior.

## [0.9.0-beta.4] - 2025-05-05
### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Improved Statistics hub loading so slow or failing sections no longer block the entire tab.
- Replaced shared Statistics loading behavior with section-level stale-while-refresh state.
- Kept existing Statistics section data visible while range changes refresh in the background.
- Prevented stale async Statistics results from overwriting newer section data after rapid range changes.
- Fixed Statistics section error handling so failures remain local to the affected card instead of causing endless global loading.
- Fixed Sleep card visibility after Sleep tracking is disabled.
- Prevented in-flight Sleep and Pulse loads from re-rendering stale cards after their tracking features are disabled.
- Added missing cleanup/error handling for selected AI meal save and feedback-report actions to avoid stuck loading states.
- Improved Diary and Add Food performance by reducing repeated product and meal-total lookups.
- Fixed a Live Workout listener cleanup issue.

### Changed
- Statistics hub now loads Steps, Recovery, Sleep, Pulse, Consistency, Performance Records, Volume/Muscles, and Body/Nutrition independently.
- Added debug-only per-section performance timing logs for Statistics and related database/helper calls.
- Preserved Recovery as a fixed current-state metric while improving Statistics reload behavior.

### Internal
- Added regression coverage for section-level Statistics loading, stale result protection, gated Sleep/Pulse visibility, and failed load cleanup.
- Added performance diagnosis documentation for issue #313.
- Expanded focused performance/stability tests around Statistics, Add Food meal totals, product batch lookup, backup JSON processing, and save-flow loading cleanup.

## [0.9.0-beta.3] - 2025-05-05

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed redundant Add Food meal-card refetching by caching meal total futures and using batched product lookup.
- Fixed repeated Diary product lookups by batch-loading products for the selected day.
- Fixed possible stale Statistics range results when switching range chips quickly.
- Fixed additional startup blocking by deferring non-critical initialization until after the first initializer frame.
- Moved Backup JSON encode/decode work off the main isolate to reduce UI stalls during import/export.

### Improved
- Improved Add Food meal performance during scrolling, rebuilds, and meal edits.
- Improved Diary loading performance for days with many food entries.
- Improved startup responsiveness while preserving ongoing workout restoration.
- Improved backup import/export responsiveness for larger backup files.

### Internal
- Added regression coverage for Add Food meal totals.
- Added batch product lookup coverage.
- Added backup isolate helper coverage.
- Added Statistics stale overlapping-load coverage.
- Full Flutter test suite passed with 509 tests.
- Android debug build completed successfully.

## [0.9.0-beta.2] - 2026-05-05
### Added
- Added native share-sheet support for completed workouts and routines.
- Added text exports with localized workout/routine summaries, set-type handling, workout volume, Train Libre branding, and the project GitHub link.
- Added branded image share cards for workouts and routines, including multiple workout layouts for summary, exercises, muscle focus, and minimal stats.

### Changed
- Redesigned workout text sharing to use readable per-set lines with localized special set-type suffixes.
- Redesigned routine image sharing to use compact set-type codes and two-column exercise cards with truncation and `+ X more` handling.
- Improved share-card branding by using the current Train Libre SVG logo.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Moved the production Drift SQLite connection onto a background isolate to prevent database work from blocking touch handling and causing Android ANRs.
- Reduced workout-history database load by fetching completed workout sets in bulk instead of issuing one set query per workout log.
- Removed redundant food-search controller rebuilds while typing in Add Food, Food Explorer, and the general food picker.
- Prevented the Diary weight chart from reloading its database query on unrelated parent rebuilds.
- Preserved the selected Diary date after adding or logging food, meals, fluids, supplements, caffeine, measurements, AI meals, or workouts from a non-today Diary view.
- Removed a Live Workout session-manager listener on screen disposal to reduce memory-leak risk after leaving active workouts.
- Prevented dense workout and routine share cards from clipping long labels or overflowing the image canvas.
- Fixed muscle-focus share cards so high-exercise workouts keep the radar, top muscle-volume values, and footer inside the exported image.

## [0.9.0-beta.1] - 2025-05-02
### Changed
- Renamed the app and repository branding from Hypertrack to Train Libre across Flutter, Android, iOS, widgets, documentation, and package metadata.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Preserved restore compatibility for legacy Hypertrack backups while creating new backups under the Train Libre name.

## [0.9.0-alpha.4] - 2026-05-02
### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Hardened Sleep Health Score handling for ambiguous and missing stage data.
- Prevented `unknown` and ambiguous `inBedOnly` stages from inflating wake duration, WASO, interruptions, and sleep-efficiency penalties.
- Improved REM-missing and low-fidelity stage guardrails so scores do not imply unsupported certainty.
- Made Sleep Regularity Index availability depend on valid consecutive comparison pairs, not just raw valid-day count.
- Marked synthesized duration-only sleep windows as estimated instead of treating them like observed session bounds.
- Added targeted regression tests for missing-stage handling, stage guardrails, SRI coverage, and sleep-window fallback behavior.
- Improved Muscle Recovery readiness semantics with bodyweight strength support, explicit cardio exclusion, and centralized significant-load handling.
- Recalibrated recovery pressure so equivalent-set load no longer saturates after very small stimuli.
- Added muscle-specific recovery windows plus load- and intensity-based recovery extensions.
- Made RIR/RPE fatigue detection more robust and fixed inclusive recovery-state boundary behavior.
- Added robust recovery timestamp parsing and clarified fixed current-state recovery lookback behavior.
- Fixed remote OFF catalog import for currently published single-file SQLite artifacts that still use WAL header mode.
- Prevented remote catalog normalization from truncating downloaded DB files before import validation.
- Added startup retry behavior so failed remote refresh attempts bypass the normal minimum check interval on the next app launch.

### Changed
- Refined muscle recovery analytics by separating current readiness from last-load pressure in the Recovery Tracker.
- Updated recovery UI copy to show actual effective recovery windows and localized load-pressure levels.
- Improved recovery heuristic documentation for muscle-specific windows, readiness scoring, and load-pressure semantics.
- Startup loading status now reflects remote catalog preparation details during OFF/training refresh checks.

### Internal
- Expanded recovery regression coverage for equivalent-set pressure, bodyweight/cardio filtering, RIR/RPE fatigue thresholds, muscle-specific windows, boundary behavior, timestamp parsing, and recovery range policy.
- Updated statistics/recovery documentation to frame readiness as a transparent training-log heuristic rather than a clinical recovery prediction.
- Hardened remote catalog refresh services with WAL-header normalization, size-integrity guards, and focused regression coverage for OFF refresh edge cases.
- Updated OFF/WGER catalog refresh docs and generator scripts to enforce portable published SQLite artifacts (`journal_mode=DELETE`).

## [0.9.0-alpha.3] - 2026-04-26
### Internal
- updated the base nutrition database

## [0.9.0-alpha.2] - 2026-04-25

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed Pulse day-scope handling so the current day is now included as a partial-day window (`start of day -> now`) instead of behaving like a fully completed 24-hour period.
- Added a small guard against zero-length Pulse day windows around local midnight rollover.
- Improved sleep heart-rate fallback behavior on Android / Health Connect setups by deriving sleep HR from the general heart-rate stream when strict sleep-session-linked heart-rate samples are unavailable.
- Improved robustness for vendor/device combinations such as Xiaomi Band setups where valid heart-rate samples may exist but are not reliably linked to sleep-session records.

### Changed
- Sleep heart-rate fallback now intersects general heart-rate samples with imported sleep-session time windows and remaps matched samples to the corresponding sleep session before use.
- The fallback path is still conservative: strict session-linked sleep HR remains preferred, and derived-by-window HR is only used when that stricter result is empty.

### Internal
- Added focused regression tests for:
  - Pulse current-day partial-window behavior
  - Health Connect sleep-HR derivation from general HR samples filtered by sleep windows

### Notes
- This release is a targeted reliability follow-up to `0.9.0-alpha.1`.
- Real-device validation remains especially important for Xiaomi Band / Health Connect combinations and for edge cases such as overlapping or adjacent sleep sessions.

## [0.9.0-alpha.1] - 2026-04-25

### Added
- Added opt-in Pulse analysis with a Settings toggle, heart-rate permission request, and a Statistics hub entry that appears only when enabled.
- Added a dedicated Pulse analysis screen with day/week/month period controls, pulse range, time-weighted average pulse, conservative resting-pulse estimate, and the existing line-chart pattern.
- Added a shared deterministic AI meal validation engine for capture and recommendations, including local DB matching quality, local nutrition recomputation, target-fit checks, visible warnings, and bounded repair orchestration.
- Added a separate opt-in setting for sending recent meal context to AI meal recommendations. It defaults off and recommendations still work without it.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Improved Android sleep heart-rate retrieval for Health Connect providers that store valid in-session samples inside longer heart-rate records whose record window can sit outside the strict sleep/import window.
- Made AI meal save behavior explicit when some recognized/recommended items are unmatched, so partial saves no longer look like all AI items were saved.

### Changed
- Updated Apple Health usage copy to mention enabled health views that read steps, sleep, and heart-rate data.
- AI meal recommendations now locally verify kcal/protein/carbs/fat fit against the intended remaining meal target before acceptance, with up to three automatic repair passes.
- AI meal capture now validates recognized quantities, DB matches, and recomputed nutrition before showing the review screen, with up to three automatic repair passes.

### Internal
- Modernized the Android app module Java/Kotlin compile target from 8 to 17 to match the current Gradle/AGP/JDK toolchain and reduce app-owned build warnings.
- Replaced the foreground rest-timer sound cue with Flutter's built-in system alert sound and removed the `flutter_ringtone_player` dependency to eliminate its Android Java 8/deprecated API build warnings.
- Documented the Pulse MVP boundaries and the Health Connect sleep HR fallback behavior.
- Documented the AI meal capture/recommendation validation architecture and added focused validation/repair tests.

### Notes
- The former `flutter_ringtone_player` warning source was reviewed: version 4.0.0+4 still declares Java 8 compatibility and uses the deprecated Android `Ringtone.setStreamType(...)` API. The app only used it for the foreground rest-timer notification sound, so replacing that single call was lower-risk than keeping or suppressing the plugin warning.

## [0.8.11] - 2026-04-23

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Improved workout heart-rate retrieval reliability for vendor-originated Health Connect data by adding a safe fallback query window when the strict workout window returns no records.
- Restored the missing Measurements shortcut on the Statistics hub so body measurements are reachable again from the Body section.

### Changed
- Continued the Settings IA cleanup with a conservative extraction pass:
  - moved Appearance settings into a dedicated sub-screen
  - moved Steps settings into a dedicated sub-screen
  - moved Sleep settings into a dedicated sub-screen
  - kept Health export in its dedicated sub-screen for consistent structure
- Reorganized top-level Settings into broader sections for better scanability:
  - App
  - Health & Tracking
  - Nutrition & Data
  - Support / About
- Moved “Restart app tour” to the bottom of the App section.
- Refined a few Settings entry icons for better visual consistency.

### Notes
- This release focuses on low-risk UX structure improvements and targeted compatibility fixes without changing settings persistence semantics.

## [0.8.10] - 2026-04-15

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Improved backup/restore robustness so malformed or legacy-shaped payload rows no longer abort the full import as easily.
- Hardened supplement settings/history restore handling for legacy ID mappings and more tolerant type parsing.
- Improved body/nutrition trend loading stability so outdated async responses no longer overwrite newer range selections.
- Prevented malformed analytics chart inputs from causing unstable rendering in normalized trend charts.
- Reduced small-screen layout issues in the body/nutrition trend legend by switching to a wrapping layout.
- Reduced the risk of synthetic workout-session ID collisions in edge cases.

### Improved
- Polished the body/nutrition drill-down fallback state with clearer empty/error messaging.
- Improved resilience of health-step-segment restore by sanitizing malformed rows before database upsert.
- Replaced remaining raw debug print behavior in workout session restore with safer debug logging.

### Notes
- This release focuses on stability, restore safety, analytics robustness, and small UI polish improvements.

## [0.8.9] - 2026-04-15

### Changed
- Reworked the **Bodyweight ↔ Calorie analytics feature** from a simple correlation approach to a more robust **trend-summary model**.
- Replaced correlation-style interpretation with clearer classification of observed patterns:
  - cut-like (lower intake + falling weight)
  - bulk-like (higher intake + rising weight)
  - maintenance-like (stable/stable)
  - mixed or unclear signals
- Improved wording and interpretation to avoid overconfident or misleading conclusions and emphasize non-causality.
- Reused the weekly sleep-window chart pattern in the Sleep regularity detail view for more consistent sleep-timing visualization and reduced duplicated chart logic.

### Added
- Introduced a **normalized dual-line trend chart** (weight + calories) where both series start at the same baseline, making relative trend comparison significantly clearer.
- Added explicit **confidence levels** (`high`, `moderate`, `low`, `insufficient`) based on data quality.
- Added **data-quality diagnostics**, including coverage, overlap, and gap awareness, to support more honest insights.
- Added workout heart-rate summaries and charts to make already recorded heart-rate data visible after training.
- Added basic workout heart-rate metrics including average, maximum, and minimum heart rate where data is available.
- Added a dedicated heart-rate section to the workout detail screen with a session heart-rate line chart.
- Added a compact heart-rate summary block to the post-workout summary screen.

### Improved
- Significantly strengthened **data sufficiency and quality gating**:
  - minimum time span and data coverage requirements
  - overlap validation between weight and calorie logs
  - gap penalties and noise handling
- Redesigned the **Statistics hub Body & Nutrition card**:
  - clearer quick-scan summary
  - compact trend labels and relationship classification
  - embedded normalized mini chart
  - explicit confidence and data basis indicators (e.g. number of weigh-ins and logged days)
- Reworked the **Body & Nutrition detail screen**:
  - replaced separate charts with a single combined normalized comparison chart
  - simplified and clarified the interpretation section
  - removed the body-measurements shortcut to reduce visual noise and improve focus
- Added workout heart-rate data-quality handling with clearer fallback states for missing, sparse, or limited samples.
- Reused existing health-platform data flows with lightweight workout-window matching instead of introducing a heavier persistence layer for the MVP.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Eliminated misleading or weak “correlation” outputs in sparse or noisy datasets.
- Reduced risk of overinterpreting incomplete or low-quality data by enforcing stricter gating and clearer fallback states.

### Notes
- This feature focuses on **trend context, not causal inference**.  
  Observed relationships between calorie intake and bodyweight should be interpreted as patterns, not direct cause-effect conclusions.

## [0.8.8] - 2026-04-15

### Changed
- Completed a repo-wide UI consistency pass for app-owned alerts by migrating remaining standard `AlertDialog` flows to the existing Hypertrack glass action-sheet/dialog component.
- Migrated save/confirm/action dialogs in key flows:
  - onboarding restore password prompt
  - post-onboarding app-tour offer
  - AI key-missing prompts (capture + recommendation)
  - nutrition edit dialogs (food + fluid) and fluid delete confirmation
  - settings OFF region picker and attribution/licenses dialog
  - data import success acknowledgment in Data Management
- Extended the shared custom dialog helper with optional strict modal behavior (`isDismissible` / `enableDrag`) for critical confirmation flows.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Removed remaining app-level default alert style mismatches in migrated screens so action dialogs now follow one consistent Hypertrack UI pattern.
- Preserved existing action semantics and async handling across migrated flows (confirm/cancel/save/delete outcomes unchanged).

### Internal
- Cleaned up remaining analyzer issues, including widget constructor keys, naming consistency, model API cleanup, and minor test/dev code refactors.

### Notes
- Intentionally kept native-style blocking loading overlays (spinner dialogs used during workout-start operations) unchanged, since these are progress overlays rather than app decision dialogs.

## [0.8.7] - 2026-04-15

### Added
- Added a short optional post-onboarding app tour with spotlight/coach-mark guidance through the main app structure.
- Added a Settings entry to restart the app tour at any time.

### Changed
- Polished app-tour coach-mark positioning to keep the explanation panel clear of the bottom navigation area while preserving anchor context.
- Refreshed the app icon for this release.

## [0.8.6] - 2026-04-13

### Added
- Added an optional, user-triggered feedback/diagnostic report flow in Settings:
  - local report generation only (no automatic upload or hidden submission)
  - explicit preview before any sharing action
  - explicit actions: copy, save temporary `.txt`, share via native sheet, or open prefilled email draft to `feedback@schotte.me`
  - optional section toggles for adaptive nutrition diagnostics, backup/restore diagnostics, and user note

### Changed
- Reordered top-level Settings sections for a clearer flow:
  - Appearance
  - Diary
  - AI Meal Capture
  - Steps
  - Sleep
  - Health export
  - Data backup & import
  - Food database
  - Support
  - About & legal

## [0.8.5] - 2026-04-13

### Added
- Added Open Food Facts multi-country refresh/distribution infrastructure with dedicated country channels:
  - `off-foods-de-stable`
  - `off-foods-us-stable`
  - `off-foods-uk-stable`
- Added country-specific OFF release artifacts and metadata pipeline:
  - `hypertrack_off_<country>.db`
  - `off_build_report_<country>.json`
  - `off_catalog_manifest_<country>.json`
  - `off_diff_report_<country>.json`
  - `off_release_notes_<country>.md`
- Added OFF helper scripts for workflow robustness and maintainability:
  - `off_catalog_diff.py`
  - `resolve_off_reference_manifest.py`
  - `build_off_catalog_manifest.py`
  - `build_off_release_notes.py`
  - `publish_off_run_summary.py`
- Added OFF country-aware remote adoption service and startup integration:
  - `OffCatalogRefreshService`
  - `BasisDataManager` OFF remote-candidate adoption with safe fallback behavior
- Added user-facing settings UI for selecting the active food database region:
  - Germany (DE)
  - United States (US)
  - United Kingdom (UK)

### Changed
- OFF catalog generation is now explicitly country-parameterized and bulk-parquet based (`create_off_food_db.py` CLI).
- OFF manifest contract was formalized with integrity + safety fields:
  - `source_id`, `country_code`, `channel`, `version`
  - `db_sha256`
  - `product_count` (informational)
  - `min_product_count` (hard validation floor)
- OFF diff baseline strategy now compares against previous published release assets per country channel (not repository baseline files).
- OFF installed-version tracking moved to country-scoped keys (`installed_off_version_<country>`), with legacy migration safety for existing DE installs.
- Settings flow now clearly communicates that OFF region changes are applied through the existing next refresh/import cycle.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Hardened OFF startup safety when bundle and remote are unavailable for a selected country: imports are skipped safely without destructive side effects.
- Preserved historical nutrition continuity under OFF region/catalog changes by keeping `off` + `off_retained` semantics intact.

### Notes
- The bundled DE OFF database fallback remains intentionally included for staged rollout safety.
- Supported OFF app regions in this release are DE, US, and UK.

## [0.8.4] - 2026-04-13

### Added
- Added end-to-end remote exercise catalog refresh channel using release assets (`wger-catalog-stable`) with app-side adoption flow.
- Added dedicated catalog artifacts and supporting reports (`wger_build_report.json`, `wger_diff_report.json`, manifest).
- Added helper scripts for workflow robustness:
  - `build_wger_catalog_manifest.py`
  - `resolve_wger_reference_manifest.py`
  - `build_wger_release_notes.py`
  - `publish_wger_run_summary.py`
- Added regression tests for exercise catalog ID-upsert semantics and historical workout restoration under catalog drift.

### Changed
- Catalog refresh now uses stricter manifest contract and validation rules (source/channel/version/url checks).
- Threshold semantics were clarified and enforced:
  - `expected_exercise_count` is informational
  - `min_exercise_count` / minimum rows is the hard validation floor.
- Diff baseline logic now compares against the previously published release asset DB (not the committed repository DB baseline).
- Workflow hardening for scheduled/manual refresh + channel publication, including safer gating and artifact handling.
- App-side exercise base import now uses non-destructive `ON CONFLICT(id) DO UPDATE` behavior for catalog rows.
- Workout detail/summary/session restore paths now resolve exercises by stored `exercise_id` first, with graceful fallback.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed potential aggressive refresh behavior by avoiding replace-style writes for base exercises.
- Fixed a history integrity risk where session restore could lose blocks if exercise names changed after catalog update.
- Fixed set-log update behavior to preserve existing `exercise_id` linkage when name lookup no longer matches.
- Preserved historical usability when exercise rows are missing by preventing silent loss in restore flows.

### Internal / Tooling
- Hardened workflow implementation by moving fragile inline scripting to dedicated Python utilities.
- Improved release-channel publication plumbing and run-summary diagnostics.
- Updated catalog refresh documentation to match current non-destructive import semantics and release-asset distribution model.

### Notes
- Existing workout logs continue to resolve via stable exercise IDs where present; metadata updates for the same ID are reflected.
- Upstream-removed exercises are preserved locally (no hard-delete sweep in refresh path), maintaining history integrity and selector availability for retained rows.

## [0.8.3] - 2026-04-12

### Removed
- Removed the complete home-screen widget feature from MVP scope on all platforms (Flutter, Android, iOS).
- Removed Android app-widget provider/resources and iOS WidgetKit extension target integration.
- Removed widget-specific app startup, deep-link launcher, and shared widget bridge/config plumbing.

### Changed
- Regenerated app localizations after removing widget-only translation keys.
- Cleaned release notes/changelog references tied only to the removed widget rollout.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Restored reliable iOS simulator install/runtime by removing broken app-extension integration from the app build.
- Preserved and kept active the Measurements deletion persistence fix (including legacy timestamp fallback behavior).

## [0.8.3-alpha.2] - 2026-04-11

### Changed
- Refined **Today in Focus** widget density and spacing on both iOS and Android to reduce wasted space and show more useful data in the same widget area.
- Improved small-widget layout behavior on iOS with tighter typography and padding, allowing more compact metric presentation.
- Improved Android widget row sizing, spacing, and adaptive visibility logic so medium/large widget sizes can display more metrics.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed measurement deletion persistence in the Measurements screen: swiping to delete now removes the session from storage, not only from the current UI state.
- Hardened measurement-session deletion for legacy records by adding a timestamp-based fallback when legacy session IDs are missing.

## [0.8.3-alpha.1] - 2026-04-10

### Added
- Added a first alpha version of the new **Today in Focus** home-screen widget.
- Widget supports configurable daily metrics such as calories, protein, water, carbohydrates, sugar, fat, caffeine, creatine, supplements, steps, workouts, and sleep.
- Added widget configuration support for visible metric selection and maximum visible item count.
- Added widget tap behavior to open the app directly into the Diary / Tagebuch flow.
- Added a new **Haptic feedback** setting, enabled by default.

### Changed
- Finalized the app’s haptic feedback behavior through a centralized, settings-aware feedback layer.
- Added lightweight confirmation haptics for meaningful completion actions such as saving, adding, applying, starting, and finishing.
- Preserved existing haptic behavior for tab switching, FAB interactions, chart-point dragging, and timer completion flows.
- Added subtle AI waiting haptics during active generation/loading states.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed missing confirmation haptics on important add/save actions in several key flows.
- Fixed AI waiting haptics so they stop correctly when generation finishes and no longer continue into review/result screens.
- Refined the AI waiting haptic pattern to feel more periodic and less abrupt.

## [0.8.2] - 2026-04-10

### Changed
- Reorganized the Workout, Statistics, and Nutrition hub screens to better separate training actions, analytics, and nutrition tools.
- Updated hub section structure and ordering to reduce overlap and make navigation clearer.
- Workout hub now focuses on starting training, managing routines, and accessing workout history / exercise library.
- Nutrition hub now groups adaptive recommendation, goals, meals, and nutrition tools more clearly.
- Statistics hub now groups content into Steps, Recovery, Training, and Body sections.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Removed redundant hub entries that added clutter without meaningful functionality.
- Fixed remaining localization regressions from the hub reorganization by replacing hardcoded Statistics UI strings with proper l10n usage.
- Standardized uppercase section-header rendering across the reorganized hub screens.
- Ensured hub entry labels and section names are consistently localized in German and English.
## [0.8.1] - 2026-04-09

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Improved sleep day-view timeline readability with clearer timestamp labels, better spacing, and stronger light/dark-mode contrast.
- Corrected the weekly sleep-window chart so displayed time bounds and axis labels better match actual sleep session timing, including cross-midnight sessions.
- Sleep scoring now applies conservative stage-aware guardrails so mostly-light or REM-missing nights (especially from limited-fidelity sources such as Withings) cannot silently receive near-perfect totals.
- Depth-related sleep feedback now better reflects light-dominant nights instead of relying on deep-sleep percentage alone.

### Changed
- Weekly sleep-window aggregation now prefers canonical session start/end bounds when available, instead of relying only on derived duration placement.
- Sleep scoring pipeline now passes stage mix, timeline confidence, and source metadata into the score calculation.

### Internal
- Added targeted regression coverage for:
  - sleep day-view timeline timestamp rendering
  - weekly sleep-window axis bounds and cross-midnight behavior
  - stage-aware sleep score guardrails
  - limited-source / missing-REM scoring behavior
  - repository propagation of canonical session start/end times

## [0.8.0] - 2026-04-09

### Added
- User-facing maintenance uncertainty range and stabilization hints on adaptive recommendation surfaces.
- Canonical adaptive diet-phase tracking (`cut`/`maintain`/`bulk`) with deterministic 7-day confirmation for phase changes.

### Changed
- Adaptive nutrition recommendation now ships as a canonical Bayesian recursive system with explicit manual apply workflow.
- Adaptive recommendation observation scaling now uses confirmed-phase-age ramping (`3000 -> 7700` kcal/kg through week 9+) instead of window-length scaling.
- Generation semantics remain due-week anchored and deterministic within a due week, including force-recalculation replay behavior.
- Due-notification eligibility is strictly gated by due-week status, generated-state status, and notification-state status.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Hardened adaptive recommendation persistence with coherent snapshot/state checks, legacy fallback migration handling, and recovery from malformed canonical keys.
- Ensured backup/restore continuity for adaptive recommendation settings and canonical recursive state persistence.

### Internal
- Expanded adaptive nutrition regression coverage across domain/data/presentation/scenario layers, including long-horizon simulations, phase-transition scenarios, and backup/restore continuity validation.

### Acknowledgements
- Thanks to @Whatsonyourmind for thoughtful review and feedback on the adaptive nutrition model, uncertainty presentation, and edge-case framing during the 0.8.0 development cycle.

## [0.8.0-alpha.3-bayesian-preview.3] - 2026-04-08

### Added
- Canonical adaptive diet-phase model (`cut`, `maintain`, `bulk`) with persisted confirmed/pending phase tracking.
- Deterministic 7-day phase-change confirmation flow:
  - pending candidate starts on direction change
  - confirmed phase switches only after 7 stable days
  - reverting before confirmation cancels pending reset
- Lightweight residual-bias diagnostic seam for weekly observation validation:
  - mean residual summary
  - sample count
  - bias direction status (`neutral`, likely over/under-estimating energy density)

### Changed
- Replaced the window-length kcal/kg observation scaling with confirmed-phase-age ramping:
  - week 1 = `3000`
  - linear ramp to week 9 = `7700`
  - week 9+ stays at `7700`
- Exact target-rate changes no longer define new adaptive phases; only goal direction does.
- Adaptive recommendation copy (EN/DE) now uses simpler wording that clearly separates:
  - “still adapting/settling”
  - normal uncertainty around likely maintenance range
- Adaptive nutrition current-state docs updated for confirmed-phase semantics, ramp behavior, and residual diagnostics seam.

### Testing
- Expanded adaptive nutrition scenario-test infrastructure with reusable synthetic-truth and recovery metrics helpers:
  - convergence milestones (initial / week-4 / week-8 / week-12)
  - signed/absolute error progression
  - error half-life and settling-time checks
  - bounded overshoot/undershoot and truth-crossing checks
  - pre/event/post recovery-window summaries for posterior, variance, and confidence
  - bounded weeks-to-recover checks for transient event scenarios
- Strengthened ground-truth scenario assertions to validate quantitative convergence behavior, not only boundedness/stability.
- Strengthened chaotic scenario assertions (weekend spikes, refeed, water jump, illness, logging-quality phases) to validate measurable disruption and recovery behavior.
- Added comparative long-horizon profile validation (8–12 week style horizons) with directional plausibility checks across matched profile pairs:
  - heavier vs lighter
  - lean vs higher body-fat at comparable size
  - high vs low activity
  - male/female/unknown plausibility banding
  - high-steps vs low-steps long-horizon relation

## [0.8.0-alpha.3-bayesian-preview.2] - 2026-04-07

### Added
- Data-calibrated Bayesian noise adaptation for adaptive nutrition:
  - bounded history-informed scaling for `Q` (maintenance drift variance)
  - bounded history-informed scaling for `R` (observation variance)
  - deterministic fallback to conservative defaults when history is insufficient
- User-facing maintenance uncertainty transparency:
  - likely maintenance range derived from posterior uncertainty (`mean ± 1σ`)
  - plain-language uncertainty hints on adaptive recommendation surfaces
  - stabilization hint when the recursive estimate is still settling
- Stabilization sanity-check layer derived from live vs steady-state behavior:
  - quality flags for bootstrap/transient/noisy regimes
  - conservative confidence guard during settling phases
- Expanded Bayesian estimator/service/repository/UI tests for:
  - calibration responsiveness and bounds
  - fallback safety under sparse history
  - stabilization flags and onboarding stabilization copy
  - maintenance estimate/state persistence coherence

### Changed
- Adaptive nutrition current-state docs were updated for production-style clarity, including:
  - data-calibrated `Q/R` semantics
  - credible-interval presentation semantics
  - stabilization/sanity-check behavior
  - user-facing behavior
  - scheduling and stable data-window semantics
  - recursive Bayesian prediction/update chaining
  - apply vs recalculate behavior
  - persistence and due-notification semantics
  - confidence/warning interpretation
- The nutrition recommendation card and onboarding preview now include maintenance range + uncertainty/stabilization copy without changing explicit apply semantics.
- README documentation navigation label was tightened to reflect canonical Bayesian architecture wording.

### Internal
- Adaptive nutrition terminology and inline comments were normalized further around recursive Bayesian, uncertainty, and due-week semantics.

## [0.8.0-alpha.3-bayesian-preview.1] - 2026-04-06

### Added
- Experimental Bayesian/Kalman adaptive nutrition estimation path
- Atomic Bayesian experimental snapshot persistence
- Manual “Recalculate now” action for adaptive recommendations
- Recommendation freshness metadata in UI:
  - calculated at
  - next adaptive recommendation due
  - due now indicator
- Scheduler-based due-notification seam for new adaptive recommendations
- Richer estimator comparison/debug tracing
- Documented Bayesian estimator tuning parameters

### Changed
- Bayesian experimental state now uses atomic snapshot persistence as unified state storage
- Due-notification logic now requires:
  - recommendation is currently due
  - no recommendation has yet been generated for that due week
  - no notification has yet been sent for that due week
- Snapshot generation time is now sourced only from `recommendation.generatedAt`
- German adaptive notification strings now use proper umlauts and cleaner wording
- Manual recalculation now forces immediate regeneration without auto-applying active goals

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Safer handling of incoherent or corrupt Bayesian experimental state
- Safer migration from legacy fragmented Bayesian persistence
- Removed remaining active use of fragmented Bayesian write paths in normal experimental flow

### Internal
- Production heuristic recommendation path remains unchanged and authoritative
- Legacy fragmented Bayesian keys are now migration-only fallback support
- Documentation reviewed and updated to match final enforced behavior
## [0.8.0-alpha.2] - 2026-04-06

This alpha improves the adaptive nutrition recommendation MVP with more conservative sparse-data behavior, more robust trend estimation, better step-prior maintenance inputs, and clearer recommendation transparency.

### Added
- Recommendation transparency copy layer shared across onboarding and nutrition hub surfaces.
- New data-basis hint messaging for:
  - profile/prior-only recommendations
  - sparse recent weight logs
  - sparse recent intake logs
  - sparse weight + intake logs together
- New specific warning copy for macro-constrained recommendations.

### Changed
- `notEnoughData` recommendations are now strictly prior-only:
  - no inferred-maintenance blending
  - no week-over-week maintenance drift against previous recommendations
  - goal-rate calorie adjustment still applies on top of the prior estimate
- Prior maintenance estimation now uses step input with the following precedence:
  1. recent average actual daily steps
  2. configured daily step target
  3. fallback default of `8000`
- Recent actual step averages now use synced step data from the rolling lookback window when available.
- Weight-trend estimation now uses linear regression over EWMA-smoothed bodyweight data instead of endpoint-only delta.
- Recommendation surfaces now frame confidence as **data basis quality** rather than scientific certainty.
- Onboarding adaptive recommendation preview now shows:
  - data basis label
  - data basis counts
  - explicit prior-only messaging when applicable
  - prioritized warning text aligned with the nutrition hub card
- Recommendation warning prioritization is now more explicit:
  - calorie floor applied
  - unresolved food calories
  - large adjustment detected
  - macro distribution constrained
  - generic conservative fallback only when no more specific warning applies
- EN/DE adaptive recommendation wording was revised to match the new semantics and transparency model.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Prevented sparse-data recommendations from drifting maintenance estimates despite explicitly insufficient adaptive data.
- Reduced sensitivity of weekly trend estimation to noisy start/end bodyweight values.
- Improved recommendation copy so unresolved food-calorie issues are surfaced more clearly before apply.
- Fixed onboarding progress/button logic so the final onboarding page cleanly exposes the finish action.

### Documentation
- Updated the adaptive nutrition recommendation current-state documentation to match implementation truth for:
  - strict prior-only `notEnoughData` behavior
  - regression-based weight slope calculation
  - step-priority precedence (`actual -> target -> default 8000`)
  - compact prioritized basis/warning messaging
  - continued treatment of extra cardio as a coarse manual heuristic

### Testing
- Added and updated automated tests for:
  - strict prior-only engine behavior
  - actual-steps vs target-steps fallback precedence
  - regression-based weight trend calculation
  - prior-only UI messaging
  - unresolved-food warning rendering
  - onboarding preview transparency
  - final onboarding-page finish behavior

### Notes
- Extra cardio remains a manual heuristic input and is not backed by a dedicated cardio-tracking model.
- Recent actual step averages currently use usable logged days only within the lookback window.

## [0.8.0-alpha.1] - 2026-04-06

This alpha introduces the first end-to-end MVP of adaptive nutrition recommendations.

### Added
- Adaptive weekly nutrition recommendation foundation:
  - repository persistence
  - due-week scheduler
  - recommendation input adapter
  - recommendation engine
  - orchestration service
- Nutrition hub recommendation card integration with:
  - confidence + warning display
  - explicit apply action for active targets
- Onboarding adaptive recommendation flow with:
  - dedicated goal/rate/activity/cardio setup
  - dedicated optional body-fat onboarding step
  - body-fat guidance entry point with text-based male/female reference helper
- Goals screen recommendation settings for:
  - bodyweight goal direction
  - weekly target rate
  - baseline daily activity
  - extra cardio/endurance outside the app
- New adaptive recommendation persistence keys in `SharedPreferences` for settings/state snapshots.

### Changed
- Onboarding order is now:
  - Welcome
  - Profile
  - Bodyweight
  - Body fat %
  - Adaptive goal/recommendation settings
  - Calories
  - Macros
  - Water
- Baseline activity model expanded from 3 to 4 levels:
  - low
  - moderate
  - high
  - very high
- Activity-level helper UX is now structured and easier to scan (intro + one line per level), and remains separate from extra-cardio input.
- Prior maintenance estimation is now more personalized for MVP:
  - uses body-fat/lean-mass-aware path when body-fat % is available
  - falls back safely when body-fat is missing
  - applies declared baseline activity + extra-cardio influence conservatively
- Recommendation generation is stable per due week (no in-week drift from Monday vs later-week app-open timing).
- Recommendation-related EN/DE strings were moved/expanded in l10n and regenerated.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Prevented implausible calorie outputs from being surfaced without explicit constrained/warning handling.
- Hardened calorie-input aggregation paths to reduce systematic undercounting in common logging scenarios.
- Ensured backup/restore explicitly covers adaptive recommendation settings:
  - `adaptive_nutrition_recommendation.prior_activity_level`
  - `adaptive_nutrition_recommendation.extra_cardio_hours`

### Testing
- Added and updated automated tests for:
  - recommendation domain logic
  - recommendation persistence/state behavior
  - due-week stability behavior
  - onboarding/goals recommendation flows
  - backup/restore coverage for adaptive recommendation keys

## [0.7.10] - 2026-04-05

This release includes a fix for Diary refresh behavior after saving meals through the AI meal-recognition flow.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed a Diary refresh issue after saving meals via the AI meal-recognition flow
  - when a meal was recognized with AI and saved from the Add Food flow, the Diary screen did not always refresh automatically
  - the save result is now propagated correctly so the Diary reloads immediately after the meal is saved
  - no manual pull-to-refresh is needed in that flow anymore

### Notes
- This fix specifically addresses the Diary → Add Food → AI meal recognition path
- The direct AI recommendation save flow already propagated refresh correctly
## [0.7.9] - 2026-04-07

small fixes
## [0.7.8] - 2026-04-05

This release is a maintenance and stability update that prepares Hypertrack for the upcoming 0.8 / TDEE cycle.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed backup/restore integrity for meal-related data
  - meal templates and meal items are now included in backups
  - meal/nutrition restore behavior is more complete and reliable
- Improved nutrition backup robustness when food entries rely on product references / barcode fallback
- Improved goals/settings restore behavior
  - changed targets are restored correctly
  - fallback restore behavior no longer depends on profile payload always being present
- Improved supplement restore integrity
  - tracked-state and supplement history restore behavior are more reliable
- Improved workout restore fidelity
  - preserves more set metadata and ordering details during restore

### Improved
- Updated project dependencies to current resolvable versions
- Resolved API breakages caused by dependency upgrades
  - notifications
  - file picker
  - CSV handling
- Stabilized the automated test suite
  - fixed outdated expectations
  - reduced brittle widget-test failures
  - improved deterministic test behavior
- Expanded automated test coverage in important low-level areas
  - backup/restore
  - goals and target persistence
  - weight/history foundations
  - statistics data
  - storage/services

### Internal / maintenance
- Better regression protection for backup, restore, and persistence behavior
- Better groundwork for future TDEE development in 0.8
- General cleanup and hardening across data/services/test infrastructure

### Notes
- This is primarily a maintenance/stability release
- The focus of this version is correctness, persistence integrity, and preparation for the next major feature cycle

## [0.7.7] - 2026-04-04

This release focuses on AI provider expansion, AI settings cleanup, and a small Diary improvement.

### Added
- Optional **Sugar** tile for the Diary overview
  - can be enabled in Settings
  - disabled by default
  - uses existing sugar tracking + existing sugar target
  - rendered inside the existing top Diary overview section

- Expanded **AI provider support** for:
  - OpenAI
  - Google Gemini
  - Anthropic / Claude
  - Mistral
  - xAI / Grok

- AI settings improvements
  - dedicated grouped AI settings section
  - master **Enable AI features** toggle
  - AI features now default to **off**
  - provider, model, and API key configuration hidden unless AI is enabled

### Changed
- Reworked AI model selection logic for meal analysis
  - provider-specific curated model handling
  - live provider model APIs used as availability source
  - better ranking of newer/current models
  - improved provider-specific filtering
  - more robust selected-model resolution

- OpenAI integration improvements
  - better handling of model names / aliases
  - fixes for OpenAI request parameter handling
  - improved error reporting

- Gemini integration improvements
  - more robust model normalization and fallback handling
  - improved error reporting
  - better compatibility across Gemini model variants

- Diary overview layout updated
  - optional Sugar tile now appears in the same existing overview area
  - placed at the bottom of the left column when enabled

### Notes
- End-to-end tested providers in this release:
  - OpenAI
  - Gemini

- Implemented but not fully end-to-end verified in this release:
  - Anthropic
  - Mistral
  - xAI

## [0.7.6] - 2026-04-04

This release focuses on a small set of quality-of-life improvements across AI meal capture, measurements, workout logging, iOS navigation behavior, and rest timer alerts.

### Improved

- **AI meal capture UI**
  - Removed the dedicated in-app microphone button from the AI meal recognition screen
  - Moved camera and gallery actions directly into the main text input area for a cleaner and more focused layout
  - Preserved the existing prompt + image-based analysis flow

- **Measurements screen defaults**
  - The measurements chart now defaults to **weight** when weight data is available
  - Existing fallback behavior remains unchanged when weight is not present

- **Workout logging inputs**
  - Reps, weight, and related workout input fields are no longer prefilled with `0`, `0kg`, or similar zero-value defaults when unset
  - Empty fields now remain truly empty until the user enters data, while existing hint/subtext behavior is preserved

- **iOS navigation consistency**
  - Improved swipe-back behavior on iOS for settings-related navigation paths
  - Preserved explicit settings result propagation for cases where values actually changed

- **Pause timer completion alerts**
  - Foreground timer completion continues to trigger an audible/vibration alert
  - Background timer completion now more reliably triggers a notification instead of silently finishing

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.


- Fixed AI meal capture layout/actions so media input controls are placed where users expect them
- Fixed measurement chart default selection logic
- Fixed workout field initialization so unset values are not rendered as actual entered values
- Fixed a settings/navigation path that interfered with native iOS back-swipe behavior
- Fixed the Android/background timer completion path so users are still alerted when the app is not in the foreground

## [0.7.5] - 2026-04-04
### added
- [#200](https://github.com/rfivesix/hypertrack/issues/200) added a consistend app color. Changed the iOS App icon (The white mode icon got the same color as the dark mode icon) for consistency

### fixed
- [#143](https://github.com/rfivesix/hypertrack/issues/143) fixed audio recording in ai_meal_capture_screen.dart. 
- [#203](https://github.com/rfivesix/hypertrack/issues/203) fixed OFF database re-initialization
- [#205](https://github.com/rfivesix/hypertrack/issues/205) fixed german translation

## [0.7.4] - 2026-04-04

This release completes the main **sleep module rollout** and adds the first full version of **one-way health platform export**.

### Added

- **Sleep module** integrated across the app
  - day / week / month sleep views
  - sleep detail screens
  - sleep timeline visualization
  - sleep score overview
  - sleep statistics integration
- **Sleep Health Score V2**
  - duration
  - continuity
  - regularity
  - more conservative and better documented scoring model
- **Sleep localization pass**
  - localized sleep UI strings
  - cleaned up remaining hardcoded sleep text
- **One-way health export** from Hypertrack to:
  - **Apple Health (HealthKit)**
  - **Google Health Connect**
- Export support for:
  - **body measurements**
  - **nutrition aggregates**
  - **hydration**
  - **workout sessions**
- New **Health Export** settings surface with:
  - platform toggles
  - permission handling
  - export status visibility
  - manual export trigger

### Improved

- **Sleep scoring**
  - better weighting and calibration toward duration / continuity / regularity
  - clearer documentation of evidence-based vs heuristic parts
  - cleaner handling of missing data and score completeness
- **Sleep pipeline / persistence**
  - improved nightly analysis flow
  - explicit scoring versioning
  - regularity calculation support
  - more robust persistence and repository integration
- **Sleep documentation**
  - canonical sleep current-state documentation
  - canonical sleep health score documentation
  - cleaned and consolidated sleep docs
- **Sleep UX**
  - better empty states
  - more consistent detail pages
  - improved score/state wording
  - better navigation coverage
- **Workout export quality**
  - workout export now includes title plus notes/summary text where supported
  - improved session-level export payload quality
- **Health export reliability**
  - full-history initial export
  - incremental follow-up export
  - per-domain checkpoint behavior
  - retry-safe idempotent export bookkeeping
  - chunked export handling for larger histories
- **Timezone handling**
  - export uses source event offsets where available instead of forcing UTC everywhere
- **Diagnostics**
  - clearer export failure summaries
  - better distinction between app-side write problems and downstream platform display limitations

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.


- Removed the previous effective **30-day export cap** for initial health export flows
- Fixed multiple **Health Connect write-path issues**, including:
  - invalid equal start/end intervals
  - body-fat export handling
  - nutrition/hydration write stability
  - quota-related write behavior through safer batching
- Fixed incremental export behavior so a failed domain does not unnecessarily force all other domains back into broad reload behavior
- Fixed remaining sleep-module localization gaps
- Fixed several sleep navigation / presentation rough edges found during beta testing

### Documentation

- Added / updated:
  - sleep current-state documentation
  - sleep health score v2 documentation
  - one-way health export documentation
  - overview / architecture / storage references
  - README links and module references
- Reduced outdated or duplicate sleep documentation in favor of clearer canonical sources

### Notes

- **Sleep export/import scope remains unchanged**: the sleep module is about processing and analytics inside Hypertrack, not external sleep write-back.
- **Health export is one-way only**. Hypertrack remains the authoritative record.
- **Nutrition export is aggregate-based only**. No ingredient or individual food-item reconstruction is exported.
- **Workout export is session-level only**. Internal workout structure is not exported as structured native workout data.
- Some downstream behavior, especially in **Google Fit**, may differ from what is actually stored in **Health Connect**. If a field is written correctly but not surfaced there, that is a downstream display limitation rather than a Hypertrack write failure.

## [0.7.4-beta.1] - 2026-04-04

This beta focuses on **one-way health platform export** and the final stabilization work around that integration.

### Added
- **One-way health export** from Hypertrack to:
  - **Apple Health (HealthKit)**
  - **Google Health Connect**
- Export support for:
  - **Body measurements** (for example weight, body fat where supported)
  - **Nutrition aggregates** (calories, protein, carbs, fat, fiber, sugar, salt/sodium mapping)
  - **Hydration**
  - **Workout sessions**
- New **Health Export** settings section with:
  - per-platform enable/disable
  - permission handling
  - export status visibility
  - manual export trigger

### Improved
- **Health export reliability**
  - initial export can backfill the full history
  - follow-up exports are incremental
  - idempotent export tracking prevents duplicate writes
  - export runs are chunked for safer large-history syncs
- **Workout export quality**
  - improved workout title handling
  - workout export now includes description text plus a compact plain-text set summary where supported
- **Timezone handling**
  - export now uses source event offsets where available instead of forcing UTC in all cases
- **Diagnostics**
  - more accurate domain-level export failure summaries
  - better distinction between app-side export problems and downstream platform display limitations

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Removed the previous effective **30-day export limit** for initial export flows
- Fixed multiple **Health Connect write-path issues** around:
  - invalid record intervals
  - body-fat export handling
  - nutrition/hydration export stability
  - quota-related write behavior via safer batching
- Fixed incremental export behavior so one failed domain does not force unnecessary full-history reloads for all other domains

### Notes
- Export remains **one-way only**. Hypertrack is the authoritative record.
- Nutrition export remains **aggregate-based only**. No ingredient- or food-item reconstruction is exported.
- Workout export remains **session-level only**. Internal workout structure is not exported as native structured workout content.
- Some downstream display behavior, especially in **Google Fit**, may differ from what is stored in Health Connect. If a field is written correctly but not shown in Google Fit, this is a platform display limitation rather than a Hypertrack write failure.

### Documentation
- Added and updated implementation-focused documentation for the one-way health export module
- Updated project docs and overview references to reflect the current health export behavior
## [0.7.4-alpha.1] - 2026-04-03

This alpha focuses on one-way health export hardening for Android Health Connect and adds richer session context for workout exports without expanding structured workout scope.

### Added
- Workout export note-summary text built from logged exercises/sets and attached to exported workout sessions.
- Standardized set-line note formatting for export summaries:
  - one line per exercise,
  - set entries as `<setType> <weight>kg x <reps>`,
  - set-type abbreviations `W` (warm-up), `S` (standard), `F` (failure), `D` (dropset).
- Android Health Connect workout export now writes the summary to `ExerciseSessionRecord.notes`.
- Apple Health workout export now persists the summary in workout metadata (`hypertrack_workout_summary`).

### Changed
- Health export workout payload model now includes an optional notes field for platform writers.
- Workout export data loading now includes associated set logs to build ordered note summaries.
- Nutrition/Hydration grouped export flow now records split diagnostics so failures can indicate whether nutrition and hydration failed independently.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Android body-fat export mapping now recognizes real stored measurement type variants (including `fat_percent`) so body-fat entries are no longer dropped before write.
- Android body-fat export normalization/range handling aligned to Health Connect `BodyFatRecord` percent expectations (`0..100`).
- Android nutrition export reliability improved:
  - strict interval validation now respected (`startTime < endTime`),
  - defensive per-field sanitization for calories/macros/fiber/sugar/sodium,
  - optional-field fallback retry to isolate problematic nutrition fields.
- Android hydration export interval validation fixed (`startTime < endTime`) to prevent rejected writes.
- Android BMI export no longer reports false-success when unsupported by the current Health Connect writer path.

### Tests
- Expanded health-export data source tests to validate workout summary note formatting and ordering across multiple exercises/sets.
- Maintained passing targeted export tests for data source, service orchestration, and adapters.

## [0.7.3] - 2026-04-03

This stable release includes all `0.7.3-alpha.*` and `0.7.3-beta.1` changes since `0.7.2`, with Sleep moved from early alpha foundations to a release-ready implementation baseline.

### Added
- End-to-end Sleep tracking across iOS (HealthKit) and Android (Health Connect), including sessions, stages, and overnight heart-rate ingestion.
- Sleep Day experience (timeline, score, and key metric tiles) plus detail pages for Duration, Heart rate, Regularity, Depth, and Interruptions.
- Sleep week/month scoped overview support and broader period navigation behavior.
- Sleep entry points from Statistics Hub and Settings.
- Sleep settings controls for tracking toggle, permissions/access flow, import actions, and raw-import visibility.
- Persisted nightly analysis metadata for score completeness and regularity outputs (SRI, valid-day count, stability).
- Sleep Health Score V2 (`sleep-health-score-v2`) as canonical score model with updated documentation and regression coverage.
- Automatic throttled sleep import orchestration (`importRecentIfDue`) for periodic sync checks.
- Expanded localized Sleep copy across setup, status, empty states, timeline/status labels, and detail messaging.

### Changed
- Sleep scoring evolved from V1 to V2:
  - top-level weights now Duration `40%`, Continuity `35%`, Regularity `25%`
  - stricter duration mapping with stronger short-sleep penalties
  - continuity remains SE + WASO with internal renormalization
  - regularity remains SRI with lower top-level compensation weight
- Sleep pipeline default analysis version set to `sleep-health-score-v2`.
- Sleep navigation and overview flow refined across day/week/month scopes.
- Sleep settings and status UX refined to better separate setup/access/data state.
- Sleep timeline presentation redesigned into staged bar-style rendering with clearer legend/axis behavior.
- Sleep benchmark bars (duration/heart-rate detail views) updated for better contrast in light/dark mode.
- Statistics-to-Sleep integration refined while preserving clear feature ownership boundaries.
- Settings section labels updated to release wording (`Sleep/Schlaf`, `Steps/Schritte`).
- Project docs rewritten and consolidated around implementation-first references.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Manual `Import sleep data now` now performs full-history backfill import.
- Automatic/periodic sleep import remains incremental (30-day lookback), preserving prior history while refreshing recent windows.
- Sleep score pipeline issues that previously left scores missing/uncomputed on live import.
- Interruption detection and wake-duration gaps in nightly outputs.
- Sleep heart-rate handling issues affecting import completeness, baseline/delta behavior, and display consistency.
- Health Connect stage-mapping issues that could misclassify wake-related segments.
- Nightly analysis persistence and derived-field propagation gaps.
- Forced recompute cleanup now removes raw/canonical/derived records consistently for the affected window.
- Diary and Statistics refresh flows now trigger periodic sleep sync checks.
- Removal of temporary hardcoded sleep debug data from day-overview presentation.
- Remaining key localization inconsistencies and hardcoded Sleep UI text in primary surfaces.
- Release-readiness documentation/comment drift (broken links, stale wording, ambiguous notes) aligned to current implementation.

### Tests
- Added/expanded targeted coverage for:
  - sleep mapping and persistence DAOs
  - permissions/adapters and sync service behavior
  - navigation and settings flows
  - sleep scoring engine and regularity index
  - nightly-analysis persistence and pipeline processing
  - heart-rate baseline chronology
  - forced recompute behavior
  - automatic import throttling behavior

## [0.7.3-beta.1] - 2026-04-03

This release promotes the current Sleep feature set from alpha toward beta by finalizing score behavior, settings labeling, timeline presentation, and import orchestration. Sleep scoring is now stricter for short duration nights (V2), settings labels are language-correct and no longer marked as alpha/batch, and sleep import now supports both all-time manual backfill and recurring incremental sync behavior.

### Added
- Sleep Health Score V2 as the new canonical scoring model (`sleep-health-score-v2`) with updated documentation and regression coverage.
- Automatic throttled sleep import orchestration (`importRecentIfDue`) to check for new data regularly without excessive repeated imports.
- New sync-service test coverage for automatic import throttling behavior.

### Changed
- Sleep score model updated from V1 to V2:
  - top-level weights now Duration `40%`, Continuity `35%`, Regularity `25%`
  - stricter duration piecewise mapping with stronger penalties below 7h (especially below 6h)
  - continuity remains SE + WASO only, with internal renormalization
  - regularity remains SRI, with reduced top-level compensation weight
- Sleep pipeline default analysis version changed to `sleep-health-score-v2`.
- Sleep settings section title changed from `Sleep/Schlaf (Batch 2)` to `Sleep/Schlaf`.
- Steps settings section title changed from `Health Steps (Alpha)` to `Steps/Schritte` based on selected language.
- Sleep timeline card was redesigned to a staged bar-style timeline with cleaner legend and axis behavior.
- Sleep benchmark bars (duration/heart-rate details) received contrast adjustments for dark and light mode readability.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Manual `Import sleep data now` now performs all-time backfill import instead of a 30-day test-only import.
- Automatic/sequential sleep import remains incremental (30-day lookback), preserving previously imported historical data while adding/updating newer records.
- Diary and Statistics refresh flows now trigger periodic sleep sync checks similarly to existing steps refresh behavior.
- Removed temporary hardcoded sleep debug data from day overview presentation.

## [0.7.3-alpha.4] - 2026-04-02

This alpha finalizes the Sleep health-score pass. It documents and ships the implemented V1 scoring model, persists additional nightly analysis fields for score completeness and regularity, expands Sleep day/detail messaging and localization, and refreshes core documentation so release notes and docs align with implementation.

### Added
- Sleep Health Score V1 documentation describing the implemented scoring model, component weights, regularity rules, completeness semantics, and known limitations.
- A canonical Sleep current-state document that describes the routed screens, repositories, pipeline flow, persistence layers, and implementation boundaries.
- Persisted nightly-analysis fields for score completeness and regularity outputs, including SRI, valid-day count, and stable/preliminary state.
- Additional localized Sleep copy for empty states, timeline/status labels, sleep-score messaging, regularity messaging, heart-rate messaging, and raw-import metadata in English and German.
- Targeted regression coverage for the updated sleep scoring engine, nightly analysis persistence, pipeline processing, navigation, settings, and regularity index calculation.

### Changed
- Updated the Sleep scoring engine to the implemented `sleep-health-score-v1` model using top-level Duration, Continuity, and Regularity components with renormalization when component data is missing.
- Sleep pipeline analysis now computes nightly regularity history from persisted sessions/stages, carries score completeness and regularity metadata forward, and writes those values into derived nightly analyses.
- Sleep repositories and day-overview composition now expose persisted score-completeness, regularity, and heart-rate sample data to presentation surfaces.
- Sleep day/detail presentation was refined to better communicate unavailable data, import/setup actions, score-quality state, regularity maturity, and heart-rate baseline/sample availability.
- Project documentation was rewritten to be implementation-focused and current-state-first across the README, architecture, data/storage, overview, statistics, and sleep technical references.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed release/documentation accuracy by replacing stale or historical descriptions with implementation-grounded documentation and clearer boundaries around what is actually implemented.
- Fixed nightly-analysis persistence gaps so newly computed score completeness and regularity fields round-trip through schema migration, DAO writes, and repository mapping.
- Fixed score-model consistency by aligning the pipeline, persisted analysis version, and documentation around the same Sleep Health Score V1 behavior.
## [0.7.3-alpha.3] - 2026-04-01

This alpha significantly expands the Sleep module from early foundation work into a usable end-to-end feature set for testing. It adds broader Sleep navigation and overview coverage, improves setup and sync flows, strengthens Health Connect ingestion, and fixes key issues in scoring, heart-rate handling, and interruption detection, alongside localization, stability, and test coverage improvements.

### Added
- Sleep module progression from initial day-only flow toward connected day, week, and month experiences
- Sleep week and month overview support for broader period-based navigation and summaries
- Statistics tab entry points into Sleep flows
- Expanded Sleep settings surfaces for permissions, sync, and debug/import visibility
- Additional Sleep localization coverage across screens, labels, and state messaging
- Additional automated coverage for Sleep aggregation, pipeline, persistence, and presentation paths

### Changed
- Refined Sleep navigation structure and routing across day, week, and month scopes
- Improved Sleep settings, permission, and sync UX to better distinguish setup state, access state, and data state
- Updated Sleep data flow to rely more consistently on derived and repository-backed outputs
- Improved Health Connect ingestion behavior and mapping for sleep-stage and heart-rate records
- Refined Sleep overview and detail screen behavior, layout consistency, and fallback handling
- Improved Statistics-to-Sleep integration while keeping Sleep logic owned by the Sleep feature
- Updated repository and aggregation layers to support broader Sleep summaries and derived period views

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed Sleep score pipeline issues that caused scores to remain missing or uncomputed on the live import path
- Fixed interruption detection gaps that caused wake/interruption results to be missing or unavailable
- Fixed Sleep heart-rate handling issues affecting import completeness, baseline/delta availability, and display
- Fixed Health Connect stage-mapping gaps that could incorrectly classify wake-related segments
- Fixed issues in nightly analysis persistence and derived field propagation
- Fixed localization inconsistencies and remaining hardcoded Sleep UI text in key surfaces
- Fixed several Sleep-related stability problems across sync, repository, and overview flows
- Improved regression protection with targeted test additions and updates for recent Sleep fixes
## [0.7.3-alpha.2] - 2026-03-31

### App Icon
- updated the app icon

### Sleep module
- Corrected sleep heart-rate baseline calculation to use the **last 30 nights in chronological order** before computing the median.
- Added regression coverage for the HR baseline chronology behavior.

### Sleep pipeline / recompute
- Fixed forced recompute so raw, canonical, and derived sleep data are removed **consistently for the affected session time window**.
- Raw imports are now cleared via the associated session IDs instead of broad imported-at behavior.
- Derived nightly analyses are now cleared via the affected night-date range.
- Added test coverage for forced recompute behavior.

### Documentation
- Updated the sleep issue audit document to reflect implementation status more accurately.
- Adjusted claims for issues **#166, #170, #173, and #175** to match the actual implementation state more honestly.
- Explicitly documented remaining missing wiring and limitations.

### Tests
- Added/updated targeted tests for:
  - heart-rate baseline chronology
  - sleep pipeline forced recompute behavior

## [0.7.3-alpha.1] - 2026-03-31

### Added
- **Sleep tracking (alpha) across iOS and Android:** Added HealthKit and Health Connect ingestion for sleep sessions, stages, and overnight heart rate with new native method-channel bridges and permissions.
- **Sleep Day experience (Batch 2):** Added the Sleep Day overview (timeline, score, and key tiles) plus dedicated detail screens for Duration, Heart rate, Regularity, Depth, and Interruptions, with shared navigation routing.
- **Sleep controls in Settings:** Added a Sleep section to enable tracking, request permissions, run a manual 30‑day import, and view raw import payloads.
- **Statistics Hub entry:** Added a Sleep card to launch the new Sleep Day overview.

### Changed
- **Sleep data persistence:** Added canonical sleep tables and raw import storage to power the day experience and detail views.
- **Summary card layout:** Added an optional margin configuration to support sleep UI layouts.

### Tests
- Added coverage for sleep mapping, persistence DAOs, permissions/adapters, sync service behavior, navigation, settings UI, and regularity chart math.

## [0.7.2] - 2026-03-31

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Duplicate caffeine logging for fluid entries:** Fixed an issue where saving caffeinated drinks could create duplicate caffeine supplement logs, leading to inflated caffeine totals.

### Tests
- Added regression coverage to ensure fluid entries no longer create duplicate caffeine supplement logs.

## [0.7.1] - 2026-03-27

### Added
- **Native health steps tracking across iOS and Android:** Added Apple HealthKit and Google Health Connect integration for reading and syncing step data into Hypertrack, including the platform bridge, persisted segment storage, and daily step goal support.
- **Dedicated Steps experience:** Added a dedicated steps detail screen with Day/Week/Month views, period navigation, richer trend context, and tighter integration into Diary, Statistics Hub, Settings, Goals, and onboarding.
- **Steps source controls:** Added provider selection and source-policy controls, including `Auto (dominant source)` and `Merge (max per hour)` to better handle overlapping multi-source health data.
- **Regression coverage for the new steps flow:** Added tests for sync idempotency, source aggregation behavior, steps hub visibility, backup fallback handling, onboarding flow, and steps module behavior.

### Changed
- **Smarter steps sync behavior:** Permissions are now requested when tracking is enabled instead of on every sync, refresh behavior is more resilient, and step-related UI updates propagate more reliably across diary and statistics surfaces.
- **Steps charts and summaries:** Refined weekly/monthly trend rendering, baseline behavior, goal labeling, and statistics-card presentation for clearer interpretation of step progress.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Android Health Connect completeness:** Fixed paginated `readRecords` ingestion so all result pages are processed, resolving missing or undercounted daily totals on Android.
- **Duplicate and inflated step totals:** Fixed overlap handling after disabling and re-enabling tracking, and improved multi-source aggregation to avoid double counting.
- **Statistics steps visibility:** Steps are now shown on the statistics screen only when tracking is enabled, with live updates after settings changes.
- **Backup destination reliability:** Fixed auto-backup failures for invalid or unwritable folders and added SAF-backed writing to the exact user-selected external folder on Android.
- **Workout and AI polish:** Localized cardio set-row headers and improved Android speech-recognition availability and retry handling in AI meal capture.

## 0.7.1-beta.1 - 2026-03-27

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Cardio set-row header localization (#75):** Localized cardio header labels (`Distance`, `Time`, `Intensity`) in workout set rows.
- **Statistics steps visibility (#150):** Steps metric is now shown on the statistics screen only when step tracking is enabled in settings, with live UI updates when toggled.
- **Auto backup reliability (#151):** Fixed auto-backup failures for invalid/unwritable selected folders by validating writability and falling back to a safe app backup directory.
- **Android auto-backup folder targeting (#151):** Added SAF-based folder access so backups can be written to the exact user-selected external folder path on Android.
- **AI meal voice capture on Android (#143):** Improved speech recognition initialization/retry flow and Android-specific availability handling; fixed platform guidance text (no more incorrect iOS-only prompt on Android).
## 0.7.1-alpha.4 — 2026-03-26

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Android Health Connect paging:** Fixed `readRecords` ingestion to read all pages instead of only the first result page.
- **Missing steps on Android:** Resolved undercounted daily totals caused by incomplete Health Connect imports (especially visible when comparing Hypertrack vs Google Fit / Withings).

## 0.7.1-alpha.3 — 2026-03-26

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Steps inflation after re-enabling tracking:** Resolved an issue where daily totals could jump too high after disabling and re-enabling step tracking.
- **Idempotent refresh pipeline:** Force refresh and incremental refresh now safely replace overlapping sync windows to prevent duplicate counting.
- **Safer multi-source aggregation:** Improved handling for overlapping sources (e.g. smartwatch + phone / Withings + system) to avoid double counting.

### Added
- **Steps source policy (Settings):**
  - `Auto (dominant source)` (default, recommended)
  - `Merge (max per hour)`
- **Debug diagnostics for sync:** Added debug logging of sync window/fetch stats plus per-source daily totals to speed up troubleshooting.

### Tests
- Added coverage for:
  - disable -> re-enable -> overlapping sync window (no inflation),
  - multi-source overlap behavior for both source policies.
## [0.7.1-alpha.2+70006] - 2026-03-26

### Added
- **Steps Module UX (Day/Week/Month):** Expanded the dedicated steps screen with clear Day/Week/Month views and period navigation for date/week/month switching.
- **Richer Step Trend Context:** Added compact insight chips in trend cards (total, active hours, peak hour, average/day, goal-hit days) for faster interpretation.

### Changed
- **Weekly & Monthly Steps Visualization:** Reworked bars/labels to better match the intended visual style (clean baseline, target reference line, improved spacing and readability).
- **Statistics Hub Steps Card:** Refined the reusable steps card rendering and alignment so it visually matches the redesigned steps module.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Bar Baseline Consistency:** Step bars now correctly grow from zero baseline in trend charts instead of appearing visually offset.
- **Goal Label Alignment:** Goal labels (for example `8k`) are now positioned directly at line height instead of drifting above the dashed target line.
- **Week Chart Scaling Accuracy:** Goal check markers no longer affect bar-height calculations, preventing subtly shortened bars.
- **Day Histogram Scaling:** Hourly bars now scale against the actual drawable chart height, fixing incorrect visual heights in the daily timeline.

## [0.7.1-alpha.1] - 2026-03-26

### Added
- **Health Steps Integration (Alpha):** Read and sync daily step data from native health providers directly into the diary.
  - **Android – Health Connect:** Full integration with Health Connect on Android 14+ (API 34+). Includes all required manifest declarations (`READ_STEPS` permission, `ACTION_SHOW_PERMISSIONS_RATIONALE` intent-filter, `VIEW_PERMISSION_USAGE` activity-alias, and `health_permissions` resource).
  - **iOS – HealthKit:** Native Swift implementation using `HKSampleQuery` to read `stepCount` data. Configured with `NSHealthShareUsageDescription` and HealthKit entitlement.
  - **Platform Bridge:** New `MethodChannel` (`hypertrack.health/steps`) with three methods: `getAvailability`, `requestPermissions`, `readStepSegments`.
  - **Sync Service:** Automatic background sync with 48h overlap window, SHA1-based deduplication, and configurable provider filter (All / Apple / Google).
  - **Steps Goal:** Users can set a daily steps goal during onboarding and in the goals screen, with historical goal tracking via `daily_goals_history`.
- **Settings – Health Steps Section:** New settings section to enable/disable step tracking and select the preferred health data provider.
- **Database:** Added `health_step_segments` table with `ON CONFLICT` upsert logic and `target_steps` column in `app_settings` and `daily_goals_history`.

### Changed
- **Smarter Permission Flow:** Permissions are now requested only once when the user enables step tracking in Settings (not on every sync cycle), reducing permission dialog fatigue.
- **Diary Refresh on Return:** The diary screen now automatically refreshes its data when returning from Settings or Profile, ensuring step tracking changes are immediately visible.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **"App Update Required" on Android 14+:** Added the missing `<activity-alias>` for `VIEW_PERMISSION_USAGE` with `HEALTH_PERMISSIONS` category, which Android 14+ requires to recognize the app as Health Connect-compatible.
- **Sync Error Handling:** `StepsSyncService.sync()` now gracefully catches `PlatformException` when permissions are missing, instead of crashing or repeatedly prompting the user.

## [0.7.0] - 2026-03-25

### Added
- **Statistics & Analytics Hub:** Fully integrated central overview for consistency, PR progress, muscle distribution, recovery readiness, and body/nutrition trends.
- **Deep-Dive Analytics Screens:** Dedicated dashboards accessible from the hub for PRs, consistency tracking, recovery analysis, muscle-group trends, and body/nutrition correlation.
- **Universal Sharing Workflows:** Export and share app-generated content (including text summaries and exported files) through native OS share sheets for faster collaboration or coach feedback.

### Changed
- **Smarter Analytics Architecture:** Refactored statistics to use clearer feature boundaries (domain/data/presentation), making analytics behavior more consistent and maintainable.
- **Reliable Range Logic:** Standardized time-range handling across the hub and drill-down views so metrics remain easier to interpret.
- **Improved Analytics Readability:** Unified labels, chart defaults, and numeric formatting across statistics screens for cleaner trend reading.
- **Data-Quality-Aware Insights:** Body/nutrition and muscle analytics now apply clearer confidence and sufficiency rules before presenting stronger guidance.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Refined Statistics Behavior:** Addressed several v0.7 alpha rough edges regarding analytics state handling and presentation consistency.
- **Core Tracking Polish:** Targeted reliability and UX refinements for workout and nutrition logging during the v0.7 stabilization cycle.

### Security (Privacy)
- **Offline-First Analytics:** Ensured all insights are computed strictly on-device from existing logs, requiring no cloud dependency and maintaining the default privacy-first approach.

## [0.7.0-alpha.3+70003] - 2026-03-21

### 📊 Statistics Module (Architecture)
- Introduced a dedicated Statistics feature module under `lib/features/statistics/` with explicit domain/data/presentation boundaries.
- Added centralized range-resolution semantics via `StatisticsRangePolicyService` for mixed selected/fixed/capped/dynamic-all behavior across hub and drill-down analytics.
- Added centralized data-quality semantics via `StatisticsDataQualityPolicy` for body/nutrition insight confidence and muscle-distribution sufficiency checks.
- Expanded typed analytics payload usage (`TrainingStatsPayload`, `WeeklyConsistencyMetricPayload`, `RecoveryAnalyticsPayload`, `BodyNutritionAnalyticsResult`, `StatisticsHubPayload`) to reduce reliance on untyped map access in core statistics flows.
- Added hub/data composition adapters (`StatisticsHubDataAdapter`, `BodyNutritionAnalyticsDataAdapter`) to consolidate multi-source analytics loading.

### 🧭 Statistics UX (User-visible)
- Statistics Hub now acts as the primary analytics portal with compact summaries and drill-down routing for:
  - Performance (PR and notable improvement context)
  - Consistency (weekly trend signal)
  - Muscle analytics (distribution emphasis)
  - Recovery readiness
  - Body/Nutrition correlation
- Improved consistency of analytics labels, numeric formatting, and state display behavior through shared presentation formatter and chart defaults.
- Preserved intentional fixed-window semantics where applicable (for example hub 6-week consistency context and tracker calendar windows), with UI chips still available for metrics that follow selected-range behavior.

### 📝 Notes
- This release continues to treat analytics as on-device, read-only derived views over existing workout, nutrition, fluid, and measurement logs.

## [0.7.0-alpha.2] - 2026-03-10

### 📊 Analytics Polish
- **Consistency metrics expansion**: Added `getWeeklyConsistencyMetrics()` in `WorkoutDatabaseHelper` to provide weekly frequency, duration, and tonnage in one dataset.
- **Consistency Tracker upgrades**: Introduced metric toggle (Volume, Duration, Frequency), improved axis labeling, and switched charts to use richer weekly metric data.
- **Statistics Hub improvements**: Added the same consistency metric toggle to the hub cards for a faster top-level overview.
- **Muscle Group Analytics radar**: Added a new radar visualization for relative muscle volume distribution, including compact top-group aggregation.
- **Recovery Tracker radar + context**: Added heuristic radar pressure view and expanded per-muscle context (recent load amount and heuristic window hints).
- **Body/Nutrition analytics readability**: Improved section hierarchy and chart labeling for trend interpretation.

### 🧩 UI Consistency
- Added shared analytics UI primitives:
    - `AnalyticsSectionHeader` for consistent section titling.
    - `AnalyticsChartDefaults` for standardized chart setup (titles, line behavior).
- Standardized selected line charts to straight-line rendering for clearer trend reading.

### 🌍 Localization
- Added new localization keys for radar/caption and recovery heuristic details (EN/DE).
- Refined German copy quality by replacing legacy ASCII spellings (e.g. `ae/oe/ue`) with proper umlauts where applicable.

### 🧪 Notes
- This release focuses on post-alpha analytics UX clarity and interpretation support, without changing the core training log workflow.

## [0.7.0-alpha] - 2026-03-09

_Note: This is an alpha release, heavily focusing on the new deep-dive Analytics engine. Some areas, UI patterns, and data visualizations may still evolve based on feedback._

### 🚀 Analytics
- **Data Hub Redesign**: Introduced a comprehensive new Statistics Hub replacing the basic overview.
- **Deep-Dive Dashboards**: 
  - **PR Dashboard**: Tracks Personal Records and progressive overload.
  - **Recovery Tracker**: Assesses muscle fatigue and readiness.
  - **Consistency Tracker**: Monitors workout adherence over time.
  - **Muscle Group Analytics**: Visualizes training volume and intensity per body part.
- **Exercise-Level Analytics**: Integrated workout trends and PR summaries directly into individual `ExerciseDetailScreen` sections.
- **Advanced Offline Metrics**: Expanded `workout_database_helper` to calculate complex, multi-variable insights entirely on-device without cloud connectivity.

### 🏋️ Live Workout
- **Background Rest Timers**: Added native local push notifications via `flutter_local_notifications` to reliably alert you when your rest timer is over, even when the app is minimized or the screen is off.

### 🍎 Body / Nutrition
- **Body & Nutrition Correlation**: Introduced algorithms and a new tracking screen to evaluate how your macro and caloric intake impacts long-term body measurement and weight trends.

### 🌍 Localization / Polish
- **Extensive Translations**: Added over 1,000 new localization entries across German and English to cover all complex terminology in the new Analytics tools.
- **UI Refinements**: Polished the Main Screen, Profile Screen, and Add Measurement interfaces to align with the new Data Hub aesthetic.

### 🔧 Stability / Cleanup
- Swept the codebase to remove testing/debug leftovers prior to Alpha release.
- Upgraded Android build configurations (`AndroidManifest.xml` / `build.gradle.kts`) to securely manage exact alarm permissions for the new background timer notifications.

## [0.6.1] - 2026-03-09

### ✨ New Features & Improvements
- **Supplement Tracking History**: Implemented historical tracking for supplement settings (goals, limits, and doses) for accurate long-term analysis and charting.
- **Refined AI Meal Recommendations**: Adjusted macro calculations so meal suggestions dynamically portion out the remaining daily targets based on the specific meal type (Breakfast, Lunch, Dinner, Snack). Added a text box for custom wishes and dietary limitations.
- **Enhanced AI Context**: The AI now correctly utilizes real historical daily goals instead of default app settings when generating recommendations.
- **Performance Boost (Isolates)**: Offloaded AI image processing to a background isolate, significantly improving UI responsiveness and overall performance during photo analysis.

### 🔐 Security & Maintenance
- **Enhanced Encryption**: Updated encryption iterations for improved data-at-rest security while maintaining backward compatibility with older backups.
- **Codebase Polish**: Translated remaining German comments and strings in the database layer to English to maintain codebase consistency.

## [0.6.0] - 2026-03-06

### 🚀 Major Release: The "AI Nutrition Overhaul"

This release fundamentally upgrades how meals can be logged by leveraging on-device and cloud AI, drastically reducing the friction of tracking nutrition. It also adds personalized meal recommendations.

### ✨ Top Features
- **AI Meal Capture Screen**: You can now log complex meals automatically via a single photo, voice dictation, or a quick text description. 
- **AI Recommendations**: Receive personalized meal, snack, and drink recommendations directly within the app, specifically tailored to perfectly fill out your remaining daily macronutrients, while respecting your dietary preferences (Vegan, Quick, etc.).
- **Magical AI Interface**: Brand new, fully animated magical UI for AI features, providing visual feedback during analysis with an elegant gradient design.
- **Smart Ingredient Matching**: AI identifies local database items based on the language of your device, combining and portioning foods intuitively (like merging multiple eggs).
- **Privacy Controls**: Added an "AI Kill-Switch" in settings to globally disable all AI interfaces if preferred. API keys are encrypted at rest using native secure storage (`flutter_secure_storage`).

### 🧠 Logic & Database Overhaul
- **Re-ranked Fuzzy Search**: Implemented dart-side re-ranking to prioritize exact database matches, base foods over user creations, and handle compounding accurately. 
- **AI System Prompts**: Custom system prompts block nutritional hallucinations, enforcing the AI to strictly identify weights and component names.
- **No API Lock-in**: Select between OpenAI (GPT-4o) and Google Gemini (Flash) seamlessly depending on your preferred API key.

### 🎨 UI/UX Refinements
- **Glass Bottom Menus**: Introduced consistent glassmorphism to bottom sheets across the entire app for value editing.
- **Minimalist Aesthetic**: Removed heavy neon backgrounds in favor of targeted gradient accents on UI entry points, maintaining a clean and beautiful design language.


## [0.6.0-alpha.3] - 2026-03-05

### ✨ New Feature: AI Kill-Switch (#85)

- **Global toggle**: Added "Enable AI Features" switch in Settings → AI Meal Capture. Defaults to enabled; persisted via SharedPreferences.
- **Conditional UI**: When disabled, all AI entry points disappear without layout gaps:
  - Speed Dial: "AI Meal" action removed from the action list.
  - Nutrition Explorer: Gradient AI button next to barcode scanner hidden.
  - Settings: AI Settings navigation card conditionally shown only when AI is enabled.
- **Localization**: Added `aiEnableTitle` and `aiEnableSubtitle` strings in both English and German.

### 🎨 UI Improvements

- **AI Review Screen**: Replaced plain `AlertDialog` for quantity editing with the app's custom `showGlassBottomMenu` widget, ensuring visual consistency with the rest of the app (glass styling, keyboard-aware padding, visual style adaptation).

### 🐛 Bug Fixes

- **AI Review Quantity Editor**: Fixed `_dependents.isEmpty` assertion crash when closing the quantity editor. Root cause was disposing a `TextEditingController` while the glass bottom menu's exit animation was still playing.

## [0.6.0-alpha.2] - 2026-03-05

### 🎨 UI Redesign: Minimalist AI Interface (#84)

- **Removed gradient overload**: Stripped animated aura background, glassmorphic segmented toggle, gradient mic button, and glassmorphic action buttons from the AI Meal Capture screen.
- **AI gradient now accents entry points only**: Speed-dial icon, Settings entry icon, and Nutrition Explorer search bar icon use a `ShaderMask` rainbow gradient.
- **Analyze button**: Remains the sole gradient CTA with a smooth, deterministic shimmer animation during loading. Text and spinner are rendered above the gradient background.
- **Inline loading**: Replaced the modal `_AnalyzingOverlay` popup with an in-button animated gradient + spinner.
- **Empty states**: Photo, Voice, and Text tabs now show a centered placeholder with a faded icon and helper text when no input is present.
- **Text field fix**: Replaced broken Container+InputBorder.none with proper `OutlineInputBorder` for clean border radius on the text input tab.
- **New entry point**: Added AI icon with gradient accent next to the barcode scanner in the Nutrition Explorer search bar.

### 🧠 AI Logic Improvements

- **Locale-aware prompts**: `AiService` now accepts `languageCode` — the system prompt explicitly instructs the AI to return food names in the user's app language (e.g., "Apfel" not "Apple" when language is "de").
- **Item consolidation**: System prompt rule prevents duplicate entries — "4 eggs" returns one "Egg" entry with combined weight (240g).
- **No nutritional hallucination**: AI is instructed to return only food names and estimated gram weights. Calorie/macro values are looked up from the local database.
- **Simple base names**: AI returns short, generic food names (e.g., "Banane" not "Reife Banane") to maximize database match rates.

### 🔍 Improved Fuzzy Matching

- **Dart-side re-ranking**: `fuzzyMatchForAi` now fetches 20 candidates from SQL, then re-ranks in Dart with priority: exact match → starts-with → shortest partial match.
- **Source priority preserved**: Base foods still rank above user and Open Food Facts entries within each match tier.
- **Accuracy**: Searching for "Apfel" now correctly returns "Apfel" instead of "Erdapfel" or compound dishes.

### 📦 Code Reduction

- `ai_meal_capture_screen.dart`: ~1264 → ~870 lines (−31%), removed 3 animation controllers, 5 glassmorphic widgets, and the modal overlay.

## [0.6.0-alpha.1] - 2026-03-05

### 🚀 New Feature: AI Meal Capture (#81)

Capture meals faster using photos, voice, or text — powered by AI. Users provide their own API key (stored securely via `flutter_secure_storage`), and the app detects foods with estimated quantities, then lets users review and edit before saving.

### ✨ New Features

- **AI Meal Capture Screen**: New screen accessible from the diary FAB for logging meals via:
  - **Photo input**: Take a photo or pick from gallery (up to 4 images for multi-angle accuracy).
  - **Voice input**: Describe your meal by speaking — speech-to-text with on-device recognition.
  - **Text input**: Type a free-form meal description.
- **AI Meal Review Screen**: Review AI-detected foods before saving — edit quantities, swap items, add/remove entries.
- **AI Settings Screen**: Configure API provider (OpenAI GPT-4o or Google Gemini), enter API key, and test connectivity.
- **Multi-Provider AI Service**: Supports both OpenAI and Gemini APIs with dynamic payload formatting and structured JSON response parsing.
- **Complex Meal Handling**: AI system prompt forces decomposition of composite meals into individual ingredients (e.g., "Burger" → bun, patty, lettuce, cheese, sauce).

### 🎨 UI/UX: "Magical" AI Interface

- **Animated Aura Background**: 5 floating gradient orbs (pink, cyan, orange, purple, emerald) on independent coprime animation cycles (13s / 17s / 23s) — the combined pattern repeats only after ~85 minutes, creating truly organic, non-deterministic motion.
- **Glassmorphic Controls**: Custom frosted-glass segmented toggle for input modes with pastel rainbow gradient indicator.
- **Pastel Rainbow Buttons**: Analyze button and microphone button use a washed-out 5-color spectrum (pink → peach → gold → mint → cyan).
- **Enhanced Analyzing Overlay**: Rotating SweepGradient ring, hue-cycling sparkle icon, and animated gradient progress bar during AI processing.

### 🐛 Bug Fixes

- **Diary Bug (Critical)**: Fixed AI-detected foods not appearing in the diary. Root cause was mismatched meal type keys — the AI review screen used bare values (`'lunch'`) while the diary expected prefixed keys (`'mealtypeLunch'`).
- **Database Prioritization**: `fuzzyMatchForAi` now strictly orders results: base foods first (priority 0), then user foods (1), then Open Food Facts entries (2), followed by name length.

### 🔧 Permissions & Configuration

- **Android**: Added `RECORD_AUDIO` permission to `AndroidManifest.xml` for voice input.
- **iOS**: Fixed `NSMicrophoneUsageDescription` (previously stated "no mic access needed") and added missing `NSSpeechRecognitionUsageDescription`.
- **Speech Recognition**: Configured `speech_to_text` with dictation mode, 60s listen duration, 10s pause tolerance, partial results, locale auto-detection, and `cancelOnError: false`.

### 📦 Dependencies

- `speech_to_text: ^7.0.0`
- `flutter_secure_storage` (for API key storage)
- `image_picker` (for photo capture)

## [0.5.1] - 2026-03-04

### 🐛 Bug Fixes

- **RIR Field Validation (#83)**: Fixed the RIR (Reps in Reserve) field not correctly accepting and persisting values.
  - The field now defaults to empty/null instead of being hardcoded to 2.
  - Clearing the field correctly persists as null (previously reverted to the old value).
  - Target RIR values from routines now appear as placeholder hints in the Live Workout screen.
  - Non-numeric and negative input is now rejected via input validation.

## [0.5.0] - 2026-03-03

### 🚀 Major Release: The "Foundation Overhaul"

This release represents a complete modernization of Hypertrack's core architecture. The database has been rebuilt from the ground up, the onboarding experience has been rewritten, and the app has been fully rebranded. After extensive alpha testing, v0.5.0 is the new stable baseline.

### ✨ New Features

- **Complete Onboarding Wizard**: Replaced the old single-page tutorial with a multi-step setup wizard covering Name/Birthday, Height/Gender, Weight, Calories, Macros, and Water goals — all with precise text input fields.
- **Cardio Exercise Support**: The app now fully supports cardio exercises.
  - Dynamic input fields switch from "Kg / Reps" to "Distance (km) / Time (min)" based on exercise category.
  - Cardio routines default to 1 set and summarize as "Total Distance | Total Duration".
- **RIR (Reps In Reserve) Tracking**: Plan and log training intensity with RIR fields in routines, live workouts, and workout history.
- **Session Restoration**: Active workouts now survive app restarts — all logged sets, exercise order, and in-progress values are automatically recovered.
- **Profile 2.0**: Redesigned Profile Screen displaying Age, Gender, and Height alongside the profile picture, with inline editing.
- **Auto-Caffeine Logging**: Caffeinated drinks automatically create corresponding Supplement Log entries.
- **App Initializer Screen**: Database updates now show a clear progress screen during startup instead of running silently in the background.
- **Portrait Lock**: The app orientation is now locked to portrait for a consistent experience.

### 💾 Database & Architecture

- **Schema v6 Migration**: Major database overhaul adding `height`, `gender`, `birthday` to Profiles, `carbsPer100ml` to FluidLogs, and `rir`/`pauseSeconds` columns for workout tracking.
- **Unified goal storage**: User goals (Calories, Macros, Water) migrated from `SharedPreferences` to the SQLite database (`app_settings` table). Changing goals now updates the Dashboard instantly without restart.

### 🎨 UI/UX Improvements

- **Edit Routine Overhaul**: Completely refactored to match the Live Workout design with `WorkoutCard`, `SetTypeChip`, and consistent column layout.
- **AppBar Consistency**: Fixed back button visibility in light mode across Live Workout and Scanner screens.
- **Scanner Screen**: Cleaned up AppBar styling and simplified the camera layout.

### 🔧 Branding & Project

- **Full Rebranding**: Completed "Hypertrack" branding across all project names, package/bundle identifiers, class names, localization files, and documentation.
- **Relative Paths**: Converted all internal file paths to relative paths for better portability.
- **Documentation**: Added comprehensive project documentation (architecture, data models, UI components).

### 🐛 Bug Fixes

- Fixed workout exercise reordering not being persisted when saving.
- Fixed base food items being buried in search results — search now prioritizes local 'User' and 'Base' items.
- Fixed trailing spaces in search input causing zero results.
- Fixed incomplete (unchecked) "ghost sets" not being cleaned up when finishing a workout.
- Fixed crash in workout summary from incorrect type casting (`num` vs `int`).
- Fixed backup import crashes caused by `int` vs `string` ID conflicts.
- Fixed Supplements being duplicated upon backup import.
- Fixed sugary drinks showing 0g Carbs in fluid tracking.
- Fixed inconsistent UI styling between routine editing and live tracking.
- Improved pause timer logic to persist changes immediately.

## [0.5.0-alpha.5] - 2026-03-03

### Changed
- **Branding**: Completed the full rebranding to **Hypertrack**. Updated all project names, package/bundle identifiers, class names, and file references across the entire codebase.
- **Project Structure**: Converted all internal file paths to **relative paths** to ensure consistency and easier portability of the project.

## [0.5.0-alpha.3] - 2025-12-29

### Added
- **Cardio Support**: Introduced specialized tracking for cardio exercises.
  - **Dynamic Input Fields**: Based on exercise category ('Cardio'), the input fields in *Live Workout* and *Routine Editor* automatically switch from "Kg / Reps" to "**Distance (km) / Time (min)**".
  - **Routine Logic**: Cardio exercises in routines now default to 1 set (instead of 3) and initialize with empty fields.
  - **Summary & History**: Cardio results are now summarized as "Total Distance | Total Duration" instead of volume.
- **Detailed Database Initialization**:
  - Replaced background database updates with a dedicated **App Initializer Screen**.
  - This screen blocks the UI during startup, displaying a progress bar and detailed status ("Updating base foods: 1500/9000..."), preventing app lag and missing data issues.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Workout Reordering**: Fixed a critical bug where reordering exercises during a live workout was not persisted upon saving. The correct order is now saved to the database history.
- **Search Reliability**:
  - Fixed an issue where base food items (e.g., "Apple") were hidden in search results due to the sheer volume of Open Food Facts entries. Search now prioritizes local 'User' and 'Base' items.
  - Fixed a query bug where trailing spaces in search input (often added by keyboards) caused zero results. Input is now trimmed automatically.
- **Ghost Sets**: Finishing a workout now automatically cleans up incomplete (unchecked) sets from the database.
- **Type Safety**: Resolved a crash in the workout summary screen caused by incorrect type casting (`num` vs `int`) for duration calculations.

## [0.5.0-alpha.2] - 2025-12-28

### Added
- **RIR (Reps In Reserve) Support**:
  - Added `rir` column to `SetLogs` database table for tracking actual exertion.
  - Added `target_rir` column to `RoutineSetTemplates` database table for planning intensity.
  - Integrated RIR input fields into `LiveWorkoutScreen`.
  - Integrated RIR display and editing into `WorkoutLogDetailScreen`.
  - Integrated Target RIR configuration into `EditRoutineScreen`.
- **Session Restoration**: Added `tryRestoreSession()` to `WorkoutSessionManager` to recover ongoing workouts after app restarts.

### Changed
- **UI Overhaul (Edit Routine)**: Refactored `EditRoutineScreen` to align with the design of `LiveWorkoutScreen`.
  - Now uses `WorkoutCard` and `SetTypeChip` widgets.
  - Consistent column layout (Set, Kg, Reps, RIR).
- **Database**: Reset schema version to 1 to accommodate new RIR columns cleanly.
- **Pause Timer**: Improved logic to persist pause time changes immediately to the routine definition.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Fixed inconsistent UI styling between routine editing and live tracking.

## [0.5.0-alpha.1] - 2025-12-27

### 🚀 Major Features & Onboarding
- **New Onboarding Wizard:** Completely rewrote the initial setup process.
    - Replaced single-page tutorial with a multi-step wizard.
    - Added dedicated pages for: Name/Birthday, Height/Gender, Weight, Calories, Macros (Protein/Carbs/Fat), and Water.
    - Replaced sliders with precise text input fields.
- **Profile 2.0:** Redesigned the Profile Screen.
    - Now displays calculated Age, Gender, and Height alongside the profile picture.
    - Added logic to edit these stats directly.
- **Auto-Caffeine Logging:** Adding a drink with caffeine (e.g., Coffee/Energy Drink) now automatically creates a corresponding entry in the Supplement Logs.

### 💾 Database & Architecture (Drift v6)
- **Schema Migration (v1 -> v6):** Massive database update.
    - Added `height` (int) and `gender` (string) to `Profiles`.
    - Added `birthday` (datetime) to `Profiles`.
    - Added `carbsPer100ml` to `FluidLogs`.
    - Added `rir` (Reps in Reserve) and `pauseSeconds` columns (backend preparation).
- **Unified storage:**
    - Migrated user goals (Calories, Macros, Water) from `SharedPreferences` to the local SQLite database (`app_settings` table).
    - Enabled "Live Updates": Changing goals in Settings or Onboarding now updates the Dashboard immediately without a restart.

### 🐛 Fixes & Improvements
- **Backup System:**
    - Fixed critical bug where importing backups caused crashes due to `int` vs `string` ID conflicts.
    - Fixed issue where Supplements were duplicated upon import.
    - Implemented robust `clearAllUserData` to ensure a clean state before importing.
- **Fluid Tracking:** Fixed logic where sugary drinks showed 0g Carbs. Sugar content is now automatically treated as Carbs for the daily summary.
- **Stability:** Added `ensureStandardSupplements()` on app start to prevent crashes if "Caffeine" is missing from the database.
## [0.4.0] - 2025-12-03

### 🚀 Major Release: The "Glass & Fluid" Update

This release marks a significant milestone, introducing a complete UI overhaul, advanced meal tracking, and fluid intake management.

### ✨ Top Features
- **Meals (Mahlzeiten):** Create, edit, and log meals composed of multiple ingredients. Diary entries are now grouped by meal type (Breakfast, Lunch, Dinner, Snack).
- **Fluid & Caffeine Tracking:** dedicated tracking for water and other liquids. Automatic caffeine logging based on beverage intake.
- **Glass UI Design:** A completely new visual language featuring glassmorphism, unified bottom sheets, and an optional "Liquid Glass" visual style.
- **Onboarding:** A brand new onboarding experience for new users.
- **Hypertrack:** Official rebranding and new App Icon.

### 🎨 UI/UX
- **Unified Menu System:** Replaced system dialogs with consistent **Glass Bottom Menus** for a smoother experience.
- **Predictive Back:** Enabled support for Android 14+ predictive back gestures.
- **Haptic Feedback:** Enhanced tactile feedback across the app (Charts, Navigation, FAB).

### 🛠 Technical & Stability
- **Database Architecture:** Robust versioning for internal asset databases and improved backup/restore logic (including supplements).
- **Performance:** Optimized workout session handling and state management.
- **Localization:** Full German and English support across all new features.


## [0.4.0-beta.9] - 2025-11-25

### Bug Fixes
- **Datensicherung**: Ein Fehler wurde behoben, durch den Supplements und Supplement-Logs beim Wiederherstellen eines Backups ignoriert wurden. Diese werden nun korrekt in die Datenbank importiert (#70).
- **UI / Design**: Die AppBar im Mahlzeiten-Editor (`MealScreen`) wurde korrigiert. Sie verwendet nun die globale `GlobalAppBar` für ein einheitliches Design (Glassmorphismus), insbesondere im Light Mode (#68).

## [0.4.0-beta.8] - 2025-11-25
### UI/UX Improvements
- **Unified Design:** Replaced the native `AlertDialog`s with the custom **Glass Bottom Menu** for a consistent look and feel.
  - Applied to: Delete discard workout from main_screen.dart
### fix(l10n): localize remaining hardcoded UI strings for v0.6

- Added missing translation keys to `app_de.arb` and `app_en.arb` (Settings, Onboarding, Data Hub, Workout Bar).
- Replaced hardcoded strings in `SettingsScreen` (Visual Style selection).
- Localized search hints and empty states in `AddFoodScreen`.
- Localized app bar title in `DataManagementScreen`.
- Updated `OnboardingScreen` to use localization keys.

## [0.4.0-beta.7] - 2025-11-24

### Features
- **Android:** Enabled **Predictive Back Gesture** support for Android 14+ devices.

### UI/UX Improvements
- **Unified Design:** Replaced almost all native `AlertDialog`s and standard BottomSheets with the custom **Glass Bottom Menu** for a consistent look and feel.
  - Applied to: Delete confirmations, Supplement logging/editing, Meal ingredient picker, Routine pause/set type editing.
- **Edit Routine:** Aligned the pause timer display style with the Live Workout screen.
- **Food Details:** Fixed layout issue where content overlapped with the transparent app bar.

### Bug Fixes
- **Supplements:** The Supplement Hub and "Log Intake" dialog now correctly respect the date selected in the Diary (instead of always defaulting to "today").
- **Navigation:** Fixed back navigation stack when starting a workout from the Main Screen (back button now correctly returns to the dashboard).
- **Add Food:** Fixed a `RangeError` crash when scrolling to the bottom of the Meals tab.
## [0.4.0-beta.6] - 2025-11-22

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

*   **Critical: Custom Exercises**
    *   Fixed a database error that prevented users from saving new custom exercises (Issue #58).
    *   Resolved an issue where custom exercises appeared with empty titles when added to a routine.
*   **Critical: Data Restoration**
    *   Improved the backup import logic to strictly preserve original IDs for custom exercises. This prevents routines from breaking or losing exercises after restoring a backup.
*   **Profile Picture**
    *   Fixed a bug where deleting the profile picture did not visually update the app until a restart (Issue #31).
*   **Live Workout Stability**
    *   Fixed a layout crash that occurred when opening the "Change Set Type" menu.
    *   Fixed the "Finish Workout" dialog being inconsistent with the rest of the UI.
*   **Diary & Logging**
    *   Fixed the "Add Ingredient" flow in the Meal Editor which previously closed the menu without adding the item.
    *   Ensured that adding food, fluids, or supplements via the FAB always logs to the **currently selected date** in the diary, rather than defaulting to "now".

### Changed
*   **UI/UX Polish:**
    *   **Bottom Navigation:** Fixed the height of the Glass Bottom Navigation Bar to perfectly align with the Floating Action Button (Issue #61).
    *   **Scroll Padding:** Adjusted bottom spacing across all list screens (Routines, History, Explorer) so the last items are no longer hidden behind the navigation bar (Issue #60).
    *   **Liquid Glass Theme:** Reduced the background opacity and distortion thickness of the "Liquid" visual style to improve content readability.
*   **Modernized Menus:**
    *   Replaced remaining system dialogs (Edit Pause Time, Delete Confirmations, Set Type Picker) with the unified **Glass Bottom Menu**.
    *   Added visual symbols (N, W, F, D) to the Set Type selector for better recognition.

## [0.4.0-beta.5] - 2025-11-07

### Added
* **UI/UX:**
    * Added bottom spacer in the food explorer
    * added glass bottom menu in supplement screen
    * added glass bottom menu in data management screen
* **haptic:**
    * added haptic feedback on the glass navigationbar
### Changed
* haptic
    * increased haptic feedback when hovering on the weight graph
    * increased feedback on glassFAB
* **UI/UX**
    * changed the Appbar to blur
### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

* Fixed an issue where a routine did not loaded.
    

## [0.4.0-beta.4] - 2025-11-07

### Changed
* **UI/UX: Liquid glass**
    * adjusted border intensity
    * adjusted design of the glass bottom menu


## [0.4.0-beta.3] - 2025-11-06

### Added
*   **New Feature: Optional "Liquid Glass" UI Style**
    *   A new, optional visual style can be enabled in `Settings > Appearance` to switch to a rounded, fluid, and translucent UI.
    *   This feature is powered by the `liquid_glass_renderer` package, providing a high-fidelity, cross-platform frosted glass effect on both iOS and Android.
    *   The standard "Glass" UI remains the default.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

*   **Critical: Create Food Screen Unusable**
    *   Fixed a critical bug where the "Create Food" screen incorrectly displayed a numeric keyboard for text fields (name, brand), making it impossible to enter non-numeric characters. (Fixes #56)
*   **Critical: Create/Edit Routine Bugs**
    *   Resolved an issue where adding a new exercise to a routine did not visually update the list on the screen until the app was restarted. (Fixes #58)
    *   Fixed a bug where exercises added to a routine were missing their details (name, muscle groups) due to an inconsistent database query.
    *   Addressed a UI state bug where adding, removing, or changing set types in the routine editor would not update the UI in real-time.
*   **Database Stability:**
    *   Prevented crashes when saving custom food items by making the database insertion logic resilient to schema differences between the app model and the asset database.

### Changed
*   **UI/UX Consistency:**
    *   Replaced all standard `AlertDialog` pop-ups in the Supplement tracking feature with the modern `GlassBottomMenu` to provide a consistent and fluid user experience.
*   **Code Refactoring:**
    *   Simplified and stabilized the supplement logging flow by refactoring the UI logic into distinct, reusable widgets, resolving a crash when attempting to log a supplement.
    
## [0.4.0-beta.2] - 2025-10-22
### Added
* **App icon:** Now there is an App icon
### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

* **Backup:** tried to fix the backup
### Changed
* **App Name:** Changed the name from "Hypertrack" to "Hypertrack".


## [0.4.0-beta.1] - 2025-10-19

### Added

*   **New Feature: Onboarding Screen**
    *   Implemented the full, interactive Onboarding process for new users (or when the app is reset).
*   **New Feature: Initial Tab Navigation**
    *   The Main Screen now supports starting on a specific tab, improving navigation flexibility (e.g., deep linking).
*   **Fluid Log Editing**
    *   The "Edit Fluid Entry" dialog now includes fields for the **Name**, **Sugar per 100ml**, and **Caffeine per 100ml**, allowing for precise editing of non-water drinks.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.


*   **Critical Data Consistency: Fluid/Liquid Food Deletion**
    *   Fixed a critical bug where deleting a **liquid food entry** (e.g., a juice logged via the food tracker) did not correctly remove the linked Fluid Log and Caffeine Log entries, causing orphaned data (Fixes logic in `deleteFluidEntry`).
*   **Modal Display Issue (UX)**
    *   Fixed a bug where the Glass Bottom Menu (and other modals) sometimes failed to display correctly over the main navigation stack.
*   **Live Workout View**
    *   Corrected the padding in the Live Workout screen's exercise list, preventing the final exercise from being obscured by the bottom navigation/content spacer.

### Changed

*   **Major Branding Change: Renamed to "Hypertrack"**
    *   The application has been officially renamed from **"Hypertrack" to "Hypertrack"** across all screens, assets, bundle identifiers, and localization files.
*   **UX Improvement: Modernized Edit Dialogs**
    *   The "Edit Food Entry" and "Edit Fluid Entry" flows in the Diary screen were upgraded from the old `AlertDialog` to the new **Glass Bottom Menu (Bottom Sheet)**, improving mobile UX.
*   **UI Consistency**
    *   Visually updated the buttons and backgrounds in the Floating Action Button (FAB) menu to ensure consistency with the established "Glass FAB" design language.

## [0.4.0-alpha.12] - 2025-10-15

### Added

*   **New Feature: Today's Workout Summary on Diary Screen**
    *   Workout statistics (Duration, Volume, Set Count) for the current day are now displayed directly on the Diary/Nutrition screen (Issue #55).
*   **New Hub UI: Nutrition Hub Overhaul**
    *   The **Nutrition Hub** (`/nutrition-hub` - Issue #53) has been completely redesigned with an improved UI and UX, including new statistical cards and analysis gateways.
*   **Database Asset Versioning**
    *   Implemented a robust versioning system for all internal asset databases (`hypertrack_base_foods.db`, `hypertrack_prep_de.db`, `hypertrack_training.db`). This ensures that core app data is updated when the app version changes, preventing outdated database contents.
*   **Workout History Details**
    *   The Workout History screen now displays the **Total Volume** (in kg) and **Total Sets** for each logged workout, providing more context at a glance.
*   **Automatic Backup Check**
    *   The app now checks for and runs the automated daily backup process upon startup, increasing data security.
*   **New Routine Quick-Create Card**
    *   A new "Create Routine" card has been added to the Workout Hub for quick access.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.


*   **Critical: Database Name Display**
    *   Fixed a critical bug where localized food names (e.g., German, English) were not correctly retrieved from the product database, leading to the display of wrong or empty names in some parts of the app (Issue #56).
*   **Critical: Backup and Restore Stability**
    *   Fixed multiple critical issues related to the full backup/restore process (Issue #52), ensuring that **Supplements**, **Supplement Logs**, and detailed **Workout Set Logs** are correctly serialized, backed up, and restored.
*   **Workout History Filtering**
    *   Fixed a bug in the workout database helper that caused uncompleted/draft workout logs to be included in the history; only workouts with the status `completed` are now shown.
*   **Exercise Name Localization**
    *   Corrected the logic for displaying exercise names in the Exercise Catalog and Detail screens to correctly prioritize localized names (`name_de`, `name_en`).
*   **Profile Picture Deletion**
    *   Fixed an issue where deleting the profile picture did not work as intended (Issue #31).
*   **Fluid Log Processing**
    *   The calculation for Carbs and Sugar in fluid entries is now correctly scaled by the logged quantity.

### Changed

*   **Reworked Add Menu (FAB)**
    *   The Floating Action Button (FAB) menu on the main screen has been refined for better usability and visual feedback (Issue #50).
*   **Improved Water Section UI/UX**
    *   The Water section in the Diary screen has received general UI/UX enhancements (Issue #54).
*   **Routineless Workout Restoration**
    *   Restoring a workout that was not based on a routine now correctly determines the order of exercises based on the original log order.
*   **Enhanced Swipe-to-Delete Confirmation**
    *   Added explicit confirmation dialogues for the swipe-to-delete actions on Routines, Meals, and Nutrition/Fluid Logs to prevent accidental data loss.
*   **Improved Search Queries**
    *   Product search now searches across `name`, `name_de`, and `name_en` fields, significantly improving discoverability.
*   **UI/UX Refinements**
    *   Numerous minor style adjustments across the app (typography, button padding, list item shadows) for a cleaner, more consistent look.
## Release Notes – 0.4.0-alpha.11+4011

### Added
*   New wger exercise database integrated, providing even more details and laying the groundwork for upcoming advanced analytics features.
*   First set of curated base foods added to the food catalog. More will follow soon.

### Changed
*   Adjusted item labels in the bottom navigation bar to max. 1 line for a cleaner UI.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

*   Resolved critical issues with database migration and access, fixing crashes when viewing workout history or adding exercises to routines.
*   Fixed localization issue in the base foods catalog, ensuring food names are displayed in the correct language.

## Release Notes - 0.4.0-alpha.10+4010

### ✨ New Features & Major Improvements

*   **Enhanced Fluid Tracking:**
    *   Any liquid can now be logged with a name, quantity, sugar, and caffeine content via the new "+" menu.
    *   When logging food items, you can now specify that it is a liquid ("Add to water intake"). The quantity is then correctly added to the daily water goal.
*   **Automatic Caffeine Tracking:**
    *   Daily caffeine intake is now automatically calculated and displayed in the nutrition summary.
    *   Caffeine can be specified in "mg per 100ml" for both custom liquids and food items marked as liquid.
    *   A new "Caffeine" entry has been added to the trackable supplements.
*   **Improved Nutrition Analysis:**
    *   Calculations in the nutrition analysis (`nutrition_screen.dart`) and on the dashboard (`diary_screen.dart`) now correctly include calories, carbs, and sugar from all logged fluids.
*   **Expanded "Add" Menu:**
    *   The central speed-dial menu has been expanded with "Add Liquid" and "Log Supplement" options for faster access.

### 🐛 Bugfixes & Improvements

*   **Data Integrity on Deletion:** Fixed a critical bug where deleting fluid or food entries did not remove associated supplement logs (e.g., for caffeine). The deletion logic has been revised to ensure data consistency.
*   **Database Structure:** The database has been updated to version 19 to enable linking between food, fluid, and supplement entries.
*   **UI Improvements in Diary:** Fluids are now displayed in their own section (`Water & Drinks`) on the diary page for better clarity.
*   **Data Backup Fixes:** The backup model (`HypertrackBackup`) has been updated to correctly handle the new `FluidEntry` data.

## Release Notes - 0.4.0-alpha.9+4009

### ✨ New
- Glass-styled bottom sheet menu (blur removed; smooth dimmed backdrop).
- “Add fluid” flow merged into the new bottom sheet (amount + date + time).
- “Start workout” bottom sheet with:
  - **Start empty workout** action on top.
  - List of routines below, each with a **Start** button; tap on the tile opens **Edit Routine**.
- “Track supplement intake” fully inline in the bottom sheet (select supplement → dose & time).
- **Nutrition** tab added to the bottom bar (temporary hub / empty state).
- **Profile** moved from bottom bar to the **right side of the AppBar** as a large avatar (uses user photo when set).

### 🎨 UX / Polish
- Bottom sheet now respects the on-screen keyboard (slides up smoothly).
- Consistent glass styling (rounded corners, straight hard edge around curve).
- Restored instant tab switching on bottom bar tap (no intermediate swipe animation).

### 🐞 Fixes
- Meals: GlassFAB redirection corrected to open meal screen in edit mode.
- Category localization fixed (translated labels show correctly).


## [0.4.0-alpha.8] - 2025-10-05
### Added
- Haptic feedback when selecting chart points and pressing the Glass FAB.
- Meal Screen redesign: consistent typography, SummaryCards for ingredients, contextual FAB.
- Meals list swipe actions consistent with Nutrition screen.

### Changed
- Context-aware FAB in Meals tab (“Create Meal”), removed redundant header button.
- Meal editor visual consistency: non-filled top-right Save button.
- Ingredient layout updated (SummaryCards, editable amounts on right).
- TabBar text no longer changes size on selection.
- Diary meal headers show macro line (kcal · P · C · F) below title.

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Save button tap area and modal layering in Meal Editor.
- Scanner and Add Food refresh logic for recents/favorites.
- Defensive database handling during barcode scan.

### Notes
- No database migration required.
- Final alpha polish before beta.
EOF

## [0.4.0-alpha.7] - 2025-10-03
### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Backup import failed with *“no such column is_liquid”* → caused Diary/Stats to hang
- Old backups without password could not be restored (fallback logic improved)
- App stuck in loading when DB initialization or restore failed

### Improved
- Import logic now automatically adapts to schema changes (ignores missing columns)

### Internal
- Defensive DB handling and better logging during import

## [0.4.0-alpha.6] - 2025-10-03
### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- **Database hotfix**: ensured that all core tables (`food_entries`, `water_entries`, `meals`, `supplement_logs`, etc.) and indices are always created on upgrade, preventing missing-table errors on fresh installs or after updates.
- Fixed `DiaryScreen` and `Statistics` not loading due to missing DB structures.
- Backup/restore flow more robust, no crashes when tables were absent.

### Notes
This is a hotfix release following alpha.4, focused only on database migration stability.  

## [0.4.0-alpha.5+4005] - 2025-10-03

### 🚀 New Features
- **Meals (Beta):**
  - Create and edit meals composed of multiple food items.
  - Add ingredients via search or base food catalog.
  - Adjust ingredient amounts before saving when logging a meal.
  - Select meal type (Breakfast, Lunch, Dinner, Snack) — entries are correctly assigned to the chosen category in the diary.
- **Combined Catalog & Search Tab:**
  - Replaced separate Search and Base Foods tabs with a unified Catalog & Search tab.
  - Expandable base categories visible when no search query is entered.
  - Search results prioritized: base foods first, then OFF/User entries.
  - Barcode scanner button included directly in the search field.
- **Caffeine Auto-Logging:**
  - Automatically log caffeine intake from drinks (liquid products) with a `caffeine_mg_per_100ml` value when added to the diary.
  - Linked directly to the built-in caffeine supplement (non-removable, unit locked to mg).
- **Enhanced Empty States:**
  - Meals tab shows “No meals yet” illustration and action button to create a meal.
  - Improved UI in Favorites & Recents with icons and contextual instructions.

### 🛠 Improvements
- **Base Food Database:**
  - Now ships empty by default (no prefilled, incorrect entries).
  - Completely removed the category “Mass Gainer Bulk”.
- **Database Handling:**
  - Safer `getProductByBarcode` implementation in `ProductDatabaseHelper`: recovers from `database_closed` by reopening databases.
  - Ensures correct handling of base vs. OFF product sources.
- **Diary Screen:**
  - Food entries from meals are now grouped under the correct meal type (Breakfast, Lunch, Dinner, Snack).
  - Macro calculations (calories, protein, carbs, fat) displayed per meal.
- **UI / UX Enhancements:**
  - Consistent use of `SummaryCard` across food lists and meal cards.
  - Added “Add Food” button inside each diary meal card header.
  - Improved barcode scanner integration for a smoother workflow.
  - Caffeine unit locked (mg) and explained via helper text.

### 🐛 Fixes
- Fixed missing meal type in logged meal entries (causing them not to show in Diary, though they appeared in Nutrition overview).
- Fixed ingredient list in meal editor showing barcodes instead of product names.
- Fixed crash when selecting meal type in the bottom sheet (`setSheetState` vs `StatefulBuilder.setState`).
- Fixed null-safety errors in Add Food & Meal logging bottom sheets.
- Fixed duplicated `Expanded`/`TabBarView` layout issues (RenderFlex overflow with unbounded constraints).
- Fixed initialization bug: after Hot Reload, some database migrations were not applied — required Hot Restart (documented).
- Fixed issue with “confirm” translation key missing — replaced with `l10n.save`.

### 🔎 Known Limitations
- **Meals are still in beta:**
  - No drag-and-drop reordering of ingredients yet.
  - No duplication/cloning of meals.
  - No optional photos or icons for meals.
  - Caffeine supplement logs are not yet directly linked to the specific FoodEntry ID (planned).
  - Base Food DB is currently empty — contribution workflow (community-curated entries, moderation, import) planned for future versions.

## 0.4.0-alpha.4 — 2025-10-02
### Added
- DEV-only editor in Food Detail Screen: allows editing base food entries directly on-device
- Export function for `hypertrack_base_foods.db` via share (e.g., AirDrop, Mail, Drive)
- Search & category accordion in "Grundnahrungsmittel" tab with emoji headers

### Changed
- AppBar styling unified: Food Detail, Supplement Hub, and Settings now share large bold title style
- Minor OLED/dark mode polish for nutrient cards

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Database auto-reopen after hot reload (no more `database_closed` errors)
- Edits in base food database now persist correctly across re-entry

## 0.4.0-alpha.3 — 2025-10-01
### Added
- New bottom bar layout with detached GlassFab
- Running workout bar redesign (filled “Continue”, outlined red “Discard”)

### Changed
- Localized screen names (Diary/Workout/Stats/Profile; Heute/Gestern/Vorgestern)
- Weight chart: inline date next to big weight, hover updates value/date, no tooltip popup
- Routine & Measurements screens: swipe actions match Nutrition design

### Fixed
- **Global Weight Formatting Fix:** Implemented a new `formatDisplayWeight` method in `UnitService` to handle rendering of target, logged, and PR weights properly when converted. Replaced ad-hoc `.toStringAsFixed` logic across `live_workout_screen`, `workout_log_detail_screen`, and `edit_routine_screen` to consistently remove trailing decimals while preserving values like .5.
- **Bugfix (Edit Routine Bug):** Fixed an issue where converted weights (`lbs`) in the Edit Routine view and Live Workout view would render with 3 decimal places (e.g. `22.046`) by routing them through the new global formatting method.

- Back button in Add Food
- “Done” moved to AppBar in add exercise flow
- App version alignment (minSdk 21, targetSdk 36, versionName/Code via local.properties)

### Known
- Play Store signing not configured (debug signing only for GitHub APK)

## [0.2.0] - 2025-09-24

This release focuses on massive stability improvements, UI consistency, and critical bug fixes. The user experience during workouts is now significantly more robust and visually polished.

### ✨ Added
- **Improved "Last Time" Performance Display:** The "Last Time" metric in the live workout screen now accurately shows the weight and reps for each individual set from the previous workout, providing better context for progressive overload.

### 🐛 Fixed
- **CRITICAL: Live Workout Persistence:** An active workout session now correctly persists even if the app is closed by the user or the operating system. All logged sets, exercise order, custom rest times, and in-progress values are restored upon reopening the app, preventing data loss. (Fixes #30)
- **Live Workout UI Bugs:**
    - Correctly highlights completed sets with a subtle green background without obscuring the text fields. (Fixes #29)
    - The alternating background colors for set rows now adapt properly to both light and dark modes. (Fixes #25)
- **State Management Stability:** Resolved `initState` errors by moving context-dependent logic to `didChangeDependencies`, improving app stability.
- **Localization (l10n) Fixes:**
    - The "Delete Profile Picture" button is now fully localized. (Fixes #27)
    - The "Detailed Nutrients" headline in the Goals Screen is now localized. (Fixes #26)

### ♻️ Changed
- **UI Refactoring (`EditRoutineScreen`):** The screen for editing routines has been completely redesigned to match the modern, seamless list-style of the live workout screen, ensuring a consistent user experience across all workout-related views. (Fixes #28)
- **Centralized State Logic:** All logic for managing a live workout session is now consolidated within the `WorkoutSessionManager`. The `LiveWorkoutScreen` is now primarily responsible for displaying the state, leading to cleaner and more maintainable code.
- **Optimized App Startup:** The workout recovery logic was moved from `main.dart` into the `WorkoutSessionManager` to streamline the app's initialization process.
## [0.1.0] - 2025-09-23

This is the first feature-complete, stable pre-release of Hypertrack. It establishes a robust, offline-first foundation for tracking nutrition, workouts, and body measurements.

### ✨ Added
- **Consistency Calendar:** A visual calendar on the Statistics tab now displays days with logged workouts and nutrition entries to motivate users (#22).
- **Macronutrient Calculator:** The Goals screen now features interactive sliders to set macro targets as percentages, which automatically calculate the corresponding gram values (#18).
- **Full Localization:** The entire user interface is now available in both English and German.
- **Encrypted Backups:** Added functionality to create password-protected, encrypted backups for enhanced security.
- **Barcode Scanner:** Integrated a barcode scanner for quick logging of food items.

### 🐛 Fixed
- The app version displayed in the profile screen now correctly reflects the version from `pubspec.yaml` (#24).
- The weight history chart on the Home screen now correctly updates when the date range filter is changed.
- The Backup & Restore system now correctly processes workout routines, preventing data loss.

### ♻️ Changed
- **Database-Powered Exercise Mappings:** Exercise name mappings for imports are now stored robustly in the database instead of SharedPreferences, enabling automatic application during future imports (#23).
- **Unified UI/UX:** The application's design has been polished for a consistent user experience, especially regarding AppBars, dialogs, and buttons.
- **Improved Exercise Creation:** The "Create Exercise" screen now features an intelligent autocomplete field for categories and a chip-based selection for muscle groups, improving data quality and usability.
- **View Mode**: In view mode, the routine title is now only displayed in the app bar and the redundant large title below it, along with its divider, has been removed.
- **View Mode Scroll Fix**: Fixed the initial scroll position of the exercise list in view mode so it is no longer obscured by the app bar.
- **Edit Routine Screen**: Fixed the scroll behaviour in view mode to ensure lists scroll behind the translucent AppBar, and removed a duplicate rendering of the floating action button.
