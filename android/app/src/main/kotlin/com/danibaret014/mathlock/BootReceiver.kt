package com.danibaret014.mathlock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            val prefs = context.getSharedPreferences(AppLockService.PREFS_NAME, Context.MODE_PRIVATE)
            val isMasterLockEnabled = prefs.getBoolean(AppLockService.KEY_MASTER_LOCK, false)
            if (isMasterLockEnabled) {
                val serviceIntent = Intent(context, AppLockService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                android.util.Log.d("BootReceiver", "Boot completed: Started AppLockService.")
            }
        }
    }
}
