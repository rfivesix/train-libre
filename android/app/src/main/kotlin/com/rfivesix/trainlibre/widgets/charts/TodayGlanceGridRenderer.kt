package com.rfivesix.trainlibre.widgets.charts

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetTile
import com.rfivesix.trainlibre.widgets.theme.StatsPalette
import com.rfivesix.trainlibre.widgets.theme.parseHexColor
import kotlin.math.pow

/**
 * The six-tile "Heute im Blick" grid.
 *
 * A port of `TodayGlanceGrid` and `TodayGlanceBar` in
 * `ios/TrainLibreLiveActivity/TodayGlanceViews.swift`, which are themselves a
 * port of the app's `GlassProgressBar` — despite that Dart class name there is
 * no blur involved, the bar is a solid card, which is what makes it
 * reproducible outside Flutter at all.
 *
 * Drawn rather than composed because the bar's defining feature is a fill
 * clipped to the progress ratio with the label repeated on top of it. Glance
 * compiles to RemoteViews, which has neither fractional weights nor clipping nor
 * text shadows, so a Glance version would be a different design, not this one.
 */
object TodayGlanceGridRenderer {

    /** `DesignConstants.spacingS`. */
    private const val GRID_SPACING_DP = 8f

    /** `DesignConstants.borderRadiusL`. */
    private const val BAR_RADIUS_DP = 19f

    /** `DesignConstants.spacingM` / `spacingXS`. */
    private const val BAR_PADDING_H_DP = 12f

    private const val LABEL_SP = 13f
    private const val VALUE_SP = 11f

    /**
     * Renders the grid.
     *
     * [tiles] is the grid's reading order per column — left calories, water,
     * extra; right protein, carbs, fat — with nulls for slots the snapshot has
     * no tile for.
     */
    fun render(
        context: Context,
        tiles: List<HomeWidgetTile?>,
        palette: StatsPalette,
        widthPx: Int,
        heightPx: Int,
    ): Bitmap {
        val bitmap = createChartBitmap(widthPx, heightPx)
        val canvas = Canvas(bitmap)
        val c = ChartCanvas(context)

        val spacing = c.dp(GRID_SPACING_DP)
        val columnWidth = (bitmap.width - spacing) / 2f
        val rowHeight = (bitmap.height - spacing * 2f) / 3f

        for (index in 0 until 6) {
            val column = index / 3
            val row = index % 3
            val left = column * (columnWidth + spacing)
            val top = row * (rowHeight + spacing)
            drawBar(
                c = c,
                canvas = canvas,
                tile = tiles.getOrNull(index),
                palette = palette,
                bounds = RectF(left, top, left + columnWidth, top + rowHeight),
            )
        }
        return bitmap
    }

    private fun drawBar(
        c: ChartCanvas,
        canvas: Canvas,
        tile: HomeWidgetTile?,
        palette: StatsPalette,
        bounds: RectF,
    ) {
        val isDark = palette.isDark
        val radius = c.dp(BAR_RADIUS_DP)
        val background = if (isDark) Color(0xFF2E2E2E) else Color.White

        canvas.drawRoundRect(bounds, radius, radius, c.fillPaint(background))

        // Layer 2 — the unfilled state, full width, no shadow.
        drawText(c, canvas, tile, bounds, palette.onSurface, withShadow = false)

        // Layer 3 — the fill and its text, clipped to the progress ratio.
        val progress = tile?.progress ?: 0f
        if (tile != null && progress > 0f) {
            canvas.save()
            val clip = RectF(bounds).apply { right = bounds.left + bounds.width() * progress }
            canvas.clipRect(clip)

            val fill = parseHexColor(tile.colorHex)
            // Clipping a rounded rect to a straight edge still has to keep the
            // bar's own corners, so the fill is drawn as the same round rect.
            canvas.drawRoundRect(bounds, radius, radius, c.fillPaint(fill))

            // `GlassProgressBar`'s readability heuristic: a fill that is light in
            // dark mode (or dark in light mode) gets a scrim, so the shadowed
            // text keeps its contrast against it.
            val isLowContrast = if (isDark) {
                relativeLuminance(tile.colorHex) > 0.5
            } else {
                relativeLuminance(tile.colorHex) < 0.5
            }
            if (isLowContrast || isDark) {
                canvas.drawRoundRect(
                    bounds,
                    radius,
                    radius,
                    Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        shader = LinearGradient(
                            bounds.left,
                            0f,
                            bounds.left + bounds.width() * 0.6f,
                            0f,
                            Color.Black.copy(alpha = if (isDark) 0.2f else 0.1f).toArgb(),
                            Color.Transparent.toArgb(),
                            Shader.TileMode.CLAMP,
                        )
                    },
                )
            }

            drawText(
                c = c,
                canvas = canvas,
                tile = tile,
                bounds = bounds,
                color = if (isDark) Color.White else Color.Black,
                withShadow = true,
            )
            canvas.restore()
        }

