# Plan — Full App Intents surface: Shortcuts, Control Center, Siri

**Status:** proposal, nothing implemented.
**Scope:** iOS only. Turn the handful of intents that exist for widgets and the Live Activity
into a complete, first-class App Intents surface — the Shortcuts app, Siri, Control Center,
Action Button, Lock Screen and Spotlight.

---

## 1. Where we stand

| Intent | Target | Kind | Runs where |
| --- | --- | --- | --- |
| `AdjustRestIntent`, `SkipRestIntent` | extension | `LiveActivityIntent`, `isDiscoverable = false` | background |
| `CompleteSetIntent` | extension | `LiveActivityIntent`, `openAppWhenRun = true` | opens app |
| `QuickActionsConfigIntent` | extension | `WidgetConfigurationIntent` | widget config |
| Quick-action tiles | extension | *not intents* — `trainlibre://action/<key>` deep links | opens app |

Three facts from the existing code drive the whole plan:

1. **Nothing is discoverable.** Every intent we have is either `isDiscoverable = false` or a
   widget configuration. There is no `AppShortcutsProvider`, no phrases, no Siri, and the
   Shortcuts app shows the app with zero actions.
2. **Intents live only in the extension target.** Siri and the Shortcuts app run the *app's*
   copy of an intent. Anything meant to be user-facing has to be visible to the Runner target too.
3. **The extension cannot touch the database.** `app_hybrid.sqlite` lives in the app's Documents
   directory ([`drift_database.dart:1160`](../../lib/data/drift_database.dart:1160)), not in the
   App Group. `CompleteSetIntent`'s comment already states the consequence and the workaround:
   record the intent, hand over to the app. That workaround becomes the architecture.

---

## 2. The central decision: how an intent reads and writes data

Every ambitious item below ("log 300 ml", "how much protein do I have left?") reduces to this
one question. Three options:

**A — Open the app for everything.** What the quick-action tiles do today. Zero new
infrastructure, but it is fatal for the goal: a Siri command or a Shortcuts automation that
unlocks the phone and animates a Flutter app into the foreground is not a feature people use
twice, and Control Center controls are expected to act in place.

**B — Move the SQLite file into the App Group and read/write it from Swift.** The "real" answer,
and the wrong trade here. It means a file migration on every existing install, a hand-written
Swift mirror of the drift schema that has to track every future migration, and two processes
writing the same database while one of them (the Flutter app) may be suspended holding a lock.
The cost lands on every future schema change forever.

**C — A shared read model plus a write journal in the App Group.** ← recommended.
An extension of the mechanism the widgets already use, generalized:

```
Flutter (owns the database)                 App Group                    Extension / Siri / Control
───────────────────────────                 ─────────                    ─────────────────────────
any mutation ──► SharedStateWriter ──────►  shared_state.json      ────►  reads: totals, targets,
                 (aggregates + entity                                     workout status, entity
                  index, versioned)                                       lists for pickers
                                                                             │
app launch/resume ◄── applies + clears ──   command_journal        ◄────  writes: append command
                       (idempotent by id)                                    + optimistic delta so
                                                                             the reply is truthful
```

- **Reads** are served from a versioned `shared_state.json` — today's totals and targets (the
  existing `HomeWidgetSnapshot`, grown), live workout status, streak, due supplements, recovery
  state, plus a small **entity index** (ids + display names) for Shortcuts parameter pickers.
- **Writes** append to a **command journal** — the generalization of
  `LiveActivityCommandStore` and its `live_activity_pending_commands` key, which already proves
  the pattern works end to end. Every entry carries a UUID; the app drops what it has applied.
- **Optimistic delta.** After appending, the intent also applies the change to its in-memory view
  of the shared state and writes it back, so Siri can answer *"1750 ml — noch 750 bis zum Ziel"*
  instead of *"okay"*. The app recomputes the truth on next launch and overwrites.

Consequences to accept up front: writes are **eventually consistent** (visible in the app on its
next run), and the entity index puts routine/food/supplement *names* into the App Group
container. Section 8 covers both.

---

## 3. Target action catalogue

Grouped by domain. **Journal** = runs in the background via §2C. **Opens app** = genuinely needs
UI (camera, AI capture, a picker we will not rebuild in SwiftUI). **Read** = returns a value and
a dialog, no write.

### Nutrition
| Action | Parameters | Mode |
| --- | --- | --- |
| `LogWaterIntent` | amount + unit (`ml`/`l`/`oz`), default from settings | journal |
| `LogFoodIntent` | `FoodEntity` (recents + favourites), grams, meal type | journal |
| `LogSavedMealIntent` | `MealEntity` from `Meals` | journal |
| `GetNutritionSummaryIntent` | — | read, returns kcal/protein/carbs/fat/fibre + remaining |
| `GetRemainingCaloriesIntent` | — | read, single value for Shortcuts chaining |
| `ScanBarcodeIntent` | — | opens app |
| `CaptureAiMealIntent` | — | opens app (and respects the AI-off state, like the tile does) |

