package com.rfivesix.trainlibre.widgets.config

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import androidx.datastore.preferences.core.Preferences
import androidx.glance.appwidget.GlanceAppWidget
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.TodayGlanceWidget
import com.rfivesix.trainlibre.widgets.glance.WidgetConfig

/**
 * Which day the widget shows before the diary's 03:00 rollover.
 *
 * Counterpart to `TodayGlanceConfigIntent` in
 * `ios/TrainLibreLiveActivity/TodayGlanceWidget.swift`.
 */
class TodayGlanceConfigActivity : WidgetConfigActivity() {

    override val widget: GlanceAppWidget = TodayGlanceWidget()
    override val titleRes = R.string.widget_today_glance_day_mode_title

    /**
     * Radio rows rather than a dropdown: there are only two choices, and each
     * needs a line of explanation that a collapsed picker could not show.
     */
    @Composable
    override fun Body(current: Preferences, onSave: (ConfigWriter) -> Unit) {
        var mode by remember(current) {
            mutableStateOf(current[WidgetConfig.dayMode] ?: WidgetConfig.DAY_MODE_FOLLOW_APP)
        }

        ConfigOption(
            label = stringResource(R.string.widget_today_glance_day_mode_follow_app),
            subtitle = stringResource(R.string.widget_today_glance_day_mode_follow_app_subtitle),
            selected = mode == WidgetConfig.DAY_MODE_FOLLOW_APP,
            onSelect = { mode = WidgetConfig.DAY_MODE_FOLLOW_APP },
        )
        ConfigOption(
            label = stringResource(R.string.widget_today_glance_day_mode_calendar_day),
            subtitle = stringResource(R.string.widget_today_glance_day_mode_calendar_day_subtitle),
            selected = mode == WidgetConfig.DAY_MODE_CALENDAR_DAY,
            onSelect = { mode = WidgetConfig.DAY_MODE_CALENDAR_DAY },
        )

        ConfigSaveButton {
            onSave { prefs -> prefs[WidgetConfig.dayMode] = mode }
        }
    }
}
