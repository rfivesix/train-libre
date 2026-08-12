package com.rfivesix.trainlibre.widgets.snapshot

import java.math.BigDecimal
import java.math.RoundingMode
import java.util.Calendar
import java.util.Locale
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Shared decoder for the snapshot the Flutter app publishes.
 *
 * `ignoreUnknownKeys` is what lets an older build survive a newer app: the Dart
 * side may add a section before the widget knows about it, and a widget that
 * refused to decode would freeze on its last good render instead.
 */
internal val homeWidgetJson: Json = Json {
    ignoreUnknownKeys = true
}

/**
 * Slot identifiers of the diary's "Heute im Blick" grid, in its reading order
 * per column: left = calories, water, extra — right = protein, carbs, fat.
 */
object HomeWidgetSlot {
    const val CALORIES = "calories"
    const val WATER = "water"
    const val EXTRA = "extra"
    const val PROTEIN = "protein"
    const val CARBS = "carbs"
    const val FAT = "fat"

    /** The grid's reading order, used when no configuration has been made yet. */
    val defaultOrder = listOf(CALORIES, PROTEIN, WATER, CARBS, EXTRA, FAT)
}

/**
 * One progress bar in the widget grid.
 *
 * Everything localized or unit-dependent (`label`, `unit`, the already converted
 * `value`) is computed in Dart. The widget only formats numbers.
 */
@Serializable
data class HomeWidgetTile(
    val slot: String,
    val label: String,
    val unit: String,
    val value: Double,
    val target: Double,
    /** `#RRGGBB`, taken from the very same colour the diary bar uses. */
    val colorHex: String,
) {
    val hasTarget: Boolean get() = target > 0

    /** Clamped 0..1, mirroring `GlassProgressBar`'s `rawProgress.clamp(0, 1)`. */
    val progress: Float
        get() = if (!hasTarget) 0f else (value / target).coerceIn(0.0, 1.0).toFloat()

    /**
     * Byte-identical to the Dart side:
     * `'${value.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit'`.
     */
    val valueText: String
        get() {
            val left = dartFixed(value, 1)
            if (!hasTarget) return "$left $unit"
            return "$left / ${dartFixed(target, 0)} $unit"
        }

    fun zeroed(): HomeWidgetTile = copy(value = 0.0)

    companion object {
        /**
         * `Double.toStringAsFixed` from Dart, reproduced exactly.
         *
         * `String.format("%.1f")` is not equivalent: Java formats from the
         * double's *shortest* decimal representation, so it sees 0.15 and rounds
         * up, while Dart rounds the double's true value (0.1499…) down.
         * `BigDecimal(double)` is that true value, and HALF_UP rounds ties away
         * from zero the way Dart does — so 40.25 kg of volume renders as 40.3 in
         * both the app and the widget.
         */
        fun dartFixed(value: Double, digits: Int): String {
            if (value.isNaN() || value.isInfinite()) {
                return String.format(Locale.US, "%.${digits}f", value)
            }
            // BigDecimal has no negative zero, so "-0.0" cannot appear here any
            // more than it does in Dart.
            return BigDecimal(value).setScale(digits, RoundingMode.HALF_UP).toPlainString()
        }
    }
}

// --- Statistics sections (schema v2) ---

/**
 * One readiness pill of the Muscle Readiness widget.
 *
 * Mirrors `RecoverySectionCard._buildReadinessPill`. The count, its share and
 * the colour all arrive precomputed — the widget only lays them out.
 */
@Serializable
data class HomeWidgetRecoveryState(
    /** `recovering` / `ready` / `fresh` — `RecoveryDomainService`'s state keys. */
    val state: String,
    val label: String,
    val count: Int,
    val percent: Int,
    val colorHex: String,
)

@Serializable
data class HomeWidgetRecovery(
    val hasData: Boolean,
    val headline: String,
    /**
     * Absent when the app would have used `colorScheme.outline` — the widget has
     * its own scheme and resolves that itself rather than being handed a colour
     * from the app's theme.
     */
    val headlineColorHex: String? = null,
    val states: List<HomeWidgetRecoveryState> = emptyList(),
)

@Serializable
data class HomeWidgetStepsDay(
    /**
     * `yyyy-MM-dd` in the user's calendar, so "which bar is today" needs no
     * timezone arithmetic in the widget.
     */
    val dayKey: String,
    val steps: Int,
)

@Serializable
data class HomeWidgetSteps(
    /**
     * False when step tracking is off or permission was never granted — the
     * widget then shows that state rather than a chart of zeros.
     */
    val isTrackingEnabled: Boolean,
    val todaySteps: Int,
    val dailyGoal: Int,
    /** Oldest first, seven entries, the last one being today. */
    val days: List<HomeWidgetStepsDay> = emptyList(),
) {
    /**
     * `StatisticsStepsCard`'s scale: the taller of the goal and the best day, so
     * no bar can leave the chart no matter how big a day was.
     */
    val chartMaximum: Int
        get() = maxOf(days.maxOfOrNull { it.steps } ?: 0, maxOf(dailyGoal, 1))
}

@Serializable
data class HomeWidgetMeasurementPoint(
    val epochMs: Double,
    /** Already converted into the user's display unit. */
    val value: Double,
)

/**
 * One selectable metric of the configurable Measurements widget.
 *
 * Carries the whole series rather than a pre-sliced timeframe: the timeframe is a
 * widget configuration the app never sees, so the widget has to be able to answer
 * for any of the five periods on its own.
 */
