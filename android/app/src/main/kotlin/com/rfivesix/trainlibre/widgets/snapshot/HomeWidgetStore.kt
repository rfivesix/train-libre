package com.rfivesix.trainlibre.widgets.snapshot

import android.content.Context
import java.io.File

/**
 * Where the app and its home screen widgets meet.
 *
 * iOS needs an App Group for this because the widget runs in a separate
 * extension process with its own container; on Android the widget receiver is
 * part of the same app, so the app's own `filesDir` is already shared ground and
 * the whole App Group apparatus falls away. What stays is the shape:
 * one JSON snapshot the app is the sole writer of, plus binary assets next to it.
 */
object HomeWidgetStore {
    private const val DIRECTORY = "home_widgets"
    private const val SNAPSHOT_FILE = "snapshot.json"

    private fun directory(context: Context): File =
        File(context.filesDir, DIRECTORY).apply { mkdirs() }

    private fun snapshotFile(context: Context): File = File(directory(context), SNAPSHOT_FILE)

    /**
     * The stored snapshot, or null when the app has never written one or the
     * stored bytes no longer decode.
     */
    fun load(context: Context): HomeWidgetSnapshot? {
        val file = snapshotFile(context)
        if (!file.exists()) return null
        return try {
            HomeWidgetSnapshot.decodeOrNull(file.readText())
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Stores [json] after checking that it decodes.
     *
     * A snapshot the widget cannot read is worse than no snapshot, because it
     * would silently freeze the last good render — same reasoning as the iOS
     * bridge. Written through a temp file so a widget reading concurrently never
     * sees a half-written payload.
     */
    fun writeSnapshot(context: Context, json: String): Boolean {
        if (HomeWidgetSnapshot.decodeOrNull(json) == null) return false
        return try {
            val target = snapshotFile(context)
            val temp = File(target.parentFile, "$SNAPSHOT_FILE.tmp")
            temp.writeText(json)
            if (!temp.renameTo(target)) {
                target.writeText(json)
                temp.delete()
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    fun clearSnapshot(context: Context): Boolean = try {
        val file = snapshotFile(context)
        if (file.exists()) file.delete() else true
    } catch (_: Exception) {
        false
    }

    /**
     * Resolves a shared asset by name.
     *
     * Defends the directory against a name that tries to escape it. The app is
     * the only writer, but the widget is the one that would pay for a bug.
     */
    fun sharedFile(context: Context, name: String): File? {
        if (name.isEmpty() || name.contains('/') || name == ".." || name == ".") return null
        return File(directory(context), name)
    }

    fun sharedFileExists(context: Context, name: String): Boolean =
        sharedFile(context, name)?.exists() == true

    /**
     * Stores a binary asset — today only the muscle heatmap.
     *
     * Kept out of the JSON: a PNG has no business in a payload the widget parses
     * on every render.
     */
    fun writeSharedFile(context: Context, name: String, bytes: ByteArray): Boolean {
        val file = sharedFile(context, name) ?: return false
        return try {
            val temp = File(file.parentFile, "${file.name}.tmp")
            temp.writeBytes(bytes)
            if (!temp.renameTo(file)) {
                file.writeBytes(bytes)
                temp.delete()
            }
            sweepSiblings(file)
            true
        } catch (_: Exception) {
            false
        }
    }

    /** A delete — the app uses it when a workout is removed and its heatmap must not outlive it. */
    fun deleteSharedFile(context: Context, name: String): Boolean {
        val file = sharedFile(context, name) ?: return false
        return try {
            if (file.exists()) file.delete() else true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Removes older files sharing the new file's prefix.
     *
     * Heatmaps are named per workout so a snapshot can never point at the wrong
     * session's map. The cost of that is that every finished workout would leave
     * a file behind, so the newest write clears the ones it superseded.
     */
    private fun sweepSiblings(file: File) {
        val name = file.name
        val separator = name.lastIndexOf('_')
        if (separator < 0) return
        val prefix = name.substring(0, separator + 1)
        if (prefix.isEmpty()) return
        val entries = file.parentFile?.listFiles() ?: return
        for (entry in entries) {
            if (entry.name.startsWith(prefix) && entry.name != name) {
                entry.delete()
            }
        }
    }
}
