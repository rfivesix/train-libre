package com.rfivesix.trainlibre.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
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
import androidx.glance.unit.ColorProvider
import com.rfivesix.trainlibre.widgets.glance.SnapshotWidget
import com.rfivesix.trainlibre.widgets.glance.WidgetConfig
import com.rfivesix.trainlibre.widgets.glance.openOnTap
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSnapshot
import com.rfivesix.trainlibre.widgets.theme.RoundedShape
import com.rfivesix.trainlibre.widgets.theme.StatsPalette
import com.rfivesix.trainlibre.widgets.theme.roundedBackground

/**
 * The quick access tiles.
 *
 * Port of `QuickActionsWidget` in
 * `ios/TrainLibreLiveActivity/QuickActionsWidget.swift`. iOS ships this as three
 * separate widgets, one per family, because WidgetKit picks the family up front;
 * here one widget covers both layouts and switches on its own measured width.
 */
class QuickActionsWidget : SnapshotWidget() {

    /**
     * The two shapes this widget takes, declared rather than measured.
     *
     * The chart widgets need `SizeMode.Exact`, because a bitmap has to be given a
     * pixel size. Nothing here is a bitmap, so the layout can simply be composed
     * once per declared size and left to the system to pick between — one fewer
     * measurement to get right.
     */
    override val sizeMode = SizeMode.Responsive(
        setOf(DpSize(110.dp, 110.dp), DpSize(250.dp, 110.dp)),
    )

    /** Below this the widget shows a single column of two tiles. */
    private val wideLayoutThreshold = 180.dp

    private val gridSpacing = 8.dp

    @Composable
    override fun Content(snapshot: HomeWidgetSnapshot?) {
        val palette = StatsPalette.of(LocalContext.current)
        val prefs = currentState<Preferences>()
        val isWide = LocalSize.current.width >= wideLayoutThreshold
        val actions = WidgetConfig.quickActions(
            prefs = prefs,
            isAiEnabled = snapshot?.isAiEnabled ?: true,
            count = if (isWide) 4 else 2,
        )

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .appWidgetBackground()
                .roundedBackground(palette.surface, RoundedShape.Card)
                .padding(12.dp),
        ) {
            if (isWide) {
                TileRow(actions.take(2), modifier = GlanceModifier.defaultWeight())
                Spacer(GlanceModifier.height(gridSpacing))
                TileRow(actions.drop(2).take(2), modifier = GlanceModifier.defaultWeight())
            } else {
                actions.forEachIndexed { index, action ->
                    if (index > 0) Spacer(GlanceModifier.height(gridSpacing))
                    Tile(action, modifier = GlanceModifier.fillMaxWidth().defaultWeight())
                }
            }
        }
    }

    @Composable
    private fun TileRow(actions: List<QuickAction>, modifier: GlanceModifier) {
        Row(modifier = modifier.fillMaxWidth()) {
            actions.forEachIndexed { index, action ->
                if (index > 0) Spacer(GlanceModifier.width(gridSpacing))
                Tile(action, modifier = GlanceModifier.fillMaxHeight().defaultWeight())
            }
        }
    }

    /**
     * One action.
     *
     * Sizing belongs entirely to the caller. `defaultWeight()` is axis-specific —
     * it claims width inside a Row and height inside a Column — so a
     * `fillMaxSize()` here would quietly overwrite the row's width weight, hand
     * the whole row to the first tile and squeeze the second to nothing. That is
     * what limited this widget to one tile per row.
     *
     * The AI action carries a gradient on iOS; a Glance background is a tinted
     * drawable and cannot hold one, so it takes the gradient's starting colour.
     * The distinction it carries — "this is the AI one" — survives, the flourish
     * does not.
     */
    @Composable
    private fun Tile(action: QuickAction, modifier: GlanceModifier) {
        val context = LocalContext.current
        Column(
            modifier = modifier
                .roundedBackground(action.tint, RoundedShape.Tile)
                .padding(10.dp)
                .openOnTap(action.deepLink),
            horizontalAlignment = Alignment.Start,
        ) {
            Image(
                provider = ImageProvider(action.iconRes),
                contentDescription = null,
                colorFilter = ColorFilter.tint(ColorProvider(androidx.compose.ui.graphics.Color.White)),
                modifier = GlanceModifier.size(17.dp),
            )
            Spacer(GlanceModifier.defaultWeight())
            Text(
                text = context.getString(action.labelRes),
                maxLines = 2,
                style = TextStyle(
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                ),
            )
        }
    }
}

class QuickActionsWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = QuickActionsWidget()
}
