package com.example.healthymamaapp

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.PendingIntent
import android.util.Log
import android.media.RingtoneManager
import android.media.Ringtone
import android.net.Uri
import android.app.Activity
import android.widget.Toast

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.healthymamaapp/alarm_service"
    private val SOUND_PICKER_CHANNEL = "com.example.healthymamaapp/sound_picker"
    private val REQUEST_CODE_PICK_SOUND = 9001
    private var soundPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarmService" -> {
                    startAlarmService()
                    result.success(null)
                }
                "stopAlarmService" -> {
                    stopAlarmService()
                    result.success(null)
                }
                "scheduleNativeAlarm" -> {
                    val timestamp = call.argument<Long>("timestamp") ?: return@setMethodCallHandler
                    val sound = call.argument<String>("sound")
                    scheduleNativeAlarm(timestamp, sound)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOUND_PICKER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickAlarmSound" -> {
                    Log.d("SoundPicker", "Received pickAlarmSound from Flutter")
                    Toast.makeText(this, "Sound picker channel called", Toast.LENGTH_SHORT).show()
                    soundPickerResult = result
                    val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
                    intent.putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALL)
                    intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                    intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                    Log.d("SoundPicker", "Launching RingtoneManager.ACTION_RINGTONE_PICKER intent")
                    Toast.makeText(this, "Launching system sound picker", Toast.LENGTH_SHORT).show()
                    startActivityForResult(intent, REQUEST_CODE_PICK_SOUND)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startAlarmService() {
        val intent = Intent(this, AlarmForegroundService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopAlarmService() {
        val intent = Intent(this, AlarmForegroundService::class.java)
        stopService(intent)
    }

    private fun scheduleNativeAlarm(timestamp: Long, sound: String?) {
        Log.d("MainActivity", "Scheduling native alarm for: $timestamp (" + java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(java.util.Date(timestamp)) + ") with sound: $sound")
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        if (sound != null) intent.putExtra("sound", sound)
        val pendingIntent = PendingIntent.getBroadcast(
            this, timestamp.toInt(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            timestamp,
            pendingIntent
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d("SoundPicker", "onActivityResult called: requestCode=$requestCode, resultCode=$resultCode, data=$data")
        Toast.makeText(this, "onActivityResult: $requestCode, $resultCode", Toast.LENGTH_SHORT).show()
        if (requestCode == REQUEST_CODE_PICK_SOUND && soundPickerResult != null) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                val title: String? = if (uri != null) RingtoneManager.getRingtone(this, uri)?.getTitle(this) else "Default Alarm"
                val resultMap = hashMapOf<String, String?>()
                resultMap["uri"] = uri?.toString() ?: ""
                resultMap["title"] = title
                Log.d("SoundPicker", "User picked sound: uri=$uri, title=$title")
                Toast.makeText(this, "Picked sound: $title", Toast.LENGTH_SHORT).show()
                soundPickerResult?.success(resultMap)
            } else {
                Log.d("SoundPicker", "User cancelled sound picker or no data returned")
                Toast.makeText(this, "Sound picker cancelled or no data", Toast.LENGTH_SHORT).show()
                soundPickerResult?.success(null)
            }
            soundPickerResult = null
        }
    }
}
