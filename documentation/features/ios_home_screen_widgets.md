# iOS Home Screen Widgets

Two widgets put the diary on the Home Screen:

- **Heute im Blick** (`.systemMedium`) — the diary's six-tile nutrition grid, rendered 1:1.
- **Schnellzugriff** (`.systemSmall` / `.systemMedium`) — two or four freely chosen actions.

Available on **iOS 18 and newer**. The app and the Workout Live Activity keep their iOS 16.2
floor; the widgets are gated inside the widget bundle rather than by raising the extension's
deployment target, so nothing is taken away from 16/17 users.

> Like everything else in Train Libre, this runs entirely on the device. The widgets read a
> snapshot the app writes into the shared App Group container — no server, no network, no
> background fetch.

---

## What they show

```
┌─────────────────────┬─────────────────────┐
│ Kalorien            │ Protein             │
│ 1234.0 / 2000 kcal  │ 98.0 / 150 g        │
├─────────────────────┼─────────────────────┤
│ Wasser              │ Kohlenhydrate       │
│ 1500.0 / 2500 ml    │ 180.0 / 200 g       │
├─────────────────────┼─────────────────────┤
│ Ballaststoffe       │ Fett                │
│ 12.0 / 30 g         │ 55.0 / 60 g         │
└─────────────────────┴─────────────────────┘
```

Same six tiles as `NutritionSummaryWidget` with `isExpandedView: false`, in the same column
order, with the same colours, corner radii, spacing and fill behaviour. The third left-hand tile
follows the app's `overviewExtraNutrient` setting (fibre, sugar or salt) rather than offering a
separate widget setting, so the two can never disagree.

When the day has targets but nothing logged yet, the grid stays — the targets are the useful part —
and gains one quiet line beneath it. If the app has never written a snapshot at all (a widget added
before the app was first opened), the line instead says so rather than leaving six dashes unexplained.

Tapping the widget opens the diary.

**Schnellzugriff** shows Shortcuts-style tiles for: KI-Mahlzeit, Barcode scannen, Workout starten,
Messwert hinzufügen, Einnahme protokollieren, Flüssigkeit hinzufügen. Each slot is chosen by the
user in the widget's configuration. Tapping a tile opens the app directly in that flow.

---

## How the data gets there

```
Flutter (source of truth)                 App Group                    Extension
─────────────────────────                 ─────────                    ─────────
CalculateDailyNutritionUseCase
        │
        ▼
HomeWidgetSyncService  ──MethodChannel──►  UserDefaults(suiteName:)  ──►  TimelineProvider
  (builds snapshot JSON)                   key: home_widget_snapshot       (decodes, renders)
        │
        └──────────────────────────────►  WidgetCenter.reloadTimelines()
```

The snapshot holds **aggregate totals and targets only** — no food names, no timestamps, no
entry-level rows ever reach the shared container.

### Why there is no periodic refresh

Nutrition data cannot change while the app is closed. HealthKit nutrition and hydration are
**write-only** here ([`AppDelegate.swift`](../../ios/Runner/AppDelegate.swift) writes
`dietaryWater`; only steps, sleep and heart rate are ever read back), so every calorie and
millilitre enters through app UI. A snapshot written on each mutation is therefore not an
approximation — it is exact.

WidgetKit also budgets roughly 40–70 timeline reloads per widget per day. Spending them polling
data that provably did not change would make the widget *more* likely to be stale when it matters.

So the widget uses **push** (the app reloads timelines after every write and on backgrounding)
plus exactly **two timeline entries**: now, and the next day rollover.

### The day rollover

The diary shows the previous day until 03:00 (`resolveDiaryInitialDate`). That rule lives in Dart
and travels in the snapshot as `rolloverHour`, so the widget never keeps its own copy of it.

The widget's second timeline entry fires at the next rollover and renders
`snapshot.zeroed(forDayKey:)` — the previous day's totals cleared, its targets kept. Nothing can
have been logged for the new day without the app running, so zero is the correct answer rather
than a guess, and the widget rolls over correctly with the app closed.

Each widget instance can be configured to follow the app (03:00) or the calendar day (00:00).

---

## Where the code lives

| File | Target | Role |
| --- | --- | --- |
| `ios/LiveActivity/HomeWidgetShared.swift` | Runner + extension | Snapshot types, day maths, Dart-compatible number formatting |
| `ios/LiveActivity/HomeWidgetBridge.swift` | Runner | `trainlibre.widgets/home_screen` MethodChannel |
| `ios/TrainLibreLiveActivity/TodayGlanceWidget.swift` | extension | Widget, configuration intent, timeline |
| `ios/TrainLibreLiveActivity/TodayGlanceViews.swift` | extension | The grid and the progress bar |
| `ios/TrainLibreLiveActivity/QuickActionsWidget.swift` | extension | Widget, configuration intent, tiles |
| `ios/TrainLibreLiveActivity/QuickActionEntity.swift` | extension | Selectable actions, AI gating |
| `ios/TrainLibreLiveActivity/Localizable.xcstrings` | extension | Native strings (de/en/fr/it/ja) |
| `lib/features/home_widgets/` | — | Snapshot model, pure builder, channel, sync service |

`ios/TrainLibreLiveActivity/` is a **synchronized** Xcode group: files added there join both
targets automatically, so widget-only files are listed as Runner membership exceptions in
`project.pbxproj`.

