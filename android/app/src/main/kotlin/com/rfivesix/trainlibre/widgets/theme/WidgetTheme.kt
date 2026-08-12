package com.rfivesix.trainlibre.widgets.theme

import android.content.Context
import android.content.res.Configuration
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.text.FontWeight
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

/**
 * The shared skin of the statistics widgets.
 *
 * Tokens come from the design document `Home Screen Widgets.dc.html`, which in
 * turn lifted them from `lib/util/design_constants.dart` — the same source the
 * iOS widgets use (`ios/TrainLibreLiveActivity/StatsWidgetChrome.swift`). The
 * one deliberate deviation the document records: padding drops 16 → 14 and the
 * headline 20 → 18, because the in-app card layout does not fit a 4×2 cell
 * otherwise.
 */
object StatsTheme {
    val padding = 14.dp

    /** `DesignConstants.borderRadiusL`. */
    val pillRadius = 19.dp

    /** The smaller metric tiles of the Last Workout card. */
    val tileRadius = 14.dp
    val cardRadius = 22.dp
    val rowSpacing = 8.dp

    /**
     * The header's fixed height.
     *
     * Fixed rather than measured because the widgets below it render their
     * charts as bitmaps, and a bitmap has to be given a pixel height up front —
     * "whatever is left over" is not something a Glance composition can answer.
     * Sized for the 16sp title plus the chip's padding, with room to spare.
     */
    val headerHeight = 28.dp

    val accentDark = Color(0xFFDDFF00)
    val accentLight = Color(0xFF8B9E00)

    /** `DesignConstants.summaryCardSecondary{Dark,Light}Mode`. */
    val secondarySurfaceDark = Color(0xFF2C2C2E)
    val secondarySurfaceLight = Color(0xFFE4E6EB)

    val titleStyle = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Bold)
    val chipStyle = TextStyle(fontSize = 10.sp, fontWeight = FontWeight.Bold)
    val headlineStyle = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.Bold)
    val bigNumberStyle = TextStyle(fontSize = 34.sp, fontWeight = FontWeight.Bold)
    val overlineStyle = TextStyle(fontSize = 10.sp, fontWeight = FontWeight.Bold)
    val captionStyle = TextStyle(fontSize = 10.sp, fontWeight = FontWeight.Normal)
}

/**
 * Resolves every colour the widgets draw for the current appearance.
 *
 * The iOS counterpart has a third appearance to serve — the tinted home screen,
 * where every hue collapses into one tint — and carries an `isMonochrome` flag
 * through the whole palette for it. Android has no such mode, so that dimension
 * is gone here and light/dark is the whole story.
 *
 * Built from a [Context] rather than composed from `GlanceTheme`, because the
 * chart renderers need the same colours outside any composition.
 */
class StatsPalette(val isDark: Boolean) {

    val accent: Color get() = if (isDark) StatsTheme.accentDark else StatsTheme.accentLight

    /**
     * What is legible *on* the accent — a checkmark inside a filled badge, the
     * label of a filled pill.
     *
     * The two accents are not two shades of one colour: dark mode's `#DDFF00` is
     * near-white in luminance and light mode's `#8B9E00` is a dark olive. So the
     * foreground flips with the scheme rather than staying white, which is what
     * made the goal-met checkmark disappear in dark mode on iOS.
     */
    val onAccent: Color get() = if (isDark) Color.Black else Color.White

    val onSurface: Color get() = if (isDark) Color.White else Color(0xFF1C1C1E)

    val secondaryText: Color
        get() = if (isDark) Color(0xFF9E9EA7) else Color(0xFF6C6C70)

    val secondarySurface: Color
        get() = if (isDark) StatsTheme.secondarySurfaceDark else StatsTheme.secondarySurfaceLight

    /** The widget's own backdrop, behind everything else. */
    val surface: Color get() = if (isDark) Color(0xFF1C1C1E) else Color.White

    /**
     * A translucent wash of the accent — but flattened against the card first.
     *
     * Every widget background is a white shape drawable recoloured by a
     * `ColorFilter`, and a filter cannot make an opaque drawable translucent: a
     * 14 % accent handed to it comes back as a near-solid accent chip with
     * accent-coloured text on top, which is unreadable. Compositing here does
     * the blend the filter cannot, so the drawable is tinted with the colour the
     * user should actually see.
     */
    val chipBackground: Color get() = accent.copy(alpha = 0.14f).compositeOver(surface)

    /** A colour the app computed, or the muted default when it sent none. */
    fun stateColor(hex: String?): Color =
        if (hex == null) secondaryText else parseHexColor(hex)

    /** The readiness pills' border: the state's own hue at the card's alpha. */
    fun stateBorder(hex: String?): Color =
        parseHexColor(hex ?: "#8E8E93")
            .copy(alpha = if (isDark) 0.35f else 0.25f)
            .compositeOver(surface)

    companion object {
        fun of(context: Context): StatsPalette {
            val mode = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK
            return StatsPalette(isDark = mode == Configuration.UI_MODE_NIGHT_YES)
        }
    }
}

/**
 * Parses the `#RRGGBB` strings Dart sends.
 *
 * Falls back to the system grey on anything unparseable, matching the iOS
 * `Color(hexString:)` initialiser — a widget that threw here would take down a
 * render over a colour.
 */
fun parseHexColor(hex: String): Color {
    val trimmed = hex.removePrefix("#")
    val value = trimmed.toLongOrNull(16) ?: 0x8E8E93L
    return when (trimmed.length) {
        8 -> Color(value.toInt())
        else -> Color(0xFF000000L.or(value and 0xFFFFFF).toInt())
    }
}

/** Shorthand for the Glance colour wrapper, which every modifier wants. */
fun Color.provider(): ColorProvider = ColorProvider(this)
