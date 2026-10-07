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
                val timerStartedAt = content.setTimerStartedAtEpochMs
                val timerTemplateId = content.setTimerTemplateId
                val timerElapsedSeconds = if (timerStartedAt != null) {
                    ((System.currentTimeMillis() - timerStartedAt) / 1000L).toInt().coerceAtLeast(0)
                } else {
                    content.setTimerElapsedSeconds.coerceAtLeast(0)
                }
                val command = if (timerTemplateId != null && (timerStartedAt != null || timerElapsedSeconds > 0)) {
                    mapOf(
                        "timerTemplateId" to timerTemplateId,
                        "elapsedSeconds" to timerElapsedSeconds,
                    )
                } else {
                    emptyMap()
                }
                WorkoutLiveStore.enqueue(context, "completeSet", command)
                val next = content.upcomingSets.firstOrNull()
                if (next == null) {
                    content.copy(
                        phase = WorkoutPhase.NoSetsLeft,
                        setTimerStartedAtEpochMs = null,
                        setTimerDeadlineEpochMs = null,
                        setTimerTemplateId = null,
                        canCompleteSet = false,
                        upcomingSets = emptyList(),
                    )
                } else {
                    content.copy(
                        phase = WorkoutPhase.SetPending,
                        restEndsAtEpochMs = null,
                        restStartedAtEpochMs = null,
                        setTimerStartedAtEpochMs = null,
                        setTimerDeadlineEpochMs = null,
                        setTimerTemplateId = next.setTimerTemplateId,
                        setTimerElapsedSeconds = 0,
                        exerciseName = next.exerciseName,
                        setPosition = next.setPosition,
                        badgeText = next.badgeText,
                        badgeColorHex = next.badgeColorHex,
                        metricPrimary = next.metricPrimary,
                        metricSecondary = next.metricSecondary,
                        metricTertiary = next.metricTertiary,
                        metricSeparator = next.metricSeparator,
                        compactPrimary = next.compactPrimary,
                        compactSecondary = next.compactSecondary,
                        canCompleteSet = next.canCompleteSet,
                        upcomingSets = content.upcomingSets.drop(1),
                    )
                }
            }

            LiveUpdateAction.START_SET_TIMER -> {
                val templateId = intent.getIntExtra(LiveUpdateAction.EXTRA_TEMPLATE_ID, 0).takeIf { it != 0 } ?: return
                val startedAt = System.currentTimeMillis()
                val elapsedSeconds = content.setTimerElapsedSeconds.coerceAtLeast(0)
                WorkoutLiveStore.enqueue(context, "startSetTimer", mapOf(
                    "templateId" to templateId,
                    "startedAtEpochMs" to startedAt,
                    "elapsedSeconds" to elapsedSeconds,
                ))
                content.copy(
                    setTimerStartedAtEpochMs = startedAt - elapsedSeconds * 1000L,
                    setTimerDeadlineEpochMs = null,
                    canCompleteSet = true,
                )
            }

            LiveUpdateAction.STOP_SET_TIMER -> {
                val templateId = intent.getIntExtra(LiveUpdateAction.EXTRA_TEMPLATE_ID, 0).takeIf { it != 0 } ?: return
                val startedAt = content.setTimerStartedAtEpochMs ?: return
                val elapsed = ((System.currentTimeMillis() - startedAt) / 1000L).toInt().coerceAtLeast(0)
                WorkoutLiveStore.enqueue(context, "stopSetTimer", mapOf(
                    "templateId" to templateId,
                    "elapsedSeconds" to elapsed,
                ))
                content.copy(
                    setTimerStartedAtEpochMs = null,
                    setTimerDeadlineEpochMs = null,
                    setTimerElapsedSeconds = elapsed,
                    canCompleteSet = content.canCompleteSet || elapsed > 0,
                )
            }

            else -> return
        }

        WorkoutLiveStore.saveContent(context, updated)
        WorkoutLiveUpdate.show(context, attributes, updated)

    }
}
