# Manual Workout Plans

Manual plans place routines and rest days on a calendar. They do not generate workouts, create missed-session debt, or prescribe a catch-up session.

Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

## Plan formats and revisions

- **Weekly plan:** Assign a routine or rest day to each weekday. The seven weekday slots stay fixed; a missed workout does not shift the following weekdays.
- **Training sequence:** Arrange routines and rest days into a repeating sequence of 1–14 days. Rest days advance the sequence automatically. A missed workout slot remains the current slot until that workout is completed, partially completed, or explicitly skipped. Future calendar dates are projections and assume each upcoming slot is resolved.

Only one plan can be active at a time. A plan must include at least one workout, and each workout day must use a saved routine with at least one set. Plans store a routine snapshot in each revision, so later routine edits do not rewrite the plan’s saved prescription. An edit can take effect from today or at the next week/sequence cycle. Changing between weekly and sequence formats requires creating a new plan.

## Starting and resolving sessions

The active plan’s eligible workout can be started from the Diary card or plan calendar. Starting a past planned day from the calendar requires confirmation. An ongoing workout is linked to that planned occurrence. When the workout is completed, the app compares completed sets with the saved routine’s set requirements: meeting every requirement records **completed**; otherwise it records **partial**. The sequence advances after either outcome. Skipping is an explicit, separately confirmed action; a skipped slot also advances the sequence. A workout that is still ongoing does not resolve the slot.

Completed and partially completed occurrences with a linked workout can open that workout’s saved details. Rest days have no session to start. The plan does not add a replacement workout for an uncompleted day.

## Reminders and portability

Workout plan reminders are optional and off until enabled in Settings. When enabled, the app schedules local reminders for unresolved workout days on the active plan from today through 28 days after today, at the selected local time (18:00 by default). Reminder times that have already passed are omitted. The notification scheduler requests exact Android delivery and falls back to inexact delivery if the platform rejects that request; actual delivery timing therefore depends on platform scheduling. Tapping a plan reminder opens the active plan, rather than a particular session. Editing, activating, deactivating, or resolving plan sessions triggers reminder synchronization.

Backups include plan records, revisions, activations, occurrences, and routine/workout bindings; restore code remaps linked identifiers. The backup also includes user preference keys, which carry the plan reminder settings. Pending OS notification requests are not serialized as plan data.
