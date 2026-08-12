package com.rfivesix.trainlibre.widgets

import android.content.Context
import android.util.Log
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.updateAll

/**
 * Redraws every widget the snapshot feeds.
 *
 * The iOS side keeps a list of timeline kinds for this
 * (`TrainLibreHomeWidget.allKinds`); on Android the equivalent identity is the
 * `GlanceAppWidget` class itself, so this is that list.
 */
object HomeWidgetRefresher {
    private const val TAG = "HomeWidgetRefresher"

    /**
     * Every widget fed by the snapshot. Entries are added as each widget lands;
     * a widget missing from this list still renders on its own schedule but will
     * not react to a diary change, which is the bug this list exists to prevent.
     */
    private val widgets: List<GlanceAppWidget>
        get() = listOf(
            StepsWidget(),
            RecoveryWidget(),
            LastWorkoutWidget(),
            TodayGlanceWidget(),
            MeasurementsWidget(),
            QuickActionsWidget(),
        )

    suspend fun refreshAll(context: Context) {
        for (widget in widgets) {
            try {
                widget.updateAll(context)
            } catch (e: Exception) {
                // One widget failing to redraw must not stop the others, and
                // must never take the app's channel call down with it.
                Log.w(TAG, "Failed to refresh ${widget.javaClass.simpleName}", e)
            }
        }
    }
}
