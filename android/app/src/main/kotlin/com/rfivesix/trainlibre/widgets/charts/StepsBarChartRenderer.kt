package com.rfivesix.trainlibre.widgets.charts

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import androidx.compose.ui.graphics.toArgb
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetSteps
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetStepsDay
import com.rfivesix.trainlibre.widgets.theme.StatsFormat
import com.rfivesix.trainlibre.widgets.theme.StatsPalette

/**
 * The seven-day steps chart.
 *
 * A port of `StepsBarChart` in `ios/TrainLibreLiveActivity/StepsWidget.swift`,
 * which is itself a port of `StatisticsStepsCard._buildBarChart` — so the same
 * chart now exists three times and the layout constants below are the contract
 * between them.
 */
object StepsBarChartRenderer {

    /** Room above the bars for the goal-met badge. */
    private const val BADGE_HEIGHT_DP = 12f

    /** Room below for the weekday initial. */
    private const val LABEL_HEIGHT_DP = 14f

    /** The gutter the goal's axis label sits in. */
    private const val AXIS_INSET_DP = 34f
    private const val BAR_WIDTH_DP = 14f

    fun render(
        context: Context,
        steps: HomeWidgetSteps,
        palette: StatsPalette,
        widthPx: Int,
        heightPx: Int,
    ): Bitmap {
        val bitmap = createChartBitmap(widthPx, heightPx)
        val canvas = Canvas(bitmap)
        val c = ChartCanvas(context)

        val width = bitmap.width.toFloat()
        val height = bitmap.height.toFloat()
        val badgeHeight = c.dp(BADGE_HEIGHT_DP)
        val labelHeight = c.dp(LABEL_HEIGHT_DP)
        val axisInset = c.dp(AXIS_INSET_DP)
        val plotHeight = (height - badgeHeight - labelHeight).coerceAtLeast(1f)

        val maximum = steps.chartMaximum
        val todayKey = steps.days.lastOrNull()?.dayKey

        if (steps.dailyGoal > 0) {
            val goalRatio = (steps.dailyGoal.toDouble() / maximum).coerceIn(0.0, 1.0).toFloat()
            val goalY = badgeHeight + plotHeight * (1f - goalRatio)
            drawGoalLine(c, canvas, palette, axisInset, width, goalY)
            drawGoalLabel(c, canvas, palette, steps.dailyGoal, goalY)
        }

        val slot = (width - axisInset) / steps.days.size.coerceAtLeast(1)
        steps.days.forEachIndexed { index, day ->
            drawBar(
                c = c,
                canvas = canvas,
                day = day,
                steps = steps,
                palette = palette,
                isToday = day.dayKey == todayKey,
                maximum = maximum,
                centerX = axisInset + slot * (index + 0.5f),
                badgeHeight = badgeHeight,
                plotHeight = plotHeight,
                labelHeight = labelHeight,
            )
        }
        return bitmap
    }