        canvas.drawRoundRect(
            bounds,
            radius,
            radius,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = c.dp(0.8f)
                color = if (isDark) {
                    Color.White.copy(alpha = 0.18f).toArgb()
                } else {
                    Color.Black.copy(alpha = 0.08f).toArgb()
                }
            },
        )
    }

    private fun drawText(
        c: ChartCanvas,
        canvas: Canvas,
        tile: HomeWidgetTile?,
        bounds: RectF,
        color: Color,
        withShadow: Boolean,
    ) {
        val labelPaint = c.textPaint(LABEL_SP, color, bold = true)
        val valuePaint = c.textPaint(VALUE_SP, color.copy(alpha = 0.9f))
        if (withShadow) {
            val shadow = Color.Black.copy(alpha = 0.3f).toArgb()
            labelPaint.setShadowLayer(c.dp(1f), 0f, c.dp(1f), shadow)
            valuePaint.setShadowLayer(c.dp(1f), 0f, c.dp(1f), shadow)
        }

        val labelHeight = labelPaint.fontMetrics.let { it.descent - it.ascent }
        val valueHeight = valuePaint.fontMetrics.let { it.descent - it.ascent }
        val gap = c.dp(2f)
        val blockHeight = labelHeight + gap + valueHeight
        val top = bounds.top + (bounds.height() - blockHeight) / 2f
        val left = bounds.left + c.dp(BAR_PADDING_H_DP)
        val maxWidth = bounds.width() - c.dp(BAR_PADDING_H_DP) * 2f

        canvas.drawText(
            ellipsize(tile?.label ?: "—", labelPaint, maxWidth),
            left,
            top - labelPaint.fontMetrics.ascent,
            labelPaint,
        )
        canvas.drawText(
            ellipsize(tile?.valueText ?: "–", valuePaint, maxWidth),
            left,
            top + labelHeight + gap - valuePaint.fontMetrics.ascent,
            valuePaint,
        )
    }

    /**
     * Canvas has no line breaking of its own, and a value that runs past the
     * bar's edge would be clipped mid-digit.
     */
    private fun ellipsize(text: String, paint: Paint, maxWidth: Float): String {
        if (paint.measureText(text) <= maxWidth) return text
        val ellipsis = "…"
        var end = text.length
        while (end > 0 && paint.measureText(text.take(end) + ellipsis) > maxWidth) end--
        return if (end <= 0) ellipsis else text.take(end) + ellipsis
    }
}

/**
 * WCAG relative luminance, matching Flutter's `Color.computeLuminance()`.
 *
 * Only ever compared against 0.5, so parsing the hex directly is enough.
 */
internal fun relativeLuminance(hex: String): Double {
    val trimmed = hex.removePrefix("#")
    val value = trimmed.toLongOrNull(16) ?: 0x8E8E93L

    fun channel(shift: Int): Double {
        val raw = ((value shr shift) and 0xFF).toDouble() / 255.0
        return if (raw <= 0.03928) raw / 12.92 else ((raw + 0.055) / 1.055).pow(2.4)
    }

    return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
}
