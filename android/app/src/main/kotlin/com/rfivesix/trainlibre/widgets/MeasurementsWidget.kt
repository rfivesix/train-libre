package com.rfivesix.trainlibre.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.layout.wrapContentWidth
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.charts.MeasurementChartRenderer
import com.rfivesix.trainlibre.widgets.glance.SnapshotWidget
import com.rfivesix.trainlibre.widgets.glance.WidgetConfig
import com.rfivesix.trainlibre.widgets.glance.contentWidth
import com.rfivesix.trainlibre.widgets.glance.openOnTap
import com.rfivesix.trainlibre.widgets.glance.toPx
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetMeasurementMetric
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSnapshot
import com.rfivesix.trainlibre.widgets.theme.RoundedShape
import com.rfivesix.trainlibre.widgets.theme.StatsActionPill
import com.rfivesix.trainlibre.widgets.theme.StatsFormat
import com.rfivesix.trainlibre.widgets.theme.StatsHeader
import com.rfivesix.trainlibre.widgets.theme.StatsPalette
import com.rfivesix.trainlibre.widgets.theme.StatsTheme
import com.rfivesix.trainlibre.widgets.theme.provider
import com.rfivesix.trainlibre.widgets.theme.roundedBackground
import com.rfivesix.trainlibre.widgets.theme.statsWidgetContainer
import kotlin.math.abs

/**
 * A measurement series over the configured timeframe.
 *
 * Port of `MeasurementsWidget` in
 * `ios/TrainLibreLiveActivity/MeasurementsWidget.swift`. The snapshot carries
 * every metric's full history, so the timeframe — which the app never learns
 * about — is applied here.
 */
class MeasurementsWidget : SnapshotWidget() {

    /** The stats column's fixed share, matching the iOS card. */
    private val statsWidth = 128.dp
    private val chartHeight = 78.dp

    @Composable
    override fun Content(snapshot: HomeWidgetSnapshot?) {
        val context = LocalContext.current
        val palette = StatsPalette.of(context)
        val prefs = currentState<Preferences>()

        val period = WidgetConfig.MeasurementPeriod.fromKey(prefs[WidgetConfig.period])
        val configuredId = prefs[WidgetConfig.metricId] ?: WidgetConfig.FALLBACK_METRIC_ID
        // A metric the user configured and has since stopped recording keeps its
        // slot rather than silently snapping back to weight — the empty state
        // explains itself better than a different metric would.
        val metric = snapshot?.measurements?.firstOrNull { it.id == configuredId }
        val points = metric?.pointsWithinDays(period.days).orEmpty()

        Column(
            modifier = GlanceModifier
                .statsWidgetContainer(palette)
                .openOnTap(WidgetDeepLinks.measurements(configuredId, period.key)),
        ) {
            StatsHeader(
                title = metric?.name
                    ?: context.getString(R.string.widget_measurements_metric_weight),
                palette = palette,
                chip = context.getString(periodLabel(period)),
            )
            // Flexible, like SwiftUI's `Spacer(minLength: 8)`: the figures and
            // the chart sit at the bottom of the card however tall it is made.
            Spacer(GlanceModifier.height(8.dp).defaultWeight())

            if (points.isEmpty()) {
                EmptyBody(palette)
            } else {
                Series(metric, points, palette)
            }
        }
    }

