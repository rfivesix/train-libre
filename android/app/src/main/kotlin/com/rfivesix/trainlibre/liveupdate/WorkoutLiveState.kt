package com.rfivesix.trainlibre.liveupdate

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Static data for the lifetime of one workout.
 *
 * Mirrors `WorkoutLiveActivityAttributes` in
 * `lib/features/workout/domain/live_activity/workout_live_activity_content.dart`.
 * The labels arrive already localized, because the app owns the translations and
 * this side has no business having a second copy of them.
 */
data class WorkoutLiveAttributes(
    val workoutTitle: String,
    val workoutStartedAtEpochMs: Long,
    val deepLink: String,
    val workoutLogId: Int,
    val labelAddExercise: String,
    val labelOpenApp: String,
    val labelSkip: String,
    val labelOverdue: String,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("workoutTitle", workoutTitle)
        put("workoutStartedAtEpochMs", workoutStartedAtEpochMs)
        put("deepLink", deepLink)
        put("workoutLogId", workoutLogId)
        put("labelAddExercise", labelAddExercise)
        put("labelOpenApp", labelOpenApp)
        put("labelSkip", labelSkip)
        put("labelOverdue", labelOverdue)
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): WorkoutLiveAttributes = WorkoutLiveAttributes(
            workoutTitle = map["workoutTitle"] as? String ?: "",
            workoutStartedAtEpochMs = (map["workoutStartedAtEpochMs"] as? Number)?.toLong() ?: 0L,
            deepLink = map["deepLink"] as? String ?: "trainlibre://workout/live",
            workoutLogId = (map["workoutLogId"] as? Number)?.toInt() ?: 0,
            labelAddExercise = map["labelAddExercise"] as? String ?: "",
            labelOpenApp = map["labelOpenApp"] as? String ?: "",
            labelSkip = map["labelSkip"] as? String ?: "",
            labelOverdue = map["labelOverdue"] as? String ?: "",
        )

        fun fromJson(json: JSONObject): WorkoutLiveAttributes = WorkoutLiveAttributes(
            workoutTitle = json.optString("workoutTitle"),
            workoutStartedAtEpochMs = json.optLong("workoutStartedAtEpochMs"),
            deepLink = json.optString("deepLink", "trainlibre://workout/live"),
            workoutLogId = json.optInt("workoutLogId"),
            labelAddExercise = json.optString("labelAddExercise"),
            labelOpenApp = json.optString("labelOpenApp"),
            labelSkip = json.optString("labelSkip"),
            labelOverdue = json.optString("labelOverdue"),
        )
    }
}

/**
 * Whether a preformatted metric actually carries a value.
 *
 * A digit or letter means there is something to read; an en dash, a lone `×` or
 * whitespace is the app saying "not entered yet".
 */
private fun String.hasMetricValue(): Boolean = any { it.isLetterOrDigit() }

/** The five states of the workout live update. */
enum class WorkoutPhase(val wireName: String) {
    SetPending("setPending"),
    Resting("resting"),
    NoSetsLeft("noSetsLeft"),
    Empty("empty");

    companion object {
        fun fromWire(name: String?): WorkoutPhase =
            entries.firstOrNull { it.wireName == name } ?: Empty
    }
}

/**
 * Everything that changes during the workout.
 *
 * Mirrors `WorkoutLiveActivityContent`. Every string arrives pre-formatted, and
 * no field changes every second — the rest countdown is a pair of timestamps so
 * the notification's own chronometer can run it without an update being pushed.
 */
