package com.rfivesix.trainlibre.widgets.charts

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Paint
import android.graphics.Typeface
import android.util.TypedValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb

/**
 * Shared plumbing for the chart renderers.
 *
 * Glance compiles to RemoteViews, which means no Canvas, no Shape and no Gauge —
 * everything the iOS widgets draw with SwiftUI primitives has to arrive as a
 * bitmap instead. These renderers are that bitmap.
 */
internal class ChartCanvas(private val context: Context) {

    private val metrics = context.resources.displayMetrics

    /** Design units are dp, exactly as the SwiftUI sources spell them in points. */
    fun dp(value: Float): Float = value * metrics.density

    /**
     * Text scales with the user's font size setting, the way it does in the app
     * and in the iOS widgets. Charts here are laid out with slack for that.
     *
     * `TypedValue` rather than `scaledDensity`, which is deprecated because it
     * cannot express the non-linear font scaling introduced in Android 14 — at
     * large accessibility sizes the two disagree.
     */
    fun sp(value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, value, metrics)

    fun textPaint(sizeSp: Float, color: Color, bold: Boolean = false): Paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = sp(sizeSp)
            this.color = color.toArgb()
            typeface = Typeface.create(
                Typeface.DEFAULT,
                if (bold) Typeface.BOLD else Typeface.NORMAL,
            )
        }

    fun fillPaint(color: Color): Paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            this.color = color.toArgb()
        }

    fun strokePaint(color: Color, widthDp: Float): Paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = dp(widthDp)
            strokeCap = Paint.Cap.ROUND
            this.color = color.toArgb()
        }
}

/**
 * Allocates the backing bitmap for a chart, downscaled if it would be too large.
 *
 * A Glance `Image` travels to the launcher inside a RemoteViews parcel, and an
 * oversized bitmap does not degrade — it takes the whole update down. A widget
 * can be resized to whatever the launcher's grid allows and a 3× density phone
 * turns a modest dp size into a lot of pixels, so the ceiling belongs here
 * rather than in each caller.
 *
 * The aspect ratio is preserved and the ImageView scales the result back up;
 * these are flat shapes and a thin line, so the interpolation is not visible.
 */
internal fun chartBitmapSize(widthPx: Int, heightPx: Int): Pair<Int, Int> {
    val width = widthPx.coerceAtLeast(1)
    val height = heightPx.coerceAtLeast(1)
    val pixels = width.toLong() * height.toLong()
    if (pixels <= MAX_CHART_PIXELS) return width to height
    val scale = kotlin.math.sqrt(MAX_CHART_PIXELS.toDouble() / pixels.toDouble())
    return (width * scale).toInt().coerceAtLeast(1) to (height * scale).toInt().coerceAtLeast(1)
}

internal fun createChartBitmap(widthPx: Int, heightPx: Int): Bitmap {
    val (width, height) = chartBitmapSize(widthPx, heightPx)
    return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
}

/** 600k pixels is 2.4 MB at ARGB_8888 — roomy for a 4×2 chart, modest for a parcel. */
private const val MAX_CHART_PIXELS = 600_000L
