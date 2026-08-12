package com.rfivesix.trainlibre.widgets.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.wrapContentWidth
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.rfivesix.trainlibre.R
import com.rfivesix.trainlibre.widgets.deepLinkIntent

/**
 * A rounded, tintable background.
 *
 * Glance's own `cornerRadius(Dp)` only takes effect on Android S and above, and
 * squaring off every pill on Android 8–11 is not an acceptable way to render
 * this design. A white rounded-rect drawable tinted at the call site gives the
 * same result on every supported release, and costs one drawable per radius.
 */
fun GlanceModifier.roundedBackground(color: Color, radius: RoundedShape): GlanceModifier =
    background(
        imageProvider = ImageProvider(radius.drawableRes),
        colorFilter = ColorFilter.tint(color.provider()),
    )

/** The shapes the design uses, as tintable drawables. */
enum class RoundedShape(val drawableRes: Int) {
    Card(R.drawable.widget_shape_card),
    Tile(R.drawable.widget_shape_tile),
    Pill(R.drawable.widget_shape_pill),

    /** Same radius as [Pill]; sits *under* one to become its border. */
    PillStroke(R.drawable.widget_shape_pill_stroke),
}

/**
 * The frame, padding and background every statistics widget shares.
 *
 * `appWidgetBackground` is what lets the launcher apply its own corner masking
 * on Android 12+; without it a widget draws into the corners the system is about
 * to round off.
 */
fun GlanceModifier.statsWidgetContainer(palette: StatsPalette): GlanceModifier =
    this
        .fillMaxSize()
        .appWidgetBackground()
        .roundedBackground(palette.surface, RoundedShape.Card)
        .padding(StatsTheme.padding)

/** Title and optional chip — the header every hub card in the app has. */
@Composable
fun StatsHeader(
    title: String,
    palette: StatsPalette,
    chip: String? = null,
) {
    Row(
        modifier = GlanceModifier.fillMaxWidth().height(StatsTheme.headerHeight),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            maxLines = 1,
            style = StatsTheme.titleStyle.copy(color = palette.onSurface.provider()),
            modifier = GlanceModifier.defaultWeight(),
        )
        if (chip != null) {
            // Sized to its content and laid out after the title's weight has been
            // resolved, so it cannot end up as an empty coloured pill the way the
            // first cut of the iOS header did.
            Box(
                modifier = GlanceModifier
                    .wrapContentWidth()
                    .roundedBackground(palette.chipBackground, RoundedShape.Pill)
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = chip,
                    maxLines = 1,
                    style = StatsTheme.chipStyle.copy(color = palette.accent.provider()),
                )
            }
        }
    }
}

/**
 * The overline used where the card has no full-width title — the Last Workout
 * widget, whose title slot belongs to the workout's name.
 */
@Composable
fun StatsOverline(text: String, palette: StatsPalette) {
    Text(
        text = text.uppercase(),
        maxLines = 1,
        style = StatsTheme.overlineStyle.copy(color = palette.secondaryText.provider()),
        modifier = GlanceModifier.fillMaxWidth(),
    )
}

/**
 * The filled call to action of the empty states.
 *
 * Carries its own destination rather than inheriting the card's: the empty states
 * point at an action ("start a workout", "add a value"), not at the screen the
 * rest of the card links to.
 */
@Composable
fun StatsActionPill(
    label: String,
    deepLink: String,
    palette: StatsPalette,
    isFilled: Boolean = true,
) {
    Box(
        modifier = GlanceModifier
            .wrapContentWidth()
            .roundedBackground(
                if (isFilled) palette.accent else palette.chipBackground,
                RoundedShape.Pill,
            )
            .padding(horizontal = 11.dp, vertical = 5.dp)
            .clickable(actionStartActivity(deepLinkIntent(LocalContext.current, deepLink))),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            maxLines = 1,
            style = TextStyle(
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = (if (isFilled) palette.onAccent else palette.accent).provider(),
            ),
        )
    }
}
