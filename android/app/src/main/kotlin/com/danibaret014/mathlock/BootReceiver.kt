package com.danibaret014.mathlock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        val prefs = context.getSharedPreferences(AppLockService.PREFS_NAME, Context.MODE_PRIVATE)
        val isMasterLockEnabled = prefs.getBoolean(AppLockService.KEY_MASTER_LOCK, false)
        if (!isMasterLockEnabled) {
            Log.d(TAG, "Master lock nonaktif; auto-start dilewati ($action).")
            return
        }

        try {
            val serviceIntent = Intent(context, AppLockService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "AppLockService dimulai setelah $action.")
        } catch (e: Exception) {
            Log.e(TAG, "Gagal memulai AppLockService setelah $action", e)
        }

        // Tetap jadwalkan watchdog meskipun start langsung gagal, supaya
        // alarm berikutnya bisa mencoba menghidupkan service lagi.
        AppLockService.scheduleWatchdog(context)
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
