package com.example.healthymamaapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.example.healthymamaapp.R
import android.content.pm.ServiceInfo
import android.util.Log
import android.media.RingtoneManager
import android.media.Ringtone
import android.net.Uri

class AlarmForegroundService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var ringtone: Ringtone? = null
    private val CHANNEL_ID = "medication_alarm_channel"
    private val NOTIFICATION_ID = 1001

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("AlarmForegroundService", "Service started!")
        if (intent?.action == "STOP_ALARM") {
            stopAlarm()
            stopSelf()
            return START_NOT_STICKY
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, createNotification())
        }
        val sound = intent?.getStringExtra("sound") ?: "alarm.mp3"
        playAlarmSound(sound)
        return START_STICKY
    }

    private fun playAlarmSound(sound: String) {
        stopAlarm()
        when {
            sound.startsWith("content://") || sound.startsWith("file://") -> {
                try {
                    mediaPlayer = MediaPlayer().apply {
                        setDataSource(this@AlarmForegroundService, Uri.parse(sound))
                        isLooping = true
                        setOnPreparedListener { start() }
                        prepareAsync()
                    }
                } catch (e: Exception) {
                    Log.e("AlarmForegroundService", "Failed to play URI sound: $sound", e)
                }
            }
            sound == "system_alarm" -> playSystemSound(RingtoneManager.TYPE_ALARM)
            sound == "system_notification" -> playSystemSound(RingtoneManager.TYPE_NOTIFICATION)
            sound == "system_ringtone" -> playSystemSound(RingtoneManager.TYPE_RINGTONE)
            else -> {
                val resId = when (sound) {
                    "alarm.mp3" -> R.raw.alarm
                    "notification.mp3" -> R.raw.notification
                    else -> R.raw.alarm
                }
                mediaPlayer = MediaPlayer.create(this, resId)
                mediaPlayer?.isLooping = true
                mediaPlayer?.start()
            }
        }
    }

    private fun playSystemSound(type: Int) {
        val uri: Uri = RingtoneManager.getDefaultUri(type)
        ringtone = RingtoneManager.getRingtone(this, uri)
        ringtone?.play()
    }

    private fun stopAlarm() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        ringtone?.stop()
        ringtone = null
    }

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotification(): Notification {
        createNotificationChannel()
        val stopIntent = Intent(this, AlarmForegroundService::class.java).apply {
            action = "STOP_ALARM"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Medication Alarm")
            .setContentText("Time to take your medication! Tap to stop alarm.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_media_pause, "Stop Alarm", stopPendingIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Medication Alarm",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Channel for medication alarm foreground service"
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
} 