@Serializable
data class HomeWidgetMeasurementMetric(
    /** The `Measurement.type` key — `weight`, `fat_percent`, `waist`, … */
    val id: String,
    /** Already localized (`l10n.getLocalizedMeasurementName`). */
    val name: String,
    /** Display unit suffix (`kg`, `%`, `cm`). */
    val unit: String,
    /** Oldest first. */
    val points: List<HomeWidgetMeasurementPoint> = emptyList(),
) {
    /**
     * The points inside the last [days], or all of them when [days] is null (the
     * "Max" timeframe).
     */
    fun pointsWithinDays(
        days: Int?,
        nowMs: Long = System.currentTimeMillis(),
    ): List<HomeWidgetMeasurementPoint> {
        if (days == null) return points
        val cutoff = nowMs - days.toLong() * 86_400_000L
        return points.filter { it.epochMs >= cutoff }
    }
}

@Serializable
data class HomeWidgetLastWorkout(
    val id: Int,
    val title: String,
    val completedAtEpochMs: Double,
    val durationSeconds: Int,
    /**
     * Absent for a session without a single weighted set — the widget shows the
     * rep count in that slot instead.
     */
    val totalVolume: Double? = null,
    val volumeUnit: String,
    val totalReps: Int,
    val totalSets: Int,
    /**
     * File name inside the widget container, written by the app when the workout
     * was finished.
     */
    val heatmapImageName: String? = null,
)

/**
 * The full payload the app publishes.
 *
 * Holds aggregate totals and targets only — no food names, no timestamps, no
 * entry level data ever reaches the widget container.
 */
@Serializable
data class HomeWidgetSnapshot(
    val schemaVersion: Int,
    val generatedAtEpochMs: Double,
    /**
     * The diary day these totals belong to, as `yyyy-MM-dd` in the user's local
     * calendar.
     */
    val logicalDayKey: String,
    /**
     * The hour at which the app rolls the diary over to the next day (3).
     * Transmitted rather than hardcoded so the widget cannot drift from
     * `resolveDiaryInitialDate`.
     */
    val rolloverHour: Int,
    val isAiEnabled: Boolean,
    val tiles: List<HomeWidgetTile> = emptyList(),
    // Every section below is optional, and every reader treats a missing one as
    // "nothing to show yet" — that is what lets a v1 payload left over from an
    // older build still decode.
    val recovery: HomeWidgetRecovery? = null,
    val steps: HomeWidgetSteps? = null,
    val measurements: List<HomeWidgetMeasurementMetric> = emptyList(),
    val lastWorkout: HomeWidgetLastWorkout? = null,
) {
    /**
     * The same totals reset to zero but the targets kept, for a day the app has
     * not written a snapshot for yet. This is what makes the 03:00 rollover work
     * while the app is closed: nothing can have been logged for the new day
     * without the app running, so zero is not a guess — it is the answer.
     *
     * Only the diary rolls over. Recovery, steps, measurements and the last
     * workout are not "today's totals" — they carry across the boundary
     * unchanged, and blanking them would be a lie, not a reset.
     */
    fun zeroed(forDayKey: String): HomeWidgetSnapshot =
        copy(logicalDayKey = forDayKey, tiles = tiles.map { it.zeroed() })

    /**
     * The snapshot as the widget should show it *now*.
     *
     * A widget can outlive the app's last write by hours, so if the rollover has
     * passed since then, the stale diary totals are the wrong answer.
     */
    fun resolvedFor(nowMs: Long = System.currentTimeMillis()): HomeWidgetSnapshot {
        val today = HomeWidgetDay.dayKey(nowMs, rolloverHour)
        return if (today == logicalDayKey) this else zeroed(today)
    }

    companion object {
        /** v2 added the four statistics sections. */
        const val CURRENT_SCHEMA_VERSION = 2

        /** The hour at which the diary rolls over. Mirrors `resolveDiaryInitialDate`. */
        const val DIARY_ROLLOVER_HOUR = 3

        /**
         * Returns null rather than throwing: every caller is a widget render that
         * has to draw *something*, and an empty state beats a crash in the
         * launcher's host process.
         */
        fun decodeOrNull(source: String): HomeWidgetSnapshot? = try {
            homeWidgetJson.decodeFromString<HomeWidgetSnapshot>(source)
        } catch (_: Exception) {
            null
        }
    }
}

/**
 * Resolves which diary day a point in time belongs to.
 *
 * The rule lives in Dart (`resolveDiaryInitialDate`): before 03:00 the diary
 * still shows the previous day. `rolloverHour` carries it across, so this stays a
 * single rule with one owner.
 */
object HomeWidgetDay {
    fun dayKey(atMs: Long, rolloverHour: Int): String {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = atMs
            add(Calendar.HOUR_OF_DAY, -rolloverHour)
        }
        return String.format(
            Locale.US,
            "%04d-%02d-%02d",
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }

    /**
     * The next instant at which [dayKey] changes its answer — today's boundary if
     * it is still ahead of us, tomorrow's otherwise.
     */
    fun nextRollover(afterMs: Long, rolloverHour: Int): Long {
        val boundary = Calendar.getInstance().apply {
            timeInMillis = afterMs
            set(Calendar.HOUR_OF_DAY, rolloverHour % 24)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (boundary.timeInMillis > afterMs) return boundary.timeInMillis
        boundary.add(Calendar.DAY_OF_MONTH, 1)
        return boundary.timeInMillis
    }
}