    private fun drawGoalLine(
        c: ChartCanvas,
        canvas: Canvas,
        palette: StatsPalette,
        axisInset: Float,
        width: Float,
        goalY: Float,
    ) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = c.dp(1f)
            color = palette.accent.copy(alpha = 0.4f).toArgb()
            pathEffect = DashPathEffect(floatArrayOf(c.dp(4f), c.dp(4f)), 0f)
        }
        canvas.drawLine(axisInset, goalY, width, goalY, paint)
    }

    private fun drawGoalLabel(
        c: ChartCanvas,
        canvas: Canvas,
        palette: StatsPalette,
        dailyGoal: Int,
        goalY: Float,
    ) {
        val text = StatsFormat.compactAxis(dailyGoal)
        val paint = c.textPaint(10f, palette.secondaryText, bold = true)
        val textWidth = paint.measureText(text)
        val padH = c.dp(4f)
        val padV = c.dp(1f)
        val boxHeight = paint.fontMetrics.let { it.descent - it.ascent } + padV * 2
        // The label straddles the line the way the SwiftUI offset does, but is
        // held inside the top edge so a goal at the very top stays readable.
        val top = (goalY - boxHeight / 2f).coerceAtLeast(0f)

        val box = RectF(0f, top, textWidth + padH * 2, top + boxHeight)
        canvas.drawRoundRect(
            box,
            c.dp(6f),
            c.dp(6f),
            c.fillPaint(palette.secondarySurface.copy(alpha = 0.85f)),
        )
        canvas.drawText(text, padH, top + padV - paint.fontMetrics.ascent, paint)
    }

    private fun drawBar(
        c: ChartCanvas,
        canvas: Canvas,
        day: HomeWidgetStepsDay,
        steps: HomeWidgetSteps,
        palette: StatsPalette,
        isToday: Boolean,
        maximum: Int,
        centerX: Float,
        badgeHeight: Float,
        plotHeight: Float,
        labelHeight: Float,
    ) {
        val ratio = (day.steps.toDouble() / maximum).coerceIn(0.0, 1.0).toFloat()
        val metGoal = steps.dailyGoal > 0 && day.steps >= steps.dailyGoal
        val plotBottom = badgeHeight + plotHeight

        if (metGoal) {
            drawGoalBadge(c, canvas, palette, centerX, badgeHeight)
        }

        if (day.steps <= 0) {
            // A day the phone spent in a drawer is not the same as a day with no
            // data at all: the app draws a flat marker rather than dropping the
            // bar, so the week keeps its seven slots.
            val markerWidth = c.dp(10f)
            val markerHeight = c.dp(4f)
            val rect = RectF(
                centerX - markerWidth / 2f,
                plotBottom - markerHeight,
                centerX + markerWidth / 2f,
                plotBottom,
            )
            canvas.drawRoundRect(
                rect,
                markerHeight / 2f,
                markerHeight / 2f,
                c.fillPaint(palette.secondaryText.copy(alpha = 0.35f)),
            )
        } else {
            val barWidth = c.dp(BAR_WIDTH_DP)
            val barHeight = (plotHeight * ratio).coerceAtLeast(c.dp(4f))
            val rect = RectF(
                centerX - barWidth / 2f,
                plotBottom - barHeight,
                centerX + barWidth / 2f,
                plotBottom,
            )
            canvas.drawRoundRect(rect, c.dp(4f), c.dp(4f), c.fillPaint(palette.accent))
        }

        val label = StatsFormat.dayFromKey(day.dayKey)
            ?.let { StatsFormat.weekdayInitial(it) }
            ?: ""
        val paint = c.textPaint(10f, if (isToday) palette.onSurface else palette.secondaryText, bold = isToday)
        paint.textAlign = Paint.Align.CENTER
        canvas.drawText(label, centerX, plotBottom + labelHeight - paint.fontMetrics.descent, paint)
    }

    /** The accent square with a checkmark that crowns a day that met the goal. */
    private fun drawGoalBadge(
        c: ChartCanvas,
        canvas: Canvas,
        palette: StatsPalette,
        centerX: Float,
        badgeHeight: Float,
    ) {
        val size = c.dp(12f)
        val top = (badgeHeight - size) / 2f
        val rect = RectF(centerX - size / 2f, top, centerX + size / 2f, top + size)
        canvas.drawRoundRect(rect, c.dp(3f), c.dp(3f), c.fillPaint(palette.accent))

        val tick = Path().apply {
            moveTo(rect.left + size * 0.26f, rect.top + size * 0.52f)
            lineTo(rect.left + size * 0.44f, rect.top + size * 0.70f)
            lineTo(rect.left + size * 0.76f, rect.top + size * 0.32f)
        }
        canvas.drawPath(
            tick,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = c.dp(1.6f)
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
                color = palette.onAccent.toArgb()
            },
        )
    }
}