    @Composable
    private fun Series(
        metric: HomeWidgetMeasurementMetric?,
        points: List<com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetMeasurementPoint>,
        palette: StatsPalette,
    ) {
        val context = LocalContext.current
        val latest = points.last()
        val first = points.first()
        // Null for a single data point — there is no change to state, and an em
        // dash beats a "0.0" that would read as "held perfectly steady".
        val delta = if (points.size > 1) latest.value - first.value else null
        val chartWidth = (contentWidth() - statsWidth - 10.dp).coerceAtLeast(0.dp)

        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Bottom,
        ) {
            Column(modifier = GlanceModifier.width(statsWidth)) {
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        text = StatsFormat.decimal1(latest.value),
                        maxLines = 1,
                        style = StatsTheme.bigNumberStyle.copy(color = palette.onSurface.provider()),
                    )
                    if (!metric?.unit.isNullOrEmpty()) {
                        Text(
                            text = " ${metric?.unit}",
                            maxLines = 1,
                            style = TextStyle(
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = palette.onSurface.copy(alpha = 0.6f).provider(),
                            ),
                        )
                    }
                }
                Spacer(GlanceModifier.height(8.dp))
                DeltaChip(delta, metric?.unit.orEmpty(), palette)
                Spacer(GlanceModifier.height(6.dp))
                Text(
                    text = if (points.size > 1) {
                        context.getString(
                            R.string.widget_measurements_since,
                            StatsFormat.shortDate(first.epochMs.toLong()),
                        )
                    } else {
                        context.getString(R.string.widget_measurements_single_entry)
                    },
                    maxLines = 1,
                    style = StatsTheme.captionStyle.copy(color = palette.secondaryText.provider()),
                )
            }
            Spacer(GlanceModifier.width(10.dp))
            Image(
                provider = ImageProvider(
                    MeasurementChartRenderer.render(
                        context = context,
                        points = points,
                        palette = palette,
                        widthPx = chartWidth.toPx(),
                        heightPx = chartHeight.toPx(),
                    ),
                ),
                contentDescription = null,
                contentScale = ContentScale.Fit,
                modifier = GlanceModifier.width(chartWidth).height(chartHeight),
            )
        }
    }

    /**
     * Direction, not judgement: the widget has no idea whether the user is
     * cutting or bulking, so it colours the movement and lets them read it.
     */
    @Composable
    private fun DeltaChip(delta: Double?, unit: String, palette: StatsPalette) {
        if (delta == null) {
            Box(
                modifier = GlanceModifier
                    .wrapContentWidth()
                    .roundedBackground(palette.secondarySurface, RoundedShape.Pill)
                    .padding(horizontal = 11.dp, vertical = 4.dp),
            ) {
                Text(
                    text = "—",
                    style = TextStyle(
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = palette.secondaryText.provider(),
                    ),
                )
            }
            return
        }

        val isDown = delta < 0
        val tint = if (isDown) Color(0xFF4CAF50) else Color(0xFFFF9800)
        Row(
            modifier = GlanceModifier
                .wrapContentWidth()
                .roundedBackground(tint.copy(alpha = 0.14f).compositeOver(palette.surface), RoundedShape.Pill)
                .padding(horizontal = 9.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Image(
                provider = ImageProvider(
                    if (isDown) R.drawable.ic_widget_arrow_down else R.drawable.ic_widget_arrow_up,
                ),
                contentDescription = null,
                colorFilter = ColorFilter.tint(tint.provider()),
                modifier = GlanceModifier.size(9.dp),
            )
            Spacer(GlanceModifier.width(5.dp))
            Text(
                text = "${StatsFormat.decimal1(abs(delta))} $unit".trim(),
                maxLines = 1,
                style = TextStyle(
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = tint.provider(),
                ),
            )
        }
    }

    /**
     * Nothing recorded in the configured window — a normal thing to happen on a
     * 7-day view, so the card offers the way out rather than sulking.
     */
    @Composable
    private fun EmptyBody(palette: StatsPalette) {
        val context = LocalContext.current
        Column(
            modifier = GlanceModifier
                .fillMaxWidth()
                .roundedBackground(palette.secondarySurface, RoundedShape.Pill)
                .padding(12.dp),
        ) {
            Text(
                text = context.getString(R.string.widget_measurements_empty_body),
                maxLines = 2,
                style = TextStyle(fontSize = 12.sp, color = palette.secondaryText.provider()),
            )
            Spacer(GlanceModifier.height(9.dp))
            StatsActionPill(
                label = context.getString(R.string.widget_measurements_empty_cta),
                deepLink = WidgetDeepLinks.action(QuickAction.AddMeasurement.key),
                palette = palette,
            )
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

class MeasurementsWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MeasurementsWidget()
}
