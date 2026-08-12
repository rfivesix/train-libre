package com.rfivesix.trainlibre.widgets.theme

import android.content.Context
import android.text.format.DateUtils
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetTile
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Number and date formatting for the widgets.
 *
 * The device locale is read on every call rather than cached: the widget has no
 * Flutter locale of its own to defer to, so the system's Language & Region
 * setting is the single source of truth for how a German or French user expects
 * a thousands separator to look — and it has to keep tracking a live change to
 * that setting rather than a locale snapshotted at process launch.
 */
object StatsFormat {

    /** Grouped integers (`8,432` / `8.432`), matching `NumberFormat.decimalPattern()`. */
    fun grouped(value: Int): String =
        NumberFormat.getIntegerInstance(Locale.getDefault()).format(value)

    /** `StatisticsStepsCard._compactAxisLabel`, reproduced. */
    fun compactAxis(value: Int): String {
        if (value >= 10000) return "${(value + 500) / 1000}k"
        if (value >= 1000) {
            val truncated = HomeWidgetTile.dartFixed(value / 1000.0, 1)
            return if (truncated.endsWith(".0")) "${truncated.dropLast(2)}k" else "${truncated}k"
        }
        return value.toString()
    }

    /** `1h 14m`, or `42m` for anything under an hour. */
    fun duration(seconds: Int): String {
        val total = maxOf(seconds, 0)
        val hours = total / 3600
        val minutes = (total % 3600) / 60
        if (hours > 0) return "${hours}h ${String.format(Locale.US, "%02d", minutes)}m"
        return "${minutes}m"
    }

    /** One decimal, the same way `toStringAsFixed(1)` does it in the app. */
    fun decimal1(value: Double): String = HomeWidgetTile.dartFixed(value, 1)

    /**
     * "Yesterday, 18:30" close to today, a short date further back.
     *
     * The platform's own wording in the user's language beats anything
     * reimplemented here.
     */
    fun relativeDateTime(context: Context, epochMs: Long): String =
        DateUtils.getRelativeDateTimeString(
            context,
            epochMs,
            DateUtils.MINUTE_IN_MILLIS,
            DateUtils.WEEK_IN_MILLIS,
            DateUtils.FORMAT_ABBREV_RELATIVE,
        ).toString()

    /** A short date without a year — the "vs. 12 Jul" reference of the Measurements widget. */
    fun shortDate(epochMs: Long): String {
        val locale = Locale.getDefault()
        val pattern = android.text.format.DateFormat.getBestDateTimePattern(locale, "ddMMM")
        return SimpleDateFormat(pattern, locale).format(Date(epochMs))
    }

    /**
     * The single upper-case initial under each steps bar — locale aware, so a
     * German calendar reads `D/M/D/D/F/S/S`, not the English `T/W/T/F/S/S/M`.
     */
    fun weekdayInitial(epochMs: Long): String {
        val locale = Locale.getDefault()
        val pattern = android.text.format.DateFormat.getBestDateTimePattern(locale, "EEE")
        val text = SimpleDateFormat(pattern, locale).format(Date(epochMs))
        return text.take(1).uppercase(locale)
    }

    /** Parses the `yyyy-MM-dd` day keys the snapshot carries, in the device's own timezone. */
    fun dayFromKey(key: String): Long? {
        val parts = key.split('-')
        if (parts.size != 3) return null
        val year = parts[0].toIntOrNull() ?: return null
        val month = parts[1].toIntOrNull() ?: return null
        val day = parts[2].toIntOrNull() ?: return null
        return Calendar.getInstance().apply {
            clear()
            set(year, month - 1, day, 12, 0, 0)
        }.timeInMillis
    }
}
