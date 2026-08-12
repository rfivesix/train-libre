package com.rfivesix.trainlibre.widgets.config

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.datastore.preferences.core.Preferences
import androidx.glance.appwidget.GlanceAppWidget
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.MeasurementsWidget
import com.rfivesix.trainlibre.widgets.glance.WidgetConfig
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetStore

/**
 * The metric and timeframe of the measurements widget.
 *
 * Counterpart to `MeasurementsConfigIntent` in
 * `ios/TrainLibreLiveActivity/MeasurementsWidget.swift`. The metric list comes
 * from the snapshot for the same reason it does there: it is whatever the user
 * has actually measured, and a fixed list would either miss metrics or offer
 * ones nobody records.
 */
class MeasurementsConfigActivity : WidgetConfigActivity() {

    override val widget: GlanceAppWidget = MeasurementsWidget()
    override val titleRes = R.string.widget_measurements_name

    private data class Metric(val id: String, val name: String)

    @Composable
    override fun Body(current: Preferences, onSave: (ConfigWriter) -> Unit) {
        val context = LocalContext.current

        // Read once: the app cannot write a snapshot while this screen is up.
        val metrics = remember {
            HomeWidgetStore.load(context)?.measurements.orEmpty()
                .map { Metric(it.id, it.name) }
                .ifEmpty {
                    // Nothing recorded yet, or a widget added before the app was
                    // ever opened. Offer the one metric everyone starts with
                    // rather than an empty screen with a dead save button.
                    listOf(
                        Metric(
                            WidgetConfig.FALLBACK_METRIC_ID,
                            context.getString(R.string.widget_measurements_metric_weight),
                        ),
                    )
                }
        }

        var metric by remember(current) {
            val storedId = current[WidgetConfig.metricId]
            // A metric the user configured and has since stopped recording is no
            // longer in the list; falling back to the first one is the only
            // honest option, since the picker cannot offer what is not there.
            mutableStateOf(metrics.firstOrNull { it.id == storedId } ?: metrics.first())
        }
        var period by remember(current) {
            mutableStateOf(WidgetConfig.MeasurementPeriod.fromKey(current[WidgetConfig.period]))
        }

        ConfigDropdown(
            label = stringResource(R.string.widget_measurements_metric_title),
            options = metrics,
            selected = metric,
            optionLabel = { it.name },
            onSelect = { metric = it },
        )
        ConfigDropdown(
            label = stringResource(R.string.widget_measurements_period_title),
            options = WidgetConfig.MeasurementPeriod.entries,
            selected = period,
            optionLabel = { context.getString(periodLabel(it)) },
            onSelect = { period = it },
        )

        ConfigSaveButton {
            onSave { prefs ->
                prefs[WidgetConfig.metricId] = metric.id
                prefs[WidgetConfig.period] = period.key
            }
        }
    }

    private fun periodLabel(period: WidgetConfig.MeasurementPeriod): Int = when (period) {
        WidgetConfig.MeasurementPeriod.SevenDays -> R.string.widget_measurements_period_7d
        WidgetConfig.MeasurementPeriod.OneMonth -> R.string.widget_measurements_period_1m
        WidgetConfig.MeasurementPeriod.ThreeMonths -> R.string.widget_measurements_period_3m
        WidgetConfig.MeasurementPeriod.SixMonths -> R.string.widget_measurements_period_6m
        WidgetConfig.MeasurementPeriod.Max -> R.string.widget_measurements_period_max
    }
}
