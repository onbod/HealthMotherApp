package com.example.healthymamaapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "Alarm received! Starting service.")
        val serviceIntent = Intent(context, AlarmForegroundService::class.java)
        val sound = intent.getStringExtra("sound")
        if (sound != null) serviceIntent.putExtra("sound", sound)
        context.startForegroundService(serviceIntent)
    }
} 