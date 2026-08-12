package com.rfivesix.trainlibre.widgets

import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.glance.SnapshotWidget
import com.rfivesix.trainlibre.widgets.glance.contentWidth
import com.rfivesix.trainlibre.widgets.glance.openOnTap
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetLastWorkout
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSnapshot
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetStore
import com.rfivesix.trainlibre.widgets.theme.RoundedShape
import com.rfivesix.trainlibre.widgets.theme.StatsActionPill
import com.rfivesix.trainlibre.widgets.theme.StatsFormat
import com.rfivesix.trainlibre.widgets.theme.StatsOverline
import com.rfivesix.trainlibre.widgets.theme.StatsPalette
import com.rfivesix.trainlibre.widgets.theme.provider
import com.rfivesix.trainlibre.widgets.theme.roundedBackground
import com.rfivesix.trainlibre.widgets.theme.statsWidgetContainer
import kotlin.math.roundToInt

/**
 * The last session's key figures and muscle map.
 *
 * Port of `LastWorkoutWidget` in
 * `ios/TrainLibreLiveActivity/LastWorkoutWidget.swift`, including its two
 * layouts: side by side while the widget is short, and the heatmap given the
 * lower half once it is tall enough to be worth it.
 */
class LastWorkoutWidget : SnapshotWidget() {

    /** The design document's 60 : 40 column split, for the compact layout. */
    private val detailsWidthShare = 0.58f

    /**
     * Above this the widget switches to the stacked layout. iOS gets the
     * decision handed to it as `.systemLarge`; here the widget is freely
     * resizable, so the threshold is a height — roughly where a 4×4 cell starts.
     */
    private val tallLayoutThreshold = 220.dp

    /**
     * The metric row's natural height at its current padding and two-line
     * caption, fixed so it cannot claim the space the heatmap needs.
     */
    private val metricRowHeight = 44.dp

    @Composable
    override fun Content(snapshot: HomeWidgetSnapshot?) {
        val palette = StatsPalette.of(LocalContext.current)
        val workout = snapshot?.lastWorkout

        Column(
            modifier = GlanceModifier
                .statsWidgetContainer(palette)
                .openOnTap(
                    workout?.let { WidgetDeepLinks.workoutLog(it.id) }
                        ?: WidgetDeepLinks.action(QuickAction.StartWorkout.key),
                ),
        ) {
            when {
                workout == null -> EmptyBody(palette)
                LocalSize.current.height >= tallLayoutThreshold -> TallBody(workout, palette)
                else -> CompactBody(workout, palette)
            }
        }
    }

