package com.danibaret014.mathlock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Menerima alarm restart/watchdog dari AppLockService.
 *
 * Receiver dipisah dari service supaya alarm tetap bisa menghidupkan ulang
 * proses yang sudah dimatikan sistem/OEM. Alarm ini tidak dapat melawan
 * force-stop manual (Android membatalkan semua alarm), tetapi membantu pada
 * kasus proses dibunuh oleh low-memory killer atau manajemen baterai OEM.
 */
class ServiceRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val prefs = context.getSharedPreferences(AppLockService.PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(AppLockService.KEY_MASTER_LOCK, false)) {
            Log.d(TAG, "Master lock nonaktif; restart dilewati.")
            return
        }

        Log.d(TAG, "Restart AppLockService dari alarm (${intent?.action ?: "tanpa action"}).")
        try {
            val serviceIntent = Intent(context, AppLockService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            // Android 12+ dapat menolak start FGS dari background. Alarm
            // berikutnya tetap dijadwalkan agar ada kesempatan mencoba lagi.
            Log.e(TAG, "Gagal restart AppLockService", e)
        }

        AppLockService.scheduleWatchdog(context)
    }

    companion object {
        private const val TAG = "ServiceRestartReceiver"
    }
}
