# Home Screen Widgets (iOS & Cross-Platform Architecture)

Train Libre brings glanceable diary, activity, recovery, and workout metrics directly to the user's Home Screen without compromising offline autonomy or data privacy.

The widget suite is driven by a shared, pure Dart snapshot architecture (`lib/features/home_widgets/`) that synchronizes state over the `trainlibre.widgets/home_screen` MethodChannel to native platforms:
- **iOS 18+**: Native SwiftUI widgets via WidgetKit in `ios/TrainLibreLiveActivity/`, sharing data through an App Group container (`group.com.rfivesix.trainlibre`).
- **Android 12+**: Native widgets via Jetpack Glance and custom canvas renderers in `android/app/src/main/kotlin/com/rfivesix/trainlibre/widgets/`, plus an Android Quick Settings Tile (`QuickActionTileService`).

> Like everything else in Train Libre, widgets run entirely on the device. Widgets read a serialized JSON snapshot written directly by the app into local platform storage — no external server, no network connection, and no background fetch.

---

## The Widget Family

The snapshot provides data for six distinct widget surfaces across both platforms:

1. **Heute im Blick / Today Glance** (`.systemMedium` on iOS; 4x2 on Android):
   The diary's six-tile nutrition grid rendered 1:1 with `NutritionSummaryWidget` (Calories, Protein, Water, Carbohydrates, Extra Nutrient [fibre/sugar/salt], and Fat) including progress fills and targets. Tapping opens the diary.
2. **Schnellzugriff / Quick Actions** (`.systemSmall` / `.systemMedium` on iOS; 2x2 / 4x2 on Android):
   Configurable action shortcuts (AI meal capture, barcode scanner, start workout, log measurement, log supplement, add fluid). Tapping directly deep-links to that specific flow. On Android, also available as a Quick Settings Tile.
3. **Schritte / Steps** (`.systemSmall` / `.systemMedium` on iOS; 2x2 / 4x2 on Android):
   Current day's step count against the active daily goal, paired with an hourly/daily bar chart.
4. **Messwerte / Measurements** (`.systemSmall` / `.systemMedium` on iOS; 2x2 / 4x2 on Android):
   User-selected body metric (weight, body fat, waist circumference, etc.) showing the latest reading, change over time, and a historical sparkline chart. Configured via native configuration intents/activities.
5. **Muskel-Erholung / Muscle Recovery** (`.systemSmall` / `.systemMedium` on iOS; 2x2 / 4x2 on Android):
   Heuristic muscle readiness breakdown, showing percentages and counts for *Recovering*, *Ready*, and *Fresh* muscle groups. Tapping navigates to the Recovery Tracker.
6. **Letztes Workout / Last Workout** (`.systemMedium` / `.systemLarge` on iOS; 4x2 / 4x3 on Android):
   Summary of the most recently completed workout session (duration, tonnage, total reps, sets) alongside a rendered muscle heatmap image (`last_workout_heatmap_<id>.png`).

---

## Architecture & Data Flow

```
Flutter (Source of Truth)                       Native Platform Storage                  Native Widget Renderers
─────────────────────────                       ───────────────────────                  ───────────────────────
[Repositories: Diary, Workout, Profile]
         │
         ▼
HomeWidgetSyncService                           iOS: App Group UserDefaults              iOS: WidgetKit Extension
  (Listens to reactive repository changes,        (suiteName: group.com.rfivesix...)       (TimelineProvider -> SwiftUI)
   builds HomeWidgetSnapshot JSON)                        │
         │                                                │
         ├──MethodChannel (trainlibre.widgets/home_screen)┤
         │                                                │
         ▼                                                ▼
HomeWidgetChannel                               Android: SharedPreferences               Android: Glance & AppWidget
  .writeSnapshot(json)                            (HomeWidgetStore)                        (HomeWidgetRefresher -> Renderers)
  .writeSharedFile(heatmapBytes)
```

### Snapshot Payload (`HomeWidgetSnapshot` Schema v2)
The snapshot (`HomeWidgetSnapshot`) holds **aggregate totals, targets, and presentation metrics only**:
- No food names, exact timestamps, or granular user log entries ever reach the shared container.
- `schemaVersion: 2` supports nullable modular sections (`recovery`, `steps`, `measurements`, `lastWorkout`, `tiles`). Missing sections gracefully degrade to an empty state rather than causing decoding failures.
- `rolloverHour`: Sent explicitly in the snapshot (default 3 AM) so native timeline providers know when to zero out the nutrition grid without duplicating Dart rollover rules.

### Push-Based Updates & Timeline Budgeting
Nutrition and workout data cannot change while the app is closed. A snapshot written on each mutation and on app backgrounding is exact. Polling data that provably did not change would exhaust OS widget reload budgets (WidgetKit budgets ~40–70 reloads per day).

The synchronization uses **push**:
- The app updates the snapshot and requests a timeline reload whenever relevant data changes.
- Two timeline entries are scheduled on iOS: the current moment, and the next day rollover (`snapshot.zeroed(forDayKey:)`), ensuring the widget rolls over cleanly even if the app remains closed past 03:00.

---

## Where the Code Lives

