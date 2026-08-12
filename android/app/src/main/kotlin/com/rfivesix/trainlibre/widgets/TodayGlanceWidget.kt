package com.rfivesix.trainlibre.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.charts.TodayGlanceGridRenderer
import com.rfivesix.trainlibre.widgets.glance.SnapshotWidget
import com.rfivesix.trainlibre.widgets.glance.WidgetConfig
import com.rfivesix.trainlibre.widgets.glance.contentHeight
import com.rfivesix.trainlibre.widgets.glance.contentWidth
import com.rfivesix.trainlibre.widgets.glance.openOnTap
import com.rfivesix.trainlibre.widgets.glance.toPx
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetDay
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSlot
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSnapshot
import com.rfivesix.trainlibre.widgets.theme.StatsPalette
import com.rfivesix.trainlibre.widgets.theme.provider
import com.rfivesix.trainlibre.widgets.theme.statsWidgetContainer

/**
 * The diary's "Heute im Blick" grid.
 *
 * Port of `TodayGlanceWidget` in
 * `ios/TrainLibreLiveActivity/TodayGlanceWidget.swift`. The six bars are a
 * bitmap — see [TodayGlanceGridRenderer] for why — and the footer line below
 * them is composed, so it stays readable at any font scale.
 */
class TodayGlanceWidget : SnapshotWidget() {

    /** Room for the footer line, which only some states show. */
    private val footerHeight = 16.dp

    @Composable
    override fun Content(snapshot: HomeWidgetSnapshot?) {
        val context = LocalContext.current
        val palette = StatsPalette.of(context)
        val prefs = currentState<Preferences>()

        val resolved = resolve(snapshot, prefs)
        val tiles = HomeWidgetSlot.defaultOrder.map { slot ->
            resolved?.tiles?.firstOrNull { it.slot == slot }
        }

        // Nothing logged yet for the day being shown — distinct from "no snapshot
        // at all": here the targets are known and worth showing, so the grid
        // stays and only gains a line explaining why every bar is empty.
        val isUntouchedDay = resolved != null &&
            resolved.tiles.isNotEmpty() &&
            resolved.tiles.all { it.value == 0.0 }
        val footer = when {
            resolved == null -> context.getString(R.string.widget_today_glance_empty_no_data)
            isUntouchedDay -> context.getString(R.string.widget_today_glance_empty_no_entries)
            else -> null
        }

        val gridWidth = contentWidth()
        val gridHeight = (contentHeight() - if (footer != null) footerHeight + 6.dp else 0.dp)
            .coerceAtLeast(48.dp)

        Column(
            modifier = GlanceModifier
                .statsWidgetContainer(palette)
                .openOnTap(WidgetDeepLinks.DIARY),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Image(
                provider = ImageProvider(
                    TodayGlanceGridRenderer.render(
                        context = context,
                        tiles = tiles,
                        palette = palette,
                        widthPx = gridWidth.toPx(),
                        heightPx = gridHeight.toPx(),
                    ),
                ),
                contentDescription = null,
                contentScale = ContentScale.Fit,
                modifier = GlanceModifier.fillMaxWidth().height(gridHeight),
            )
            if (footer != null) {
                Spacer(GlanceModifier.height(6.dp))
                Text(
                    text = footer,
                    maxLines = 1,
                    style = TextStyle(
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Medium,
                        color = palette.secondaryText.provider(),
                    ),
                )
            }
        }
    }

    /**
     * A snapshot written for a different day is not stale data to be shown — it
     * is a day that has ended. Nothing can have been logged for the new day
     * without the app running, so zero against the last known targets is the
     * correct answer, not a guess.
     */
    private fun resolve(snapshot: HomeWidgetSnapshot?, prefs: Preferences): HomeWidgetSnapshot? {
        if (snapshot == null) return null
        val hour = WidgetConfig.rolloverHour(prefs, snapshot)
        val today = HomeWidgetDay.dayKey(System.currentTimeMillis(), hour)
        return if (snapshot.logicalDayKey == today) snapshot else snapshot.zeroed(today)
    }
}

class TodayGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TodayGlanceWidget()
}
