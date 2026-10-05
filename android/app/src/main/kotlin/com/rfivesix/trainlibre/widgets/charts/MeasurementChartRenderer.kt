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
        isWeight: Boolean = false,
    ): Bitmap {
        val bitmap = createChartBitmap(widthPx, heightPx)
        val canvas = Canvas(bitmap)
        val c = ChartCanvas(context)

        val width = bitmap.width.toFloat()
        val height = bitmap.height.toFloat()

        val shouldSmooth = isWeight && points.size > 1
        val smoothedPoints = if (shouldSmooth) calculateEwma(points) else emptyList()

        val allValues = (points + smoothedPoints).map { it.value }
        val minValue = allValues.minOrNull() ?: 0.0
        val maxValue = allValues.maxOrNull() ?: 0.0
        val span = maxValue - minValue

        val rawPositions = positions(points, width, height, c.dp(INSET_DP), minValue, span)
        val smoothedPositions = if (shouldSmooth) {
            positions(smoothedPoints, width, height, c.dp(INSET_DP), minValue, span)
        } else {
            emptyList()
        }

        when {
            rawPositions.size == 1 -> drawSinglePoint(c, canvas, palette, rawPositions[0], width, height)
            rawPositions.size > 1 -> {
                if (shouldSmooth) {
                    drawDualSeries(c, canvas, palette, rawPositions, smoothedPositions, height)
                } else {
                    drawSeries(c, canvas, palette, rawPositions, height)
                }
            }
        }
        return bitmap
    }

    /** Calculates EWMA smoothing matching alpha = 0.35. */
    private fun calculateEwma(
        source: List<HomeWidgetMeasurementPoint>,
        alpha: Double = 0.35,
    ): List<HomeWidgetMeasurementPoint> {
        if (source.size <= 1) return source
        val sorted = source.sortedBy { it.epochMs }
        val smoothed = ArrayList<HomeWidgetMeasurementPoint>(sorted.size)
        var previous = sorted.first().value

        for (point in sorted) {
            val next = (alpha * point.value) + ((1.0 - alpha) * previous)
            smoothed.add(HomeWidgetMeasurementPoint(point.epochMs, next))
            previous = next
        }
        return smoothed
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

    private fun drawDualSeries(
        c: ChartCanvas,
        canvas: Canvas,
        palette: StatsPalette,
        rawPositions: List<PointF2>,
        smoothedPositions: List<PointF2>,
        height: Float,
    ) {
        // 1. Raw measurements background ghost line (subtle muted grey, no dots)
        val rawLine = Path().apply {
            moveTo(rawPositions.first().x, rawPositions.first().y)
            for (point in rawPositions.drop(1)) lineTo(point.x, point.y)
        }
        canvas.drawPath(
            rawLine,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = c.dp(2.5f)
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
                color = palette.onSurface.copy(alpha = 0.28f).toArgb()
            },
        )

        // 2. Smoothed trend line with gradient fill below
        drawSeries(c, canvas, palette, smoothedPositions, height)
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
        minValue: Double,
        span: Double,
    ): List<PointF2> {
        if (points.isEmpty()) return emptyList()
        if (points.size == 1) return listOf(PointF2(width / 2f, height / 2f))

        val plotHeight = (height - inset * 2f).coerceAtLeast(1f)

        return points.mapIndexed { index, point ->
            val x = width * index / (points.size - 1).toFloat()
            val ratio = if (span > 0) (point.value - minValue) / span else 0.5
            PointF2(x, inset + plotHeight * (1f - ratio.toFloat()))
        }
    }
}

/** A plain pair; `android.graphics.PointF` is mutable and this never needs to be. */
internal data class PointF2(val x: Float, val y: Float)