### Localization is split, deliberately

Widget **content** (tile labels, units) comes from the snapshot, so it reuses the app's `.arb`
files. Widget **chrome** (gallery name, configuration sheet, action names in the picker) is
rendered by iOS *outside our process*, before any snapshot exists, so it must be native — hence
the duplicated strings in `Localizable.xcstrings`. Both files carry a comment pointing at the
other.

---

## Three things that were not obvious

**1. `Button(intent:)` does not work in these widgets.** Tiles built with
`Button(intent: OpenURLIntent(...))` — and with a custom `AppIntent` carrying
`openAppWhenRun` — render and accept the tap, but `perform()` never runs and the app never opens.
`Link` is handled by SpringBoard itself and works. Contrary to the long-standing "small widgets
only support `widgetURL`" rule, `Link` works in `systemSmall` too on the iOS 18 floor; both tile
counts were verified on device.

**2. `GeometryReader` must not be a bar's layout root.** It has no intrinsic size, so three of
them stacked in a `VStack` divide the height unevenly — the third bar lost its card entirely while
its text still rendered. The `ZStack` is the layout root now, and `GeometryReader` appears only
inside the fill's mask, where it reads a size the layout has already resolved.

**3. `String(format: "%.1f")` is not `toStringAsFixed(1)`.** Both round on the double's true
value, but C breaks an exact tie to even where Dart breaks it away from zero: 40.25 g of sugar
renders as `40.2` in the widget and `40.3` in the diary. The tie cannot be detected by scaling
either — `0.15 * 10` lands on exactly `1.5` even though the double sits below the tie, which would
round 0.15 *up* and disagree with the app in the other direction.
`HomeWidgetTile.dartFixed(_:_:)` decides on the printed expansion of the double instead and is
pinned against Dart's real output in `HomeWidgetSharedTests`.

---

## Tests

- `test/features/home_widgets/build_home_widget_snapshot_test.dart` — day resolution across the
  03:00 boundary and month/year ends, the extra-nutrient slot, metric vs imperial conversion,
  colour hex, zero-target and empty-day cases, JSON round trip.
- `test/features/home_widgets/home_widget_deep_link_test.dart` — every action key, unknown keys,
  malformed URLs, and that the workout Live Activity link is left alone.
- `ios/RunnerTests/HomeWidgetSharedTests.swift` — day key and next-rollover maths, snapshot
  decoding, zeroing, progress clamping, and the number formatting table captured from Dart.

`RunnerTests` runs with
`xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RunnerTests`.

---

## Still open

### The Schnellzugriff configuration does not reach the widget

**The four action slots cannot currently be changed.** The configuration sheet works — it lists
the six actions, stores the selection and shows it back on reopening — but the value never
arrives in the timeline provider, which always receives the parameter defaults. Every tile
therefore renders `Add Liquid / Scan barcode / Start Workout / Log Intake` no matter what is
picked.

Established by writing what `timeline(for:in:)` actually received into the App Group and reading
it back per widget instance and family:

- `timeline(for:in:)` **is** re-run at the right moments, including immediately on configuration
  commit.
- The `configuration` argument carries default values on every single run.

Ruled out, each verified on device and none of them the cause:

| Suspected | Result |
| --- | --- |
| `AppEntity` + `EntityQuery` storing an unresolvable dynamic-option token | Switched to `AppEnum` (kept — it is simpler and makes the sheet show the real defaults). No change. |
| Entry holding the intent, `@Parameter`s not surviving entry archiving | Entry now holds resolved plain values (kept — correct regardless). No change. |
| `.never` reload policy suppressing configuration reloads | Switched to a daily policy (kept — `.never` means "app-triggered only" and can strand the widget). No change. |
| Intent metadata missing from the app bundle | Added intents to the Runner target; app metadata then contained them, and the sheet switched to the app's *unlocalized* keys — proving the system reads the app bundle. Still defaults. Reverted, as it broke localization. |
| `static var title = …` vs Apple's computed style | Switched to computed (kept). No change. |
| Stale cached parameter schema under the old intent identifier | Renamed the intent and added a fresh instance. Still defaults. Reverted the name. |

The two ways forward:

1. Keep digging on the native path — the remaining suspect is how the configuration is namespaced
   between the app bundle (`com.rfivesix.trainlibre.QuickActionsConfigIntent`, which is what the
   configuration UI writes against) and the widget extension that decodes it.
2. Move the choice into the app's own settings and ship the four actions in the App Group snapshot
   the widget already reads. That pipeline is proven end to end, so it is guaranteed to work, and
   the strings stay in the existing `.arb` files. The cost is that two placed widgets could no
   longer be configured differently, and the setting no longer lives under *Edit Widget*.

Until this is resolved the widget is still useful — the four default actions are the most common
ones and all of them work — but it must not be advertised as configurable.

### Other

- **Tinted and clear Home Screen modes (iOS 18/26)** have not been reviewed on a device. The six
  coloured bars will desaturate there; whether to accept that or force full colour with
  `widgetAccentedRenderingMode` is a design call best made while looking at it.
- **Inline actions** were deliberately deferred: every quick action opens the app. When logging a
  fixed amount of fluid straight from the widget comes up, the Live Activity's
  `pendingCommandsKey` queue is the precedent to follow.
- **Android** is not covered at all.
