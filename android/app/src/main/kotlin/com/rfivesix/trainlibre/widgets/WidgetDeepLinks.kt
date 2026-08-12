package com.rfivesix.trainlibre.widgets

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.rfivesix.trainlibre.MainActivity

/**
 * The URLs the home screen widgets emit.
 *
 * Kept in lockstep with `lib/features/home_widgets/home_widget_deep_link.dart`,
 * which parses them, and with the iOS widgets, which build the same strings. A
 * widget tap therefore ends up in exactly the same handler as the in-app button.
 */
object WidgetDeepLinks {
    const val SCHEME = "trainlibre"

    const val DIARY = "trainlibre://diary"
    const val RECOVERY = "trainlibre://analytics/recovery"
    const val STEPS = "trainlibre://steps"
    const val LIVE_WORKOUT = "trainlibre://workout/live"

    fun action(key: String): String = "trainlibre://action/$key"

    fun workoutLog(id: Int): String = "trainlibre://workout/log/$id"

    fun measurements(metricId: String?, periodKey: String?): String {
        val query = buildList {
            if (!metricId.isNullOrEmpty()) add("metric=$metricId")
            if (!periodKey.isNullOrEmpty()) add("period=$periodKey")
        }
        return if (query.isEmpty()) {
            "trainlibre://measurements"
        } else {
            "trainlibre://measurements?${query.joinToString("&")}"
        }
    }
}

/**
 * An intent that opens the app on [deepLink].
 *
 * Explicitly targeted at [MainActivity] rather than left to implicit resolution:
 * a widget tap must never open a chooser, and must never be answerable by
 * another app that happens to claim the scheme.
 *
 * `singleTop` plus `CLEAR_TOP` is what keeps a second tap from stacking another
 * copy of the app on top of the first — the running instance receives the link
 * through `onNewIntent` instead.
 */
fun deepLinkIntent(deepLink: String): Intent =
    Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
        setPackage("com.rfivesix.trainlibre")
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }

/** The same intent, when a [Context] is at hand to name the component exactly. */
fun deepLinkIntent(context: Context, deepLink: String): Intent =
    Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_VIEW
        data = Uri.parse(deepLink)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }
