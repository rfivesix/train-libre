package com.rfivesix.trainlibre.widgets.glance

import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.stringPreferencesKey
import com.rfivesix.trainlibre.widgets.QuickAction
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSnapshot

/**
 * Per-instance widget configuration.
 *
 * On iOS this is an `AppIntentConfiguration`: the parameters are declared on an
 * intent and the system builds the edit sheet from them. Android has no such
 * thing, so each configurable widget gets a configuration Activity and stores
 * the result in its own Glance state — which is per widget instance, so two
 * copies of the same widget can be configured differently.
 */
object WidgetConfig {

    // --- Today Glance ---

    /** Which day the widget shows before the diary's 03:00 rollover. */
    val dayMode = stringPreferencesKey("day_mode")

    const val DAY_MODE_FOLLOW_APP = "follow_app"
    const val DAY_MODE_CALENDAR_DAY = "calendar_day"

    /**
     * The effective rollover hour for the configured mode.
     *
     * `followApp` uses whatever the app reports rather than a hardcoded 3, so
     * the two cannot drift apart if the diary rule ever changes.
     */
    fun rolloverHour(prefs: Preferences, snapshot: HomeWidgetSnapshot?): Int =
        when (prefs[dayMode]) {
            DAY_MODE_CALENDAR_DAY -> 0
            else -> snapshot?.rolloverHour ?: HomeWidgetSnapshot.DIARY_ROLLOVER_HOUR
        }

    // --- Measurements ---

    val metricId = stringPreferencesKey("metric_id")
    val period = stringPreferencesKey("period")

    /** Mirrors `HomeWidgetMeasurementPeriod` in the Dart deep-link file. */
    enum class MeasurementPeriod(val key: String, val days: Int?) {
        SevenDays("7d", 7),
        OneMonth("1m", 30),
        ThreeMonths("3m", 90),
        SixMonths("6m", 180),

        /** "Everything there is." */
        Max("max", null);

        companion object {
            fun fromKey(key: String?): MeasurementPeriod =
                entries.firstOrNull { it.key == key } ?: OneMonth
        }
    }

    /**
     * What the widget offers before the app has ever written a snapshot, so a
     * freshly installed app still has something to configure.
     */
    const val FALLBACK_METRIC_ID = "weight"

    // --- Quick actions ---

    private val slotKeys = List(4) { stringPreferencesKey("slot_$it") }

    fun slotKey(index: Int): Preferences.Key<String> = slotKeys[index]

    /**
     * The configured actions, padded with the defaults for a widget that has not
     * been configured — and with anything unavailable dropped, so the AI slot
     * does not sit there dead when the app has AI switched off.
     */
    fun quickActions(prefs: Preferences, isAiEnabled: Boolean, count: Int): List<QuickAction> {
        val configured = slotKeys.mapNotNull { QuickAction.fromKey(prefs[it]) }
        val chosen = configured.ifEmpty { QuickAction.defaultSlots }
        val available = chosen.filter { it.isAvailable(isAiEnabled) }
        // Never show fewer tiles than the layout has slots: a gap reads as a bug,
        // so the defaults backfill anything the filter removed.
        val padded = available + QuickAction.defaultSlots.filterNot { it in available }
        return padded.take(count)
    }
}