### Workout
| Action | Parameters | Mode |
| --- | --- | --- |
| `StartWorkoutIntent` | `RoutineEntity` (optional → free session) | opens app, phase 1 (see §5) |
| `CompleteSetIntent` | — | journal (exists; make discoverable) |
| `SkipRestIntent`, `AdjustRestIntent` | delta | journal (exist; make discoverable) |
| `EndWorkoutIntent` | — | journal |
| `GetWorkoutStatusIntent` | — | read: exercise, set, rest remaining |
| `GetRecoveryStatusIntent` | muscle group (optional) | read, from the recovery model |
| `LogMeasurementIntent` | `MeasurementTypeEntity`, value | journal |

### Supplements
`LogSupplementIntent(SupplementEntity, dose?)` · `LogAllDueSupplementsIntent` ·
`GetDueSupplementsIntent` — all journal/read.

### Health & insight (read-only)
`GetStepsTodayIntent` · `GetSleepScoreIntent` · `GetStreakIntent` · `GetTodayGlanceIntent`
(returns a snippet view — see §6).

### Navigation
One `OpenScreenIntent(screen: AppScreen)` with an `AppEnum` covering diary, workout, statistics,
supplements, profile — replacing the ad-hoc `trainlibre://` deep links with a single supported
entry point. The existing deep-link parser stays as the transport.

### Entities to export
`FoodEntity`, `MealEntity`, `RoutineEntity`, `ExerciseEntity`, `SupplementEntity`,
`MeasurementTypeEntity` — backed by `Products`/`UserFoodOverrides`, `Meals`, `Routines`,
`Exercises`, `Supplements`, `Measurements`.

> **Note on `AppEntity`.** [`QuickActionEntity.swift`](../../ios/TrainLibreLiveActivity/QuickActionEntity.swift)
> documents that an entity parameter failed to round-trip and an `AppEnum` was needed. That
> finding is about a **`WidgetConfigurationIntent`**, where the selection is persisted and later
> re-resolved through the query in a different process. It does not apply to a Shortcuts intent,
> where the query is resolved live. Keep the enum for widget configuration; use entities for
> Shortcuts. Verify this early — it is a load-bearing assumption for the parameterized actions.

---

## 4. Shortcuts app

- Every intent above appears automatically once it is `isDiscoverable` and visible to the Runner
  target — that alone takes the Shortcuts action list from 0 to ~20.
- `ParameterSummary` per intent so each action reads as a sentence
  (*"Log **250 ml** water"*), with `requestValueDialog` on parameters Siri must ask for.
- Return types matter for chaining: read intents return `ReturnsValue<Double>` /
  `ReturnsValue<[FoodEntity]>`, not just dialog.
- Ship a **starter gallery** in-app (`ShortcutsLink`) and document recipes: *arriving at the gym →
  start routine*, *08:00 → log supplements*, *NFC tag on the water bottle → +500 ml*.

## 5. Siri

- `AppShortcutsProvider` with the **10 highest-value** actions (hard system limit): log water,
  today's nutrition, remaining calories, start workout, complete set, log supplement, log weight,
  steps, streak, open diary.
- Every phrase must contain `\(.applicationName)` and must be localized for **de, en, fr, it, ja**
  — five natural phrasings per action per locale, in `AppShortcuts.xcstrings`. This is the single
  largest non-code work item in the plan and needs a native check per locale, not machine output.
- `IntentDialog` on every result so Siri speaks a real answer.
- **Donation:** call `.donate()` after the equivalent in-app action so Siri Suggestions and
  Spotlight learn the habit. This is what makes the feature feel alive rather than hidden.
- In-app `SiriTipView` on the diary and workout screens for discovery.
- **`StartWorkoutIntent` in the background** is deliberately deferred to a later phase: starting a
  session means a DB write *and* starting a Live Activity, and starting an activity from a
  background intent is the one part of this plan with real platform risk. Phase 1 opens the app;
  revisit with a prototype before promising otherwise.
- Apple Intelligence assistant schemas cover mail, photos, browser and similar domains — there is
  no fitness/nutrition schema to adopt. Custom intents are the whole story here; do not chase it.

## 6. Control Center, Action Button, Lock Screen

One `ControlWidget` per control, all in the existing `TrainLibreLiveActivity` extension, iOS 18+
(gated exactly like the Home Screen widgets are in `TrainLibreLiveActivityBundle`). The same
declarations power Control Center, the Action Button and the Lock Screen buttons — three surfaces
for one implementation.

