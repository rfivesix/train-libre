// android/app/src/main/kotlin/com/rfivesix/trainlibre/media/ImageOpsPlugin.kt

package com.rfivesix.trainlibre.media

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream

/**
 * Scales meal photos down, mirroring `ImageOpsPlugin` on iOS.
 *
 * Without this Android had no downscaler at all: thumbnails were never created
 * and the diary list loaded full-resolution camera photos into memory.
 */
object ImageOpsPlugin {
    const val channelName = "com.trainlibre.app/image_ops"

    private const val logTag = "ImageOps"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "downscale" -> {
                val sourcePath = call.argument<String>("sourcePath")
                val targetPath = call.argument<String>("targetPath")
                if (sourcePath == null || targetPath == null) {
                    result.success(false)
                    return
                }
                val maxSize = call.argument<Double>("maxSize") ?: 1024.0
                val quality = call.argument<Double>("quality") ?: 0.8
                scope.launch {
                    val ok = downscale(sourcePath, targetPath, maxSize, quality)
                    withContext(Dispatchers.Main) { result.success(ok) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun downscale(
        sourcePath: String,
        targetPath: String,
        maxSize: Double,
        quality: Double,
    ): Boolean {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(sourcePath, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return false

            val longestEdge = maxOf(bounds.outWidth, bounds.outHeight)

            // Two stages on purpose: `inSampleSize` only halves, so it gets the
            // bitmap down to roughly the target without ever holding the full
            // 12 MP image in memory, and the exact size follows from there.
            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSizeFor(longestEdge, maxSize)
            }
            val decoded = BitmapFactory.decodeFile(sourcePath, options) ?: return false

            val rotated = applyExifRotation(decoded, sourcePath)
            val scaled = scaleToFit(rotated, maxSize)

            val target = File(targetPath)
            target.parentFile?.mkdirs()
            FileOutputStream(target).use { out ->
                scaled.compress(
                    Bitmap.CompressFormat.JPEG,
                    (quality * 100).toInt().coerceIn(1, 100),
                    out,
                )
            }
            if (scaled !== rotated) scaled.recycle()
            if (rotated !== decoded) rotated.recycle()
            decoded.recycle()
            true
        } catch (e: Throwable) {
            Log.w(logTag, "downscale failed", e)
            false
        }
    }

    private fun sampleSizeFor(longestEdge: Int, maxSize: Double): Int {
        var sample = 1
        while (longestEdge / (sample * 2) >= maxSize) {
            sample *= 2
        }
        return sample
    }

    private fun scaleToFit(bitmap: Bitmap, maxSize: Double): Bitmap {
        val longestEdge = maxOf(bitmap.width, bitmap.height).toDouble()
        if (longestEdge <= maxSize) return bitmap
        val scale = maxSize / longestEdge
        return Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * scale).toInt().coerceAtLeast(1),
            (bitmap.height * scale).toInt().coerceAtLeast(1),
            true,
        )
    }

    /**
     * Camera photos carry their orientation in EXIF, which the re-encode drops.
     * Without this a portrait shot is stored on its side.
     */
    private fun applyExifRotation(bitmap: Bitmap, sourcePath: String): Bitmap {
        val degrees = try {
            when (
                ExifInterface(sourcePath).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL,
                )
            ) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
        } catch (e: Throwable) {
            Log.w(logTag, "exif read failed", e)
            0f
        }
        if (degrees == 0f) return bitmap
        val matrix = Matrix().apply { postRotate(degrees) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }
}
