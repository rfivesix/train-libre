package com.rfivesix.trainlibre.widgets

import android.content.Context
import com.rfivesix.trainlibre.widgets.snapshot.HomeWidgetStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * MethodChannel between the Flutter app and the home screen widgets.
 *
 * The app is the only writer. Everything arriving here is already a finished
 * JSON snapshot — this class validates it, stores it and asks the widgets to
 * re-render. Counterpart to `ios/LiveActivity/HomeWidgetBridge.swift`, and it
 * answers the exact same five methods.
 */
class HomeWidgetBridge(private val context: Context) {

    companion object {
        const val CHANNEL_NAME = "trainlibre.widgets/home_screen"
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Unlike iOS, where the widgets are gated to iOS 18, there is no
            // version below which this does nothing — Glance covers the app's
            // whole minSdk range.
            "isSupported" -> result.success(true)
            "writeSnapshot" -> writeSnapshot(call, result)
            "writeSharedFile" -> writeSharedFile(call, result)
            "sharedFileExists" -> {
                val name = call.argument<String>("name").orEmpty()
                result.success(HomeWidgetStore.sharedFileExists(context, name))
            }
            "clearSnapshot" -> {
                val cleared = HomeWidgetStore.clearSnapshot(context)
                refreshThen(result, cleared)
            }
            else -> result.notImplemented()
        }
    }

    private fun writeSnapshot(call: MethodCall, result: MethodChannel.Result) {
        val json = call.argument<String>("json")
        if (json == null) {
            result.success(false)
            return
        }
        // The store decodes before it stores: a snapshot the widget cannot read
        // is worse than no snapshot, because it would silently freeze the last
        // good render.
        val written = HomeWidgetStore.writeSnapshot(context, json)
        if (!written) {
            result.success(false)
            return
        }
        refreshThen(result, true)
    }

    /**
     * Stores a binary asset — today only the muscle heatmap.
     *
     * A null payload is a delete: the app uses it when a workout is removed and
     * its heatmap must not outlive it.
     */
    private fun writeSharedFile(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")
        if (name == null) {
            result.success(false)
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        val ok = if (bytes == null) {
            HomeWidgetStore.deleteSharedFile(context, name)
        } else {
            HomeWidgetStore.writeSharedFile(context, name, bytes)
        }
        if (!ok) {
            result.success(false)
            return
        }
        refreshThen(result, true)
    }

    /**
     * Redraws every widget, then answers the app.
     *
     * The order matters more than it looks. The app's most important write is
     * the one it makes while being backgrounded — that is the moment just before
     * the home screen becomes visible. Answering first and redrawing afterwards
     * loses exactly that update: Android freezes a backgrounded process within
     * moments, and a coroutine still on its way to `updateAll` goes with it.
     * Holding the channel result open keeps the app alive until the widgets have
     * actually been redrawn.
     *
     * Every widget is redrawn rather than guessing which section changed — a
     * snapshot write is already debounced to one per user action, so the saving
     * would buy nothing and the guess could be wrong.
     */
    private fun refreshThen(result: MethodChannel.Result, value: Boolean) {
        scope.launch {
            HomeWidgetRefresher.refreshAll(context)
            withContext(Dispatchers.Main) { result.success(value) }
        }
    }
}
