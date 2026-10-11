# Workout Live Activity

The Workout Live Activity keeps a compact view of an active workout on iOS. It can show the
current exercise and set, a rest or duration timer, and controls supported by the OS. Android
uses an ongoing workout notification; on Android 16 (API 36) the app asks the system to promote
that notification to a Live Update. Promotion and the exact presentation are controlled by
Android and device policy.

> Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

On iOS, ActivityKit support starts at iOS 16.2. Interactive App Intent buttons require iOS 17;
on iOS 16.2–16, the activity still displays but those controls are unavailable. Android displays
the ongoing notification when notifications are enabled. Its Live Update promotion is requested
only on API 36 or newer and is not guaranteed. The app does not request remote ActivityKit pushes:
it starts the iOS activity with `pushType: nil` and updates it from the app or its local intents.

## What it shows

The view depends on workout state and platform surface. During a set or rest, the iOS Lock Screen
card shows the routine title and elapsed workout time, exercise and set position, metrics, and a
checkmark when the displayed values are sufficient to complete the set. While resting, iOS 17+
also shows rest controls. An empty workout and a workout with no remaining sets have separate
states. Compact and minimal Dynamic Island layouts omit or rearrange details to fit.

Android uses a notification title and text instead of duplicating the iOS card. The title is the
exercise name when present, otherwise the workout title. During rest or a running duration timer,
the notification uses the system chronometer. It exposes the relevant timer/rest controls and a
complete-set action only when the set is eligible. Its exact display depends on the notification
shade, device, and—on API 36+—whether Android promotes it to a Live Update.

### Set values and timer behavior

For strength sets, entered values take precedence over the routine's planned weight, reps, and
RIR. Missing required values are displayed as a dash; the feature does not invent values. The
completion action is disabled or omitted until the required fields are available. On iOS, tapping
the activity outside an enabled button opens the workout through its deep link.

Duration-tracked exercises (which can include exercises other than catalogued cardio) use the
duration metrics path. Depending on the exercise's logging fields, the card may show duration,
distance, weight, and RPE. Routine set templates do not currently provide planned duration or
distance, so those values appear only after they have been logged. Whether the set can be
completed depends on the fields required by that exercise's logging mask; it is not universally
blocked until both duration and distance are present.

For a duration-based set, the timer starts at zero and counts up. Starting, stopping, and
completing it from the activity records commands; the app applies those commands to the workout
when it next runs. On iOS the App Intent updates the visible activity immediately and queues the
database command in the shared App Group. On Android a `BroadcastReceiver` queues the command,
updates its stored notification content, and redraws the notification. These actions do not
themselves open the workout screen.

## Interactions and state updates

| Action | Behavior |
|---|---|
| Tap the iOS activity or Android notification | Opens the active workout using its deep link. |
| `−15s` / `+15s` on iOS 17+ and Android | Adjusts the displayed rest end time and queues an adjustment for the app. |
| Skip rest | Clears the displayed countdown and queues the skip. The app resolves the next workout state when it applies the command. |
| Complete set | Queues completion with the current displayed values/timer state and advances the locally displayed snapshot when a following set is available. |
| Start/stop a duration timer | Updates the visible timer and queues the corresponding timer change for the app. |
| Add exercise / Open app on iOS | Opens the app by deep link; these are links, not database actions performed by the widget. |

The iOS App Intent controls are available from iOS 17. On earlier supported iOS versions, the
activity remains visible but the interactive rest and set-timer controls are not shown. Android
actions are notification actions handled by the receiver. On both platforms, a button can update
the lightweight activity/notification state before the app has applied the queued command, so the
app is the source of truth when it resumes.

The iOS widget uses a `widgetURL` for tapping the activity. An enabled checkmark is an App Intent
and queues completion without forcing the app to foreground. A checkmark with missing required
values is rendered as a disabled image; tapping the surrounding activity opens the app. Android
does not offer the complete-set action when its `canCompleteSet` state is false; a separate
notification action opens the app when available.

## Rest timer and notification sound

The displayed countdown is based on an absolute end time. iOS renders it with a system timer, and
Android renders it with a notification chronometer; neither requires a Dart update every second.
On iOS, the countdown continues past zero and the view uses a timed progress fill for its overdue
background. `staleDate` is also set to the rest end as a fallback for ActivityKit state refresh.
On Android, the implementation configures a countdown chronometer; the code does not promise a
particular overdue presentation after zero.

The rest alert is scheduled separately from the Live Activity/notification. On iOS, a native
`UNUserNotificationCenter` request with the default sound is scheduled at the rest end and
rescheduled or canceled when the user changes/skips the rest. That request may also present a
notification banner according to system notification settings; it is not suppressed just because
the Live Activity is visible. While the app is foregrounded, the workout screen plays its own
sound and haptic, and suppresses its additional foreground completion notification when a Live
Activity is running. On Android, the app's local notification service schedules the rest alert;
the workout notification itself is configured as low-importance and non-interrupting. Delivery,
sound, and banner timing remain subject to OS notification settings and scheduling behavior.

## Lifecycle and limits

The app starts the activity/notification for an active workout, updates it when visible workout
content changes, and ends or hides it when the workout is ended. The iOS bridge also ends stale
activities before starting a new one. This does not document an independent crash-recovery
guarantee for every possible OS termination path.

The activity content is a snapshot prepared by Dart: localized labels, converted units, and
formatted metric strings are sent to the native UI. Timers are sent as dates so the platform can
render them. iOS bounds the number of future set snapshots to fit ActivityKit's content-state
size; after the included snapshots are exhausted, the app must resume to provide fresh state.
Android persists the workout activity/notification attributes and content locally for its
receiver to update. On either platform, notifications/activities can be unavailable when the
user or OS disables them, and the native surfaces may truncate or rearrange content.

## Implementation map

| Path | Role |
|---|---|
| `lib/features/workout/domain/live_activity/` | Builds display content, state, and localized strings from the workout. |
| `lib/features/workout/data/live_activity/` | Sends updates and consumes queued commands through the platform channel. |
| `lib/features/workout/presentation/live_workout_view_model.dart` | Starts, updates, ends, and reconciles the activity with workout state and rest alerts. |
| `ios/LiveActivity/` | ActivityKit bridge, shared state, queued intents, and rest-sound notification. |
| `ios/TrainLibreLiveActivity/` | Lock Screen and Dynamic Island views and iOS App Intents. |
| `android/app/src/main/kotlin/com/rfivesix/trainlibre/liveupdate/` | Ongoing notification, API 36 promotion request, and action receiver. |

## Known limits

- iOS 16.2 is the ActivityKit minimum; interactive controls require iOS 17.
- Android's Live Update is an API 36+ promotion request. The ordinary ongoing notification is the fallback, and the system decides whether to promote it.
- Dynamic Island and notification surfaces do not show identical content. The available space, OS version, and device presentation affect what is visible.
- Planned routine targets for duration and distance are not currently supplied by set templates; values are shown after they are logged.
- The activity is not an editor for set metrics. To change weight, reps, or other logged values, open the workout in the app.
