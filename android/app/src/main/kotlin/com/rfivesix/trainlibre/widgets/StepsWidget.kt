package com.rfivesix.trainlibre.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
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
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.charts.StepsBarChartRenderer
import com.rfivesix.trainlibre.widgets.glance.SnapshotWidget
import com.rfivesix.trainlibre.widgets.glance.contentHeight
import com.rfivesix.trainlibre.widgets.glance.contentWidth
import com.rfivesix.trainlibre.widgets.glance.openOnTap
import com.rfivesix.trainlibre.widgets.glance.toPx
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSnapshot
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSteps
import com.rfivesix.trainlibre.widgets.theme.RoundedShape
import com.rfivesix.trainlibre.widgets.theme.StatsFormat
import com.rfivesix.trainlibre.widgets.theme.StatsHeader
import com.rfivesix.trainlibre.widgets.theme.StatsPalette
import com.rfivesix.trainlibre.widgets.theme.StatsTheme
import com.rfivesix.trainlibre.widgets.theme.provider
import com.rfivesix.trainlibre.widgets.theme.roundedBackground
import com.rfivesix.trainlibre.widgets.theme.statsWidgetContainer
import kotlin.math.roundToInt

/**
 * The seven-day steps card.
 *
 * Port of `StepsWidget` in `ios/TrainLibreLiveActivity/StepsWidget.swift`. The
 * chart itself arrives as a bitmap from [StepsBarChartRenderer]; everything
 * around it is composed.
 */
class StepsWidget : SnapshotWidget() {

    /**
     * The card's column split, from the design document. The count is the
     * headline of this widget and gets its share before the chart does.
     */
    private val totalsWidthShare = 0.38f

    /**
     * Below this the chart is not worth drawing at all.
     *
     * iOS pins the plot to a fixed 92pt row because a `.systemMedium` widget is
     * always the same size. Here the user can resize freely, so the chart takes
     * whatever the header leaves it and only refuses to go under this.
     */
    private val minChartHeight = 60.dp

    @Composable
    override fun Content(snapshot: HomeWidgetSnapshot?) {
        val context = LocalContext.current
        val palette = StatsPalette.of(context)
        val steps = snapshot?.steps
        val hasAccess = steps?.isTrackingEnabled == true

        Column(
            modifier = GlanceModifier
                .statsWidgetContainer(palette)
                .openOnTap(WidgetDeepLinks.STEPS),
        ) {
            StatsHeader(
                title = context.getString(R.string.widget_steps_name),
                palette = palette,
                chip = if (hasAccess) context.getString(R.string.widget_steps_chip) else null,
            )
            Spacer(GlanceModifier.height(8.dp))

            if (steps != null && hasAccess) {
                Chart(steps, palette)
            } else {
                PermissionBody(palette)
            }
        }
    }

    @Composable
    private fun Chart(steps: HomeWidgetSteps, palette: StatsPalette) {
        val context = LocalContext.current
        val available = contentWidth()
        val totalsWidth = available * totalsWidthShare
        val chartWidth = (available - totalsWidth - StatsTheme.rowSpacing).coerceAtLeast(0.dp)
        val chartHeight = (contentHeight() - StatsTheme.headerHeight - 8.dp)
            .coerceAtLeast(minChartHeight)

        Row(
            modifier = GlanceModifier.fillMaxWidth().height(chartHeight),
            verticalAlignment = Alignment.Bottom,
        ) {
            Column(modifier = GlanceModifier.width(totalsWidth)) {
                Text(
                    text = StatsFormat.grouped(steps.todaySteps),
                    maxLines = 1,
                    style = StatsTheme.bigNumberStyle.copy(color = palette.accent.provider()),
                )
                Spacer(GlanceModifier.height(4.dp))
                Text(
                    text = subtitle(steps),
                    maxLines = 1,
                    style = TextStyle(
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        color = palette.accent.provider(),
                    ),
                )
            }
            Spacer(GlanceModifier.width(StatsTheme.rowSpacing))
            Image(
                provider = ImageProvider(
                    StepsBarChartRenderer.render(
                        context = context,
                        steps = steps,
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
     * The share of the goal when there is one, and a plain "Today" otherwise — a
     * percentage of nothing would be a worse label than no percentage.
     */
    @Composable
    private fun subtitle(steps: HomeWidgetSteps): String {
        val context = LocalContext.current
        if (steps.dailyGoal <= 0) return context.getString(R.string.widget_steps_today)
        val percent = (steps.todaySteps.toDouble() / steps.dailyGoal * 100).roundToInt()
        return context.getString(R.string.widget_steps_percent_of_goal, percent)
    }

    /**
     * Step tracking is off, or Health Connect access was never granted. The
     * widget cannot ask for it — only the app can — so it says where to.
     */
    @Composable
    private fun PermissionBody(palette: StatsPalette) {
        val context = LocalContext.current
        Column(modifier = GlanceModifier.fillMaxWidth()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = GlanceModifier
                        .size(44.dp)
                        .roundedBackground(palette.secondarySurface, RoundedShape.Tile),
                    contentAlignment = Alignment.Center,
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_widget_locked),
                        contentDescription = null,
                        colorFilter = androidx.glance.ColorFilter.tint(palette.accent.provider()),
                        modifier = GlanceModifier.size(20.dp),
                    )
                }
                Spacer(GlanceModifier.width(12.dp))
                Column(modifier = GlanceModifier.defaultWeight()) {
                    Text(
                        text = context.getString(R.string.widget_steps_no_access_title),
                        maxLines = 1,
                        style = TextStyle(
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                            color = palette.onSurface.provider(),
                        ),
                    )
                    Spacer(GlanceModifier.height(3.dp))
                    Text(
                        text = context.getString(R.string.widget_steps_no_access_body),
                        maxLines = 2,
                        style = TextStyle(fontSize = 12.sp, color = palette.secondaryText.provider()),
                    )
                }
            }
            Spacer(GlanceModifier.height(10.dp))
            Box(
                modifier = GlanceModifier
                    .roundedBackground(palette.chipBackground, RoundedShape.Pill)
                    .padding(horizontal = 11.dp, vertical = 5.dp),
            ) {
                Text(
                    text = context.getString(R.string.widget_steps_no_access_cta),
                    maxLines = 1,
                    style = TextStyle(
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = palette.accent.provider(),
                    ),
                )
            }
        }
    }
}

class StepsWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = StepsWidget()
}
