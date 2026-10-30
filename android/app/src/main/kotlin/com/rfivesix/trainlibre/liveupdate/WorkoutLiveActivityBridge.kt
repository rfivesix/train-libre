package com.rfivesix.trainlibre.liveupdate

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel between the Flutter app and the workout live update.
 *
 * Answers the same six methods the iOS ActivityKit bridge does, so
 * `lib/features/workout/data/live_activity/workout_live_activity_service.dart`
 * needs no knowledge of which platform it is talking to.
 */
class WorkoutLiveActivityBridge(private val context: Context) {

    companion object {
        const val CHANNEL_NAME = "trainlibre.workout/live_activity"
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(true)
            "start" -> start(call, result)
            "update" -> update(call, result)
            "end" -> {
                WorkoutLiveUpdate.hide(context)
                WorkoutLiveStore.clear(context)
                result.success(null)
            }
            "scheduleRestSound" -> {
                val args = call.arguments as? Map<*, *>
                val end = (args?.get("endsAtEpochMs") as? Number)?.toLong()
                if (end != null) {
                    RestTimerSound.setTexts(context, args["title"] as? String ?: "", args["body"] as? String ?: "")
                    RestTimerSound.schedule(context, end, args["ignoreSilentMode"] as? Boolean ?: true)
                }
                result.success(null)
            }
            "cancelRestSound" -> {
                RestTimerSound.cancel(context)
                result.success(null)
            }
            "setRestIgnoreSilentMode" -> {
                val args = call.arguments as? Map<*, *>
                RestTimerSound.setIgnoreSilent(context, args?.get("enabled") as? Boolean ?: true)
                result.success(null)
            }
            "setRestNotificationsEnabled" -> {
                val args = call.arguments as? Map<*, *>
                RestTimerSound.setAlertEnabled(context, args?.get("enabled") as? Boolean ?: true)
                result.success(null)
            }
            "consumePendingCommands" -> result.success(WorkoutLiveStore.consumeCommands(context))
            else -> result.notImplemented()
        }
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        val map = call.arguments as? Map<String, Any?>
        if (map == null) {
            result.success(null)
            return
        }
        // Attributes and content arrive merged in one map, the way the Dart side
        // spreads them.
        val attributes = WorkoutLiveAttributes.fromMap(map)
        val content = WorkoutLiveContent.fromMap(map)
        WorkoutLiveStore.save(context, attributes, content)
        WorkoutLiveUpdate.show(context, attributes, content)
        result.success(null)
    }

    private fun update(call: MethodCall, result: MethodChannel.Result) {
        val map = call.arguments as? Map<String, Any?>
        val attributes = WorkoutLiveStore.attributes(context)
        if (map == null || attributes == null) {
            // An update without a start is not something to recover from by
            // inventing attributes — the workout title and the labels only ever
            // come from the app.
            result.success(null)
            return
        }
        val content = WorkoutLiveContent.fromMap(map)
        WorkoutLiveStore.saveContent(context, content)
        WorkoutLiveUpdate.show(context, attributes, content)
        result.success(null)
    }
}
