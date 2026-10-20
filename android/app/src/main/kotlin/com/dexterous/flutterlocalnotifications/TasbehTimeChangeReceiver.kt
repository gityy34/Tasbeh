package com.dexterous.flutterlocalnotifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class TasbehTimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (
            intent.action == Intent.ACTION_TIMEZONE_CHANGED ||
                intent.action == Intent.ACTION_TIME_CHANGED
        ) {
            FlutterLocalNotificationsPlugin.rescheduleNotifications(context)
        }
    }
}
