package com.rfivesix.trainlibre.liveupdate

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.WidgetDeepLinks
import com.rfivesix.trainlibre.widgets.deepLinkIntent
import com.rfivesix.trainlibre.widgets.theme.parseHexColor
import androidx.compose.ui.graphics.toArgb

/**
 * The running workout as an ongoing notification.
 *
 * This is Android's answer to the iOS Live Activity. On Android 16 the same
 * notification is promoted to a Live Update — a status bar chip and a prominent
 * lock screen card; below that it stays an ordinary ongoing notification with
 * the same content and the same buttons, which is a smaller presentation of the
 * same thing rather than a different feature.
 *
 * Deliberately not a foreground service. A posted notification already outlives
 * the app process, the buttons reach a `BroadcastReceiver` that can start the
 * app if it has to, and a service would have bought only a permission the app
 * does not otherwise need.
 */
object WorkoutLiveUpdate {

    const val NOTIFICATION_ID = 4711
    private const val CHANNEL_ID = "workout_live_update"

    fun show(context: Context, attributes: WorkoutLiveAttributes, content: WorkoutLiveContent) {
        ensureChannel(context)
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return

        runCatching { manager.notify(NOTIFICATION_ID, build(context, attributes, content)) }
    }

    fun hide(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.widget_live_update_channel_name),
            // Low: the card is meant to sit there, not to interrupt. The rest
            // timer's own alert is a separate, audible notification.
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.widget_live_update_channel_description)
            setShowBadge(false)
        }
        context.getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }

    private fun build(
        context: Context,
        attributes: WorkoutLiveAttributes,
        content: WorkoutLiveContent,
    ): android.app.Notification {
        val isResting = content.phase == WorkoutPhase.Resting && content.restEndsAtEpochMs != null

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_widget_start_workout)
            .setContentTitle(title(content, attributes))
            .setContentText(text(content))
            .setContentIntent(openApp(context, attributes))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setColor(parseHexColor(content.badgeColorHex).toArgb())
            // Deliberately *not* setColorized: a colorised notification is
            // explicitly disqualified from being promoted to a Live Update, so
            // asking for both means getting neither. setColor alone still tints
            // the icon and the status bar chip.
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (isResting) {
            // The countdown runs in the notification itself. Pushing a new
            // notification every second would be the wrong shape entirely — and
            // is exactly what the content model was designed to avoid.
            builder.setWhen(content.restEndsAtEpochMs!!)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
                .setShowWhen(true)
        } else {
            builder.setShowWhen(false)
        }

        addActions(context, builder, attributes, content)
        promote(builder, content, isResting)
        return builder.build()
    }

    /**
     * Asks Android 16 to promote this into a Live Update.
     *
     * A no-op everywhere else, and a request rather than a guarantee: the system
     * decides, and the notification has to work either way.
     *
     * `shortCriticalText` is what the status bar chip shows while the shade is
     * closed — the one line the user gets without pulling anything down, so it
     * carries the set's numbers. During a rest it is left unset on purpose: the
     * chronometer below is a live countdown, and a static string would sit next
     * to it going stale.
     *
     * Samsung's Now Bar on One UI 8 feeds off this same promotion, so there is
     * nothing vendor-specific to add for it.
     */
    private fun promote(
        builder: NotificationCompat.Builder,
        content: WorkoutLiveContent,
        isResting: Boolean,
    ) {
        if (Build.VERSION.SDK_INT < 36) return
        builder.setRequestPromotedOngoing(true)
        if (!isResting) {
            content.compactLine.takeIf { it.isNotEmpty() }
                ?.let { builder.setShortCriticalText(it) }
        }
    }

    private fun title(content: WorkoutLiveContent, attributes: WorkoutLiveAttributes): String =
        content.exerciseName.ifEmpty { attributes.workoutTitle }

    private fun text(content: WorkoutLiveContent): String = when (content.phase) {
        WorkoutPhase.Resting ->
            listOf(content.setPosition, content.metricsLine).filter { it.isNotEmpty() }
                .joinToString(" · ")
        WorkoutPhase.SetPending ->
            listOf(content.setPosition, content.metricsLine).filter { it.isNotEmpty() }
                .joinToString(" · ")
        WorkoutPhase.NoSetsLeft -> content.setPosition
        WorkoutPhase.Empty -> content.setPosition
    }

    private fun addActions(
        context: Context,
        builder: NotificationCompat.Builder,
        attributes: WorkoutLiveAttributes,
        content: WorkoutLiveContent,
    ) {
        when (content.phase) {
            WorkoutPhase.Resting -> {
                builder.addAction(
                    0,
                    "−15 s",
                    command(context, LiveUpdateAction.ADJUST_REST, deltaSeconds = -15),
                )
                builder.addAction(
                    0,
                    "+15 s",
                    command(context, LiveUpdateAction.ADJUST_REST, deltaSeconds = 15),
                )
                if (attributes.labelSkip.isNotEmpty()) {
                    builder.addAction(
                        0,
                        attributes.labelSkip,
                        command(context, LiveUpdateAction.SKIP_REST),
                    )
                }
            }

            WorkoutPhase.SetPending -> {
                // The checkmark carries no input of its own, so it is only
                // offered when the set already holds the values it would log.
                if (content.canCompleteSet) {
                    builder.addAction(
                        0,
                        context.getString(R.string.widget_live_update_complete_set),
                        command(context, LiveUpdateAction.COMPLETE_SET),
                    )
                }
            }

            WorkoutPhase.NoSetsLeft, WorkoutPhase.Empty -> Unit
        }

        if (attributes.labelOpenApp.isNotEmpty()) {
            builder.addAction(0, attributes.labelOpenApp, openApp(context, attributes))
        }
    }

    private fun openApp(context: Context, attributes: WorkoutLiveAttributes): PendingIntent =
        PendingIntent.getActivity(
            context,
            0,
            deepLinkIntent(context, attributes.deepLink.ifEmpty { WidgetDeepLinks.LIVE_WORKOUT }),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    private fun command(
        context: Context,
        action: String,
        deltaSeconds: Int? = null,
    ): PendingIntent {
        val intent = Intent(context, LiveUpdateActionReceiver::class.java).apply {
            this.action = action
            if (deltaSeconds != null) putExtra(LiveUpdateAction.EXTRA_DELTA_SECONDS, deltaSeconds)
        }
        // The request code has to differ per action, or the two rest buttons
        // would share one PendingIntent and both would carry the same delta.
        val requestCode = action.hashCode() + (deltaSeconds ?: 0)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}

/** The actions the live update's buttons can raise. */
object LiveUpdateAction {
    const val COMPLETE_SET = "com.rfivesix.trainlibre.LIVE_COMPLETE_SET"
    const val ADJUST_REST = "com.rfivesix.trainlibre.LIVE_ADJUST_REST"
    const val SKIP_REST = "com.rfivesix.trainlibre.LIVE_SKIP_REST"

    const val EXTRA_DELTA_SECONDS = "deltaSeconds"
}