    /** Figures across the top, and the rest of the card given to the muscle map. */
    @Composable
    private fun TallBody(workout: HomeWidgetLastWorkout, palette: StatsPalette) {
        // Sized to its content here, so everything left over belongs to the map.
        Details(workout, palette, titleSize = 24, fillHeight = false)
        Spacer(GlanceModifier.height(12.dp))
        Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Heatmap(workout, palette)
        }
    }

    @Composable
    private fun CompactBody(workout: HomeWidgetLastWorkout, palette: StatsPalette) {
        val available = contentWidth()
        val detailsWidth = available * detailsWidthShare
        val mapWidth = (available - detailsWidth - 12.dp).coerceAtLeast(0.dp)

        Row(modifier = GlanceModifier.fillMaxSize(), verticalAlignment = Alignment.Top) {
            Box(modifier = GlanceModifier.width(detailsWidth).fillMaxHeight()) {
                Details(workout, palette, titleSize = 20, fillHeight = true)
            }
            Spacer(GlanceModifier.width(12.dp))
            Box(
                // fillMaxHeight, not fillMaxSize: the latter would set width to
                // Fill and discard the measured column split a line above.
                modifier = GlanceModifier.width(mapWidth).fillMaxHeight(),
                contentAlignment = Alignment.Center,
            ) {
                Heatmap(workout, palette)
            }
        }
    }

    /**
     * [fillHeight] pushes the metric tiles to the bottom of the card, the way
     * SwiftUI's flexible `Spacer(minLength:)` does in the original.
     */
    @Composable
    private fun Details(
        workout: HomeWidgetLastWorkout,
        palette: StatsPalette,
        titleSize: Int,
        fillHeight: Boolean,
    ) {
        val context = LocalContext.current
        Column(
            modifier = if (fillHeight) {
                GlanceModifier.fillMaxWidth().fillMaxHeight()
            } else {
                GlanceModifier.fillMaxWidth()
            },
        ) {
            StatsOverline(context.getString(R.string.widget_last_workout_name), palette)
            Spacer(GlanceModifier.height(5.dp))
            Text(
                text = workout.title,
                // Two lines then an ellipsis — a long routine name must not be
                // allowed to push the metric tiles out of the card.
                maxLines = 2,
                style = TextStyle(
                    fontSize = titleSize.sp,
                    fontWeight = FontWeight.Bold,
                    color = palette.onSurface.provider(),
                ),
            )
            Spacer(GlanceModifier.height(3.dp))
            Text(
                text = StatsFormat.relativeDateTime(context, workout.completedAtEpochMs.toLong()),
                maxLines = 1,
                style = TextStyle(fontSize = 12.sp, color = palette.secondaryText.provider()),
            )
            if (fillHeight) {
                Spacer(GlanceModifier.defaultWeight())
            } else {
                Spacer(GlanceModifier.height(6.dp))
            }
            Metrics(workout, palette)
        }
    }

    @Composable
    private fun Metrics(workout: HomeWidgetLastWorkout, palette: StatsPalette) {
        val context = LocalContext.current
        Row(modifier = GlanceModifier.fillMaxWidth().height(metricRowHeight)) {
            Metric(
                caption = context.getString(R.string.widget_last_workout_duration),
                value = StatsFormat.duration(workout.durationSeconds),
                palette = palette,
                modifier = GlanceModifier.defaultWeight(),
            )
            Spacer(GlanceModifier.width(6.dp))
            // A calisthenics session has no volume worth printing, so its middle
            // tile counts reps instead of showing a bold zero.
            if (workout.totalVolume != null) {
                Metric(
                    caption = context.getString(
                        R.string.widget_last_workout_volume,
                        workout.volumeUnit,
                    ),
                    value = StatsFormat.grouped(workout.totalVolume.roundToInt()),
                    palette = palette,
                    modifier = GlanceModifier.defaultWeight(),
                )
            } else {
                Metric(
                    caption = context.getString(R.string.widget_last_workout_reps),
                    value = workout.totalReps.toString(),
                    palette = palette,
                    modifier = GlanceModifier.defaultWeight(),
                )
            }
            Spacer(GlanceModifier.width(6.dp))
            Metric(
                caption = context.getString(R.string.widget_last_workout_sets),
                value = workout.totalSets.toString(),
                palette = palette,
                modifier = GlanceModifier.defaultWeight(),
            )
        }
    }

    /** One of the three key figures, in the app's secondary card surface. */
    @Composable
    private fun Metric(
        caption: String,
        value: String,
        palette: StatsPalette,
        modifier: GlanceModifier,
    ) {
        Column(
            modifier = modifier
                .roundedBackground(palette.secondarySurface, RoundedShape.Tile)
                .padding(horizontal = 8.dp, vertical = 7.dp),
        ) {
            Text(
                text = caption.uppercase(),
                maxLines = 1,
                style = TextStyle(
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    color = palette.secondaryText.provider(),
                ),
            )
            Spacer(GlanceModifier.height(4.dp))
            Text(
                text = value,
                maxLines = 1,
                style = TextStyle(
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = palette.onSurface.provider(),
                ),
            )
        }
    }

    /**
     * The front-and-back muscle map the app rendered when the workout was
     * finished.
     *
     * The image is produced in Flutter — `DualBodyHighlighter` and its SVG body
     * models are the app's, and reproducing them here would mean two silhouettes
     * that drift apart on the first anatomy fix. If it is missing (an older
     * workout, or a render that failed), the slot falls back to a mark rather
     * than leaving a hole.
     *
     * Decoded inside the composition on purpose: Glance composes on a worker, the
     * file is a handful of kilobytes, and threading it through the widget's state
     * would buy nothing.
     */
    @Composable
    private fun Heatmap(workout: HomeWidgetLastWorkout, palette: StatsPalette) {
        val context = LocalContext.current
        val bitmap = workout.heatmapImageName
            ?.let { HomeWidgetStore.sharedFile(context, it) }
            ?.takeIf { it.exists() }
            ?.let { runCatching { BitmapFactory.decodeFile(it.path) }.getOrNull() }

        if (bitmap != null) {
            Image(
                provider = ImageProvider(bitmap),
                contentDescription = null,
                contentScale = ContentScale.Fit,
                modifier = GlanceModifier.fillMaxSize().padding(6.dp),
            )
        } else {
            Image(
                provider = ImageProvider(R.drawable.ic_widget_start_workout),
                contentDescription = null,
                colorFilter = ColorFilter.tint(palette.secondaryText.copy(alpha = 0.5f).provider()),
                modifier = GlanceModifier.size(30.dp),
            )
        }
    }

    /** Nothing logged yet. An invitation rather than an apology. */
    @Composable
    private fun EmptyBody(palette: StatsPalette) {
        val context = LocalContext.current
        Column(modifier = GlanceModifier.fillMaxSize()) {
            StatsOverline(context.getString(R.string.widget_last_workout_name), palette)
            Spacer(GlanceModifier.defaultWeight())
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = GlanceModifier
                        .size(52.dp)
                        .roundedBackground(palette.chipBackground, RoundedShape.Tile),
                    contentAlignment = Alignment.Center,
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_widget_start_workout),
                        contentDescription = null,
                        colorFilter = ColorFilter.tint(palette.accent.provider()),
                        modifier = GlanceModifier.size(22.dp),
                    )
                }
                Spacer(GlanceModifier.width(14.dp))
                Text(
                    text = context.getString(R.string.widget_last_workout_empty_title),
                    maxLines = 2,
                    style = TextStyle(
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = palette.onSurface.provider(),
                    ),
                )
            }
            Spacer(GlanceModifier.defaultWeight())
            StatsActionPill(
                label = context.getString(R.string.widget_start_workout),
                deepLink = WidgetDeepLinks.action(QuickAction.StartWorkout.key),
                palette = palette,
            )
        }
    }
}

class LastWorkoutWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = LastWorkoutWidget()
}
