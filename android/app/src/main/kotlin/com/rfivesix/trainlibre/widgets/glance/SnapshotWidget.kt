package com.rfivesix.trainlibre.widgets.glance

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import com.rfivesix.trainlibre.widgets.deepLinkIntent
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSnapshot
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetStore
import com.rfivesix.trainlibre.widgets.theme.StatsTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Base for the widgets that render the app's snapshot.
 *
 * On iOS each of these is a `TimelineProvider` that reloads the snapshot and
 * hands it to a view. Here the equivalent is one `provideGlance` per widget, and
 * this class holds the part that is identical across all of them: read the
 * snapshot off the disk, roll it over if the diary day has turned since the app
 * last wrote, and compose.
 */
abstract class SnapshotWidget : GlanceAppWidget() {

    /**
     * The charts are bitmaps, so the composition has to know the widget's real
     * size in order to render them at the right resolution. `Exact` is what
     * makes `LocalSize` that real size rather than a bucket.
     *
     * Typed as [SizeMode] rather than left to inference, so a widget that draws
     * no bitmap can override it with `Responsive` — which is the more reliable
     * mode when exact pixels are not needed.
     */
    override val sizeMode: SizeMode = SizeMode.Exact

    /**
     * The snapshot is handed over exactly as the app wrote it.
     *
     * Rolling it over to the current diary day is deliberately not done here:
     * only the Today Glance widget's tiles belong to a day at all, and its
     * rollover hour is a per-instance configuration this class cannot see.
     */
    final override suspend fun provideGlance(context: Context, id: GlanceId) {
        val snapshot = withContext(Dispatchers.IO) { HomeWidgetStore.load(context) }
        provideContent { Content(snapshot) }
    }

    @Composable
    protected abstract fun Content(snapshot: HomeWidgetSnapshot?)
}

/**
 * The drawable area inside the card's padding.
 *
 * `LocalSize` is the widget's outer size; everything laid out inside has the
 * container's padding taken off it already, and a bitmap sized from the outer
 * width would overflow by exactly twice the padding.
 */
@Composable
fun contentWidth(): Dp = (LocalSize.current.width - StatsTheme.padding * 2).coerceAtLeast(0.dp)

@Composable
fun contentHeight(): Dp = (LocalSize.current.height - StatsTheme.padding * 2).coerceAtLeast(0.dp)

/** Dp to whole pixels, for sizing a bitmap the composition will draw at [this]. */
@Composable
fun Dp.toPx(): Int =
    (value * LocalContext.current.resources.displayMetrics.density).toInt().coerceAtLeast(1)

/** Opens the app on [deepLink] when the widget is tapped. */
@Composable
fun GlanceModifier.openOnTap(deepLink: String): GlanceModifier =
    clickable(actionStartActivity(deepLinkIntent(LocalContext.current, deepLink)))