### Cross-Platform Dart Layer (`lib/features/home_widgets/`)
*   `domain/models/home_widget_snapshot.dart`: Schema version 2 snapshot model, tiles, recovery, steps, measurements, and workout structures with JSON serialization.
*   `domain/build_home_widget_snapshot.dart`: Pure builder function transforming domain repository entities into the platform snapshot.
*   `data/home_widget_channel.dart`: Wraps the `trainlibre.widgets/home_screen` MethodChannel (writeSnapshot, writeSharedFile, sharedFileExists, clearSnapshot).
*   `application/home_widget_sync_service.dart`: Listens to diary, profile, supplement, and workout repositories, building and pushing snapshots.
*   `application/workout_heatmap_publisher.dart`: Renders muscle fatigue heatmaps into PNG byte buffers and publishes them to shared storage.
*   `home_widget_deep_link.dart`: Unified deep-link parser routing incoming `trainlibre://widget/<action>` URLs.

### iOS Implementation (`ios/`)
| File | Role |
| --- | --- |
| `ios/LiveActivity/HomeWidgetShared.swift` | Snapshot decoding, day maths, Dart-compatible number formatting |
| `ios/LiveActivity/HomeWidgetBridge.swift` | `trainlibre.widgets/home_screen` MethodChannel implementation |
| `ios/TrainLibreLiveActivity/TodayGlanceWidget.swift` | Nutrition grid widget, configuration intent, timeline provider |
| `ios/TrainLibreLiveActivity/TodayGlanceViews.swift` | SwiftUI grid layout and progress bar rendering |
| `ios/TrainLibreLiveActivity/QuickActionsWidget.swift` | Quick action launcher widget, configuration intent, tiles |
| `ios/TrainLibreLiveActivity/StepsWidget.swift` | Steps counter and bar chart widget |
| `ios/TrainLibreLiveActivity/MeasurementsWidget.swift` | Metric tracking and trend line widget |
| `ios/TrainLibreLiveActivity/RecoveryWidget.swift` | Muscle readiness pills and breakdown widget |
| `ios/TrainLibreLiveActivity/LastWorkoutWidget.swift` | Workout recap and muscle heatmap viewer |
| `ios/TrainLibreLiveActivity/Localizable.xcstrings` | Native localization for widget gallery and configuration UI |

### Android Implementation (`android/app/.../widgets/`)
| File | Role |
| --- | --- |
| `HomeWidgetBridge.kt` | MethodChannel handling snapshot persistence and file writing |
| `snapshot/HomeWidgetStore.kt` | Stores and parses `HomeWidgetSnapshot` from SharedPreferences |
| `HomeWidgetRefresher.kt` | Broadcasts update intents to all active AppWidgets and tile services |
| `TodayGlanceWidget.kt` | Nutrition summary widget provider |
| `QuickActionsWidget.kt` | Quick action shortcut widget provider |
| `StepsWidget.kt` | Step counter widget provider with bar chart |
| `MeasurementsWidget.kt` | Measurement widget provider with trend chart |
| `RecoveryWidget.kt` | Muscle recovery widget provider |
| `LastWorkoutWidget.kt` | Last workout widget provider with heatmap display |
| `charts/*` | Custom Canvas chart renderers (`MeasurementChartRenderer`, `StepsBarChartRenderer`, etc.) |
| `config/*Activity.kt` | Interactive configuration activities for widget instances |
| `tiles/QuickActionTileService.kt` | Quick Settings tile for immediate action triggering |
| `WidgetDeepLinks.kt` | Native Android deep-link generator |

---

## iOS Implementation Details & Lessons Learned

1.  **`Button(intent:)` does not work in these widgets**:
    Tiles built with `Button(intent: OpenURLIntent(...))` render and accept taps, but `perform()` is not invoked reliably. Instead, SwiftUI `Link` is handled directly by SpringBoard and works reliably across `.systemSmall` and `.systemMedium` on iOS 18+.
2.  **`GeometryReader` layout root constraints**:
    `GeometryReader` has no intrinsic size. Stacking them in a `VStack` divides height unpredictably. Layouts use `ZStack` as the root, placing `GeometryReader` strictly inside fill masks where layout sizes are already settled.
3.  **`String(format: "%.1f")` vs Dart `toStringAsFixed(1)`**:
    C string formatting breaks exact ties to even numbers, whereas Dart breaks ties away from zero (e.g., 40.25 rounds to 40.2 in C, but 40.3 in Dart). `HomeWidgetTile.dartFixed(_:_:)` in `HomeWidgetShared.swift` parses the printed expansion of the double to match Dart's output exactly, verified by unit tests.
4.  **Configuration Intent Restoration**:
    Each quick action slot on iOS uses a dedicated `AppEnum` (`QuickActionSlot1` through `QuickActionSlot4`). This prevents iOS 18 from resetting all parameters when sharing an identical enum type.

---

## Automated Verification & Tests

- `test/features/home_widgets/build_home_widget_snapshot_test.dart`: Validates snapshot day rollover across 03:00, metric/imperial conversions, color hex mapping, and empty-state fallbacks.
- `test/features/home_widgets/home_widget_deep_link_test.dart`: Validates routing for every action key, unknown keys, malformed URLs, and Live Activity URL isolation.
- `test/features/home_widgets/workout_heatmap_publisher_test.dart`: Tests heatmap rendering and App Group image file writing.
- `ios/RunnerTests/HomeWidgetSharedTests.swift`: Tests Swift snapshot decoding, next-rollover calculation, progress clamping, and Dart-identical number formatting tables.

---

## Design Considerations & Future Refinements

- **Tinted & Clear Home Screen Modes (iOS 18+)**: High-saturation category colors may desaturate under tinted Home Screen settings. Reviewing `widgetAccentedRenderingMode` behavior on physical hardware remains an aesthetic consideration.
- **Direct Interactive Actions**: Quick action shortcuts open the app immediately. Future inline completions (such as logging a fixed water amount without opening the app) can follow the Live Activity command-queue pattern (`pendingCommandsKey`).