data class WorkoutLiveContent(
    val phase: WorkoutPhase,
    val restEndsAtEpochMs: Long?,
    val restStartedAtEpochMs: Long?,
    val exerciseName: String,
    val setPosition: String,
    val badgeText: String,
    val badgeColorHex: String,
    val metricPrimary: String,
    val metricSecondary: String,
    val metricTertiary: String,
    val metricSeparator: String,
    val compactPrimary: String,
    val compactSecondary: String,
    val canCompleteSet: Boolean,
) {
    /**
     * The metrics line as the card shows it — `80 kg × 8 · RIR 2`.
     *
     * Placeholders are dropped rather than printed. The app fills a weight or
     * rep count it does not have yet with an en dash (`_unknownValue` in
     * `build_workout_live_activity_content.dart`); on the iOS card that reads as
     * "not entered yet" inside a full layout, but in a single notification line
     * it comes out as "– × –", which says nothing at all.
     */
    val metricsLine: String
        get() {
            val head = listOf(metricPrimary, metricSecondary)
                .filter { it.hasMetricValue() }
                .joinToString(" $metricSeparator ")
            return listOf(head, metricTertiary.takeIf { it.hasMetricValue() }.orEmpty())
                .filter { it.isNotEmpty() }
                .joinToString(" · ")
        }

    /** The chip's line, falling back to the set position when no number is known yet. */
    val compactLine: String
        get() {
            val metrics = listOf(compactPrimary, compactSecondary)
                .filter { it.hasMetricValue() }
                .joinToString(" ")
            return metrics.ifEmpty { setPosition }
        }

    fun toJson(): JSONObject = JSONObject().apply {
        put("phase", phase.wireName)
        put("restEndsAtEpochMs", restEndsAtEpochMs ?: JSONObject.NULL)
        put("restStartedAtEpochMs", restStartedAtEpochMs ?: JSONObject.NULL)
        put("exerciseName", exerciseName)
        put("setPosition", setPosition)
        put("badgeText", badgeText)
        put("badgeColorHex", badgeColorHex)
        put("metricPrimary", metricPrimary)
        put("metricSecondary", metricSecondary)
        put("metricTertiary", metricTertiary)
        put("metricSeparator", metricSeparator)
        put("compactPrimary", compactPrimary)
        put("compactSecondary", compactSecondary)
        put("canCompleteSet", canCompleteSet)
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): WorkoutLiveContent = WorkoutLiveContent(
            phase = WorkoutPhase.fromWire(map["phase"] as? String),
            restEndsAtEpochMs = (map["restEndsAtEpochMs"] as? Number)?.toLong(),
            restStartedAtEpochMs = (map["restStartedAtEpochMs"] as? Number)?.toLong(),
            exerciseName = map["exerciseName"] as? String ?: "",
            setPosition = map["setPosition"] as? String ?: "",
            badgeText = map["badgeText"] as? String ?: "",
            badgeColorHex = map["badgeColorHex"] as? String ?: "#8E8E93",
            metricPrimary = map["metricPrimary"] as? String ?: "",
            metricSecondary = map["metricSecondary"] as? String ?: "",
            metricTertiary = map["metricTertiary"] as? String ?: "",
            metricSeparator = map["metricSeparator"] as? String ?: "×",
            compactPrimary = map["compactPrimary"] as? String ?: "",
            compactSecondary = map["compactSecondary"] as? String ?: "",
            canCompleteSet = map["canCompleteSet"] as? Boolean ?: false,
        )

        fun fromJson(json: JSONObject): WorkoutLiveContent = WorkoutLiveContent(
            phase = WorkoutPhase.fromWire(json.optString("phase")),
            restEndsAtEpochMs = json.optLong("restEndsAtEpochMs").takeIf { it > 0 },
            restStartedAtEpochMs = json.optLong("restStartedAtEpochMs").takeIf { it > 0 },
            exerciseName = json.optString("exerciseName"),
            setPosition = json.optString("setPosition"),
            badgeText = json.optString("badgeText"),
            badgeColorHex = json.optString("badgeColorHex", "#8E8E93"),
            metricPrimary = json.optString("metricPrimary"),
            metricSecondary = json.optString("metricSecondary"),
            metricTertiary = json.optString("metricTertiary"),
            metricSeparator = json.optString("metricSeparator", "×"),
            compactPrimary = json.optString("compactPrimary"),
            compactSecondary = json.optString("compactSecondary"),
            canCompleteSet = json.optBoolean("canCompleteSet"),
        )
    }
}

/**
 * The live update's persisted state and the queue its buttons write into.
 *
 * Both have to outlive the app process: a notification action can arrive when
 * Android has long since killed everything, and the receiver still has to be
 * able to redraw the notification and leave a note for the app.
 *
 * On iOS this is an App Group `UserDefaults`; here plain SharedPreferences,
 * since the receiver runs in the app's own process.
 */
object WorkoutLiveStore {
    private const val PREFS = "workout_live_update"
    private const val KEY_ATTRIBUTES = "attributes"
    private const val KEY_CONTENT = "content"
    private const val KEY_COMMANDS = "pending_commands"

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(context: Context, attributes: WorkoutLiveAttributes, content: WorkoutLiveContent) {
        prefs(context).edit()
            .putString(KEY_ATTRIBUTES, attributes.toJson().toString())
            .putString(KEY_CONTENT, content.toJson().toString())
            .apply()
    }

    fun saveContent(context: Context, content: WorkoutLiveContent) {
        prefs(context).edit().putString(KEY_CONTENT, content.toJson().toString()).apply()
    }

    fun attributes(context: Context): WorkoutLiveAttributes? =
        prefs(context).getString(KEY_ATTRIBUTES, null)
            ?.let { runCatching { WorkoutLiveAttributes.fromJson(JSONObject(it)) }.getOrNull() }

    fun content(context: Context): WorkoutLiveContent? =
        prefs(context).getString(KEY_CONTENT, null)
            ?.let { runCatching { WorkoutLiveContent.fromJson(JSONObject(it)) }.getOrNull() }

    fun clear(context: Context) {
        prefs(context).edit()
            .remove(KEY_ATTRIBUTES)
            .remove(KEY_CONTENT)
            .apply()
    }

    /**
     * Appends a command for the app to apply on its next run.
     *
     * Each entry carries an `id`, so the app can drop one it has already applied
     * — the same contract the iOS queue has.
     */
    fun enqueue(context: Context, kind: String, payload: Map<String, Any?> = emptyMap()) {
        val store = prefs(context)
        val queue = runCatching {
            JSONArray(store.getString(KEY_COMMANDS, "[]"))
        }.getOrDefault(JSONArray())

        val entry = JSONObject().apply {
            for ((key, value) in payload) put(key, value)
            put("id", java.util.UUID.randomUUID().toString())
            put("kind", kind)
            put("createdAt", System.currentTimeMillis() / 1000.0)
        }
        queue.put(entry)
        store.edit().putString(KEY_COMMANDS, queue.toString()).apply()
    }

    /** Reads the queue and empties it in one step, so a command cannot be applied twice. */
    fun consumeCommands(context: Context): List<Map<String, Any?>> {
        val store = prefs(context)
        val raw = store.getString(KEY_COMMANDS, "[]") ?: "[]"
        store.edit().remove(KEY_COMMANDS).apply()

        val queue = runCatching { JSONArray(raw) }.getOrNull() ?: return emptyList()
        return (0 until queue.length()).mapNotNull { index ->
            val entry = queue.optJSONObject(index) ?: return@mapNotNull null
            entry.keys().asSequence().associateWith { key ->
                when (val value = entry.get(key)) {
                    JSONObject.NULL -> null
                    else -> value
                }
            }
        }
    }
}
