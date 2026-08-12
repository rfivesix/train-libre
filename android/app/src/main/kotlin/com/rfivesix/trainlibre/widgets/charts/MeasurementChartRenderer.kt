package com.rfivesix.trainlibre.widgets.charts

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Shader
import androidx.compose.ui.graphics.toArgb
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetMeasurementPoint
import com.rfivesix.trainlibre.widgets.theme.StatsPalette

/**
 * The measurement series as a line with a fading fill beneath it.
 *
 * A port of `MeasurementSparkline` in
 * `ios/TrainLibreLiveActivity/MeasurementsWidget.swift`.
 */
object MeasurementChartRenderer {

    /** Vertical breathing room, so the extremes are not clipped by the stroke. */
    private const val INSET_DP = 4f

    fun render(
        context: Context,
        points: List<HomeWidgetMeasurementPoint>,
        palette: StatsPalette,
        widthPx: Int,
        heightPx: Int,
    ): Bitmap {
        val bitmap = createChartBitmap(widthPx, heightPx)
        val canvas = Canvas(bitmap)
        val c = ChartCanvas(context)

        val width = bitmap.width.toFloat()
        val height = bitmap.height.toFloat()
        val positions = positions(points, width, height, c.dp(INSET_DP))

        when {
            positions.size == 1 -> drawSinglePoint(c, canvas, palette, positions[0], width, height)
            positions.size > 1 -> drawSeries(c, canvas, palette, positions, height)
        }
        return bitmap
    }

    /**
     * A single reading has no line to draw. It goes on a dashed baseline so the
     * point still reads as "a value in a range" rather than as a stray dot.
     */
    private fun drawSinglePoint(
        c: ChartCanvas,
        canvas: Canvas,
        palette: StatsPalette,
        position: PointF2,
        width: Float,
        height: Float,
    ) {
        val baseline = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = c.dp(1f)
            color = palette.secondaryText.copy(alpha = 0.25f).toArgb()
            pathEffect = DashPathEffect(floatArrayOf(c.dp(4f), c.dp(4f)), 0f)
        }
        canvas.drawLine(0f, height / 2f, width, height / 2f, baseline)
        canvas.drawCircle(position.x, position.y, c.dp(4.5f), c.fillPaint(palette.accent))
    }

    private fun drawSeries(
        c: ChartCanvas,
        canvas: Canvas,
        palette: StatsPalette,
        positions: List<PointF2>,
        height: Float,
    ) {
        val line = Path().apply {
            moveTo(positions.first().x, positions.first().y)
            for (point in positions.drop(1)) lineTo(point.x, point.y)
        }

        val fill = Path(line).apply {
            lineTo(positions.last().x, height)
            lineTo(positions.first().x, height)
            close()
        }
        canvas.drawPath(
            fill,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                shader = LinearGradient(
                    0f,
                    0f,
                    0f,
                    height,
                    palette.accent.copy(alpha = 0.38f).toArgb(),
                    palette.accent.copy(alpha = 0f).toArgb(),
                    Shader.TileMode.CLAMP,
                )
            },
        )

        canvas.drawPath(
            line,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = c.dp(2.5f)
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
                color = palette.accent.toArgb()
            },
        )

        val last = positions.last()
        canvas.drawCircle(last.x, last.y, c.dp(3f), c.fillPaint(palette.accent))
    }

    /** Maps the series into the box. */
    private fun positions(
        points: List<HomeWidgetMeasurementPoint>,
        width: Float,
        height: Float,
        inset: Float,
    ): List<PointF2> {
        if (points.isEmpty()) return emptyList()
        if (points.size == 1) return listOf(PointF2(width / 2f, height / 2f))

        val plotHeight = (height - inset * 2f).coerceAtLeast(1f)
        val values = points.map { it.value }
        val minValue = values.min()
        val span = values.max() - minValue

        return points.mapIndexed { index, point ->
            val x = width * index / (points.size - 1).toFloat()
            // A perfectly flat series has no span to scale against; centring it
            // beats dividing by zero or pinning it to the floor.
            val ratio = if (span > 0) (point.value - minValue) / span else 0.5
            PointF2(x, inset + plotHeight * (1f - ratio.toFloat()))
        }
    }
}

/** A plain pair; `android.graphics.PointF` is mutable and this never needs to be. */
internal data class PointF2(val x: Float, val y: Float)
