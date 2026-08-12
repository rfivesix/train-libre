package com.rfivesix.trainlibre.liveupdate

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * The live update's buttons.
 *
 * A receiver rather than a direct call into the app, because the app may not be
 * running: the workout notification outlives the process, and a tap has to work
 * regardless. Each press leaves a note in the queue and immediately redraws the
 * notification, so the card responds even though the change has not reached the
 * database yet — the app applies the queue on its next run.
 */
class LiveUpdateActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val attributes = WorkoutLiveStore.attributes(context) ?: return
        val content = WorkoutLiveStore.content(context) ?: return

        val updated = when (intent.action) {
            LiveUpdateAction.SKIP_REST -> {
                WorkoutLiveStore.enqueue(context, "skipRest")
                // Skipping ends the rest, but which set comes next is the app's
                // answer to give. Until it runs, the card drops the countdown
                // and stops offering rest controls rather than claiming to know.
                content.copy(
                    phase = WorkoutPhase.SetPending,
                    restEndsAtEpochMs = null,
                    restStartedAtEpochMs = null,
                )
            }

            LiveUpdateAction.ADJUST_REST -> {
                val delta = intent.getIntExtra(LiveUpdateAction.EXTRA_DELTA_SECONDS, 0)
                if (delta == 0) return
                WorkoutLiveStore.enqueue(context, "adjustRest", mapOf("deltaSeconds" to delta))
                val ends = content.restEndsAtEpochMs ?: return
                // Never below now: a −15s that would land in the past reads as a
                // finished rest, which is what the app would make of it too.
                val moved = (ends + delta * 1000L).coerceAtLeast(System.currentTimeMillis())
                content.copy(restEndsAtEpochMs = moved)
            }

            LiveUpdateAction.COMPLETE_SET -> {
                WorkoutLiveStore.enqueue(context, "completeSet")
                // The set is logged by the app, which then pushes the real next
                // state. Withdrawing the button in the meantime is the honest
                // move — pressing it twice must not log two sets.
                content.copy(canCompleteSet = false)
            }

            else -> return
        }

        WorkoutLiveStore.saveContent(context, updated)
        WorkoutLiveUpdate.show(context, attributes, updated)
    }
}
