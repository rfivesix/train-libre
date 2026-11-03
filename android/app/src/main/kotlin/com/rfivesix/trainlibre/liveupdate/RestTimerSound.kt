package com.rfivesix.trainlibre.liveupdate

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.pm.PackageManager
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.rfivesix.trainlibre.R

/** A short timer chime, scheduled independently of the optional banner. */
object RestTimerSound {
    private const val PREFS = "rest_timer_sound"
    private const val IGNORE_SILENT = "ignore_silent"
    private const val SHOW_ALERT = "show_alert"
    private const val TITLE = "title"
    private const val BODY = "body"

    fun setIgnoreSilent(context: Context, enabled: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(IGNORE_SILENT, enabled).apply()
    }

    fun setAlertEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(SHOW_ALERT, enabled).apply()
    }

    fun setTexts(context: Context, title: String, body: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(TITLE, title).putString(BODY, body).apply()
    }

    fun showAlert(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(SHOW_ALERT, true)) return
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val channelId = "live_rest_timer_banner_v1"
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(channelId, "Rest Timer", NotificationManager.IMPORTANCE_HIGH)
        channel.setSound(null, null)
        manager.createNotificationChannel(channel)
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val tap = launch?.let { PendingIntent.getActivity(context, 8801, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE) }
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(prefs.getString(TITLE, ""))
            .setContentText(prefs.getString(BODY, ""))
            .setAutoCancel(true)
            .setContentIntent(tap)
            .setSilent(true)
            .build()
        try { NotificationManagerCompat.from(context).notify(8801, notification) } catch (_: SecurityException) { }
    }
    @Volatile var appVisible = false

    private fun pending(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, 8801, Intent(context, RestTimerSoundReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun schedule(context: Context, endsAt: Long, ignoreSilent: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(IGNORE_SILENT, ignoreSilent).apply()
        val alarms = context.getSystemService(AlarmManager::class.java)
        val operation = pending(context)
        alarms.cancel(operation)
        if (endsAt <= System.currentTimeMillis()) return
        try {
            if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endsAt, operation)
            } else {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endsAt, operation)
            }
        } catch (_: SecurityException) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endsAt, operation)
        }
    }

    fun reschedule(context: Context, endsAt: Long) {
        val ignoreSilent = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(IGNORE_SILENT, true)
        schedule(context, endsAt, ignoreSilent)
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(pending(context))
    }

    fun ignoreSilent(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(IGNORE_SILENT, true)
}

class RestTimerSoundReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // The Flutter timer plays the same sound while the workout is visible.
        if (RestTimerSound.appVisible) return
        RestTimerSound.showAlert(context)
        val ignoreSilent = RestTimerSound.ignoreSilent(context)
        val audio = context.getSystemService(AudioManager::class.java)
        if (!ignoreSilent && audio.ringerMode != AudioManager.RINGER_MODE_NORMAL) return

        val result = goAsync()
        val player = MediaPlayer()
        var finished = false
        fun finish() {
            if (finished) return
            finished = true
            player.release()
            result.finish()
        }
        try {
            player.setAudioAttributes(AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(if (ignoreSilent) AudioAttributes.USAGE_ALARM else AudioAttributes.USAGE_NOTIFICATION)
                .build())
            context.resources.openRawResourceFd(R.raw.rest_timer_done).use { fd ->
                player.setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
            }
            player.setOnCompletionListener { finish() }
            player.setOnErrorListener { _, _, _ -> finish(); true }
            player.prepare()
            player.start() // No audio focus requested: music can keep playing at its volume.
            Handler(Looper.getMainLooper()).postDelayed({ finish() }, 10000)
        } catch (_: Exception) {
            finish()
        }
    }
}