| Control | Type | Behaviour |
| --- | --- | --- |
| Quick water | `ControlWidgetButton` + `ControlValueProvider` | +250 ml in place, value label shows today's total |
| Start workout | button | opens app (phase 1) |
| Complete set | button | journal; only meaningful mid-workout — value provider reports state |
| AI meal / barcode | button | opens app to camera |
| Log supplement | button | journal |
| Open diary | button | opens app |

Control widgets read their state from the same `shared_state.json`, so they are free once §2 exists.

## 7. Beyond the three headline surfaces

- **Interactive Home Screen widget.** With journal writes available, the quick-action tiles can
  stop being deep links: a water tile can log 250 ml in place with a `Button(intent:)`. This is a
  direct upgrade of a shipped feature and probably the highest satisfaction-per-line item here.
- **Spotlight.** `IndexedEntity` (iOS 18) on the exported entities makes routines, foods and
  supplements findable in Spotlight.
- **Focus Filters** (`SetFocusFilterIntent`): a "Gym" Focus puts the app in workout mode and
  suppresses nutrition reminders.
- **Out of scope:** watchOS.

---

## 8. Cross-cutting work

**Xcode plumbing (do first, blocks everything).** Intents must compile into both Runner and
extension. Follow the arrangement already used for `HomeWidgetShared.swift` and
`WorkoutActivityAttributes.swift` — shared sources in both targets — rather than inventing a new
one, and move the existing three intents there.

**Deployment targets.** App Intents ≥ 16, `LiveActivityIntent` ≥ 17, controls and `IndexedEntity`
≥ 18. Same `if #available` gating as the widget bundle; nothing regresses for 16/17 users.

**Journal v2.** Typed commands, schema version, idempotency by UUID, a size cap with a documented
drop policy, and ordering rules for commands that arrive out of order. Unify
`live_activity_pending_commands` into it rather than running two queues.

**Shared state writer (Dart).** One service that rebuilds `shared_state.json` — extending
`HomeWidgetSyncService` — on every relevant mutation and on backgrounding. Entity index refreshes
only when its source tables change; it must not be rebuilt on every water log.

**Privacy.** This is the one place the plan changes the app's data posture: aggregate totals were
safe by construction, an entity index is not — it carries user-authored food, routine and
supplement names into the App Group container. Required:
- a **Siri & Shortcuts** settings toggle that gates the entity index (actions keep working
  without pickers);
- entity index cleared on toggle-off and by
  [`local_app_data_reset_service.dart`](../../lib/services/local_app_data_reset_service.dart);
- no new network dependency anywhere in this plan — everything stays on device;
- document it in the feature doc the way `ios_home_screen_widgets.md` documents the snapshot's
  "aggregates only" rule.

**Testing.**
- Swift unit tests next to `HomeWidgetSharedTests` for journal encode/decode, idempotency,
  optimistic deltas and shared-state parsing.
- Dart tests for journal application, replay-safety and entity index rebuild triggers.
- A device matrix that cannot be automated: each of the 10 phrases per locale, Control Center,
  Action Button, Lock Screen, and offline/airplane behaviour.

---

## 9. Phasing

| Phase | Content | Ships |
| --- | --- | --- |
| **0** | Xcode plumbing, journal v2, shared state writer, entity index, privacy toggle | nothing user-visible — foundation |
| **1** | Parameterless + water intents, `OpenScreenIntent`, existing three made discoverable | Shortcuts app has real actions |
| **2** | Entities and parameterized intents (food, routine, supplement, measurement) | full Shortcuts catalogue |
| **3** | `AppShortcutsProvider`, phrases ×5 locales, dialogs, snippet views, donation, `SiriTipView` | Siri |
| **4** | Control widgets | Control Center, Action Button, Lock Screen |
| **5** | Interactive widget tiles, Spotlight, Focus Filters | polish |
| **6** | Feature documentation, localization QA, shipped shortcut gallery, CHANGELOG | release |

Phase 0 is the whole bet. Phases 1–5 are each small once it exists; if phase 0 is skipped or
half-done, every later phase quietly degrades into option A from §2 — actions that just open
the app — which is the failure mode this plan exists to avoid.

## 10. Open questions

1. Does an `AppEntity` parameter round-trip in a non-widget intent here (§3 note)? Prototype in
   phase 0 — it decides whether phase 2 is possible as designed.
2. Can a Live Activity be started reliably from a background intent (§5)? If not,
   `StartWorkoutIntent` opens the app permanently, and that should be stated rather than retried.
3. Journal conflict policy: user logs 250 ml via Siri and 250 ml in the app before the journal is
   applied — the UUID makes replay safe, but two genuinely separate logs must both survive.
4. Does the water amount unit follow `unit_service.dart`, or does the intent take an explicit
   unit parameter? (Proposal: explicit parameter, defaulting to the setting.)
