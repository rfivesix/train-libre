# Workout Live Activity

The **Workout Live Activity** puts the current workout on the Lock Screen and in the Dynamic
Island for as long as a session is running. It answers one question at a glance — *what am I
lifting next, and how much rest is left* — so the phone can stay in a pocket, on a bench, or on
a music screen without the workout disappearing from view.

Available on iOS 16.2 and newer. The Dynamic Island presentations require an iPhone 14 Pro or
newer; every device gets the Lock Screen card. Interactive buttons require iOS 17.

> Like everything else in Train Libre, this runs entirely on the device. Live Activities are
> commonly driven by remote push notifications; this one never is. There is no server, no APNs
> certificate and no network round-trip — the app updates the card directly, and the system
> animates the timers on its own.

---

## What it shows

The card always carries the same four pieces of information:

```
[icon]  Push Day                                          17:06
        Bench Press                                 Set 3 of 5
        W  72.5 kg  ×  8 reps  (RIR 2)                     [✓]
```

- **Header** — routine name and the elapsed workout duration, counting up on its own.
- **Exercise and position** — which exercise, and where in it you are.
- **The set** — set type, weight, reps and RIR, led by a coloured set-type badge.
- **The checkmark** — completes the set with the values shown.

The **set-type badge** uses the same letters and colours as the app's own set rows: `W` warm-up
in orange, `F` failure in red, `D` drop set in blue, `S` superset and `O` other in neutral grey.
Normal working sets show `N` — the position is already spelled out as "Set 3 of 5" beside it, so
repeating the number would add nothing.

While a rest timer runs, a control row appears beneath the set:

```
        [ −15s ]        1:07        [ +15s ]        [ Skip ]
```

When there are no sets left the card offers **Add exercise**; if a workout is running with no
exercises at all, it offers **Open app**. The workout is never finished from the card — that
stays a deliberate action inside the app.

### Cardio

Cardio sets use the same card with different numbers: duration, distance and RPE instead of
weight, reps and RIR, separated by `·` instead of `×`, and without a set-type badge.

```
        Treadmill                                   Set 1 of 1
        20:00  ·  5.00 km  (RPE 7)                         [✓]
```

Routines currently store no target duration or distance for cardio, so a cardio set shows values
only once they have been entered. Until then the line reads `–` and the set cannot be completed
from the card.

---

## The four surfaces

| Surface | What it shows |
|---|---|
| **Lock Screen / banner** | The full card described above |
| **Dynamic Island, expanded** | The same content, laid out for the narrower island |
| **Dynamic Island, compact** | Rest timer on the left, `72.5 kg / × 8` on the right |
| **Dynamic Island, minimal** | One element: the rest timer, or `115×9`, or the app icon |

Which of the compact and minimal forms you see is decided by iOS, not by the app. When a second
Live Activity is on screen — a music player, a timer — both are reduced to their minimal circle.
Because that circle is then the only place the set appears at all, it shows the numbers rather
than the app icon.

---

## Interactions

| Element | Effect |
|---|---|
| Tapping the card | Opens the running workout. Never stacks a second copy of the screen. |
| `−15s` / `+15s` | Extends or shortens the running pause |
| `Skip` | Ends the pause immediately |
| `✓` | Completes the set with the values shown and starts the next pause |
| **Add exercise** | Opens the exercise picker |

The buttons work while the app is closed. They run in the widget's own process, which has no
access to the app's database — so a completed set is recorded as a pending command in the shared
App Group and applied by the app the next time it runs. Because of that, the checkmark also
brings the app to the foreground; the timer buttons do not need to.

**A set with missing values cannot be completed from the card.** If weight or reps are unknown,
the checkmark is grey and inert, and tapping it opens the app instead. Missing numbers are shown
as `–`; nothing is ever filled in from the plan or guessed.

---

## The rest timer

The rest countdown is the part of the card people look at most, and the part with the most
subtlety behind it.

**It never stops.** The number counts down to zero and then keeps counting *up*, so an overdue
pause shows how long it has been overdue rather than sitting frozen at `0:00`.

**The field turns red the moment the pause ends** — not a second later. This matters more than it
sounds: a Live Activity cannot change its own layout, text or colour while the app is asleep.
Only a handful of system-drawn views update on their own, and the red backdrop is built from one
of them, so it flips exactly on time without the app being woken at all.

**The sound is what actually reaches you** when the phone is in a pocket and music is playing.
It is scheduled ahead of time and moves along when the pause is changed from the card, so `+15s`
really does mean fifteen seconds more. While the card is visible, the app does not additionally
post a banner — the card already says it.

---

## Behaviour worth knowing

- The Live Activity ends when the workout is finished or discarded. A workout left over from a
  crash or force quit is cleaned up when the next one starts.
- iOS ends Live Activities after about eight hours and removes them from the Lock Screen after
  twelve. A very long session will lose the card before the workout ends.
- If Live Activities are switched off in Settings, the workout is unaffected; the card simply
  never appears.
- Editing the workout in the app — adding, removing or reordering sets and exercises — is
  reflected on the card immediately.
- Text is fully localized (DE, EN, FR, IT, JA) and follows the chosen unit system, including
  lbs and miles.

---

## How it fits together

Everything the card displays is prepared in Dart and handed over ready to draw: numbers already
formatted, units already converted, words already translated, badge colours already resolved. The
Swift side formats nothing — it lays out strings it does not interpret. That keeps a single source
of truth for how a set is written, shared with the rest of the app.

Times are the exception, and deliberately so: they cross over as absolute dates rather than
counters, which lets the system animate them without an update every second. A running workout
needs roughly one update per set.

| Path | Role |
|---|---|
| `lib/features/workout/domain/live_activity/` | Builds the card's content from the session |
| `lib/features/workout/data/live_activity/` | Channel to the platform |
| `ios/LiveActivity/` | Shared model, bridge, rest-sound scheduler |
| `ios/TrainLibreLiveActivity/` | The widget extension: views, App Intents, theme |
| `test/features/workout/live_activity_content_test.dart` | Content, badges, cardio, guard rails |

---

## Known limits

- **Android is not covered.** Live Activities are an iOS feature; the equivalent there is a
  foreground-service notification and has not been built.
- **Cardio targets do not exist yet.** Routines store no planned duration or distance, so cardio
  sets stay empty until values are entered.
- **The numbers cannot be edited from the card.** Weight and reps are shown as planned; changing
  them means opening the app.
