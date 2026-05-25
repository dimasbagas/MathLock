package com.example.mathlockv2

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class AppLockService : Service() {

    private lateinit var executor: ScheduledExecutorService

    /** Last package that a lock screen was shown for */
    private var lastLockedPackage: String = ""
    
    /** State variables for efficient UsageStats querying */
    private var lastEventTime: Long = 0
    private var currentForegroundPackage: String? = null

    private val screenReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                // When screen turns off, clear the last locked package and lock status
                // so that when the user unlocks the phone, the app is locked again.
                lastLockedPackage = ""
                getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                    .putBoolean("is_unlocked", false)
                    .apply()
            }
        }
    }

    companion object {
        const val CHANNEL_ID         = "cobalt_fortress_channel"
        const val NOTIFICATION_ID    = 1001
        const val PREFS_NAME         = "app_lock_prefs"
        const val KEY_LOCKED_APPS    = "locked_apps"        // Set<String> "pkg|name"
        const val KEY_MASTER_LOCK    = "master_lock_enabled"
        const val KEY_DIFFICULTY     = "difficulty_level"
        const val KEY_PENDING_NAME   = "pending_lock_name"
        const val KEY_PENDING_DIFF   = "pending_difficulty"
        const val OWN_PACKAGE        = "com.example.mathlockv2"
        const val POLL_INTERVAL_MS   = 500L
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        
        val filter = android.content.IntentFilter(android.content.Intent.ACTION_SCREEN_OFF)
        registerReceiver(screenReceiver, filter)
        
        executor = Executors.newSingleThreadScheduledExecutor()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        executor.scheduleAtFixedRate(
            ::checkForegroundApp, 0, POLL_INTERVAL_MS, TimeUnit.MILLISECONDS
        )
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        unregisterReceiver(screenReceiver)
        executor.shutdownNow()
        super.onDestroy()
    }

    // ── Core polling logic ───────────────────────────────────────────────────

    private fun checkForegroundApp() {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // Guard: master lock must be active
            if (!prefs.getBoolean(KEY_MASTER_LOCK, false)) {
                return
            }

            // Parse locked apps
            val lockedSet = prefs.getStringSet(KEY_LOCKED_APPS, emptySet()) ?: return
            if (lockedSet.isEmpty()) return

            val lockedMap: Map<String, String> = lockedSet.associate {
                val parts = it.split("|", limit = 2)
                parts[0] to if (parts.size > 1) parts[1] else parts[0]
            }

            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return
            val now = System.currentTimeMillis()
            val startTime = if (lastEventTime == 0L) now - 1000 * 60 * 60 else lastEventTime
            
            val events = usm.queryEvents(startTime, now)
            val event = UsageEvents.Event()
            
            var hasNewEvents = false
            
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                lastEventTime = event.timeStamp
                
                // 1 = ACTIVITY_RESUMED (MOVE_TO_FOREGROUND)
                if (event.eventType == 1) { 
                    currentForegroundPackage = event.packageName
                    hasNewEvents = true
                    processForegroundApp(event.packageName, lockedMap, prefs)
                } 
            }
            
            // If no new events, continuously enforce the state of the last known foreground app
            // to ensure lock screens bypassed by transparent overlays or splash transitions are brought back.
            if (!hasNewEvents && currentForegroundPackage != null) {
                processForegroundApp(currentForegroundPackage!!, lockedMap, prefs)
            }
            
        } catch (e: Exception) {
            android.util.Log.e("AppLockService", "Error in checkForegroundApp: ", e)
        }
    }

    private fun processForegroundApp(foreground: String, lockedMap: Map<String, String>, prefs: SharedPreferences) {
        // Never lock our own app
        if (foreground == OWN_PACKAGE) return

        if (lockedMap.containsKey(foreground)) {
            // Already tracking this app session
            if (foreground == lastLockedPackage) {
                // Check if user authenticated
                if (prefs.getBoolean("is_unlocked", false)) {
                    return
                } else {
                    // App bypassed lock (e.g. splash screen transition), re-trigger!
                    showLockScreen()
                    return
                }
            }

            android.util.Log.d("AppLockService", "Target locked app detected: $foreground. Showing Lock Screen.")
            lastLockedPackage = foreground

            val appName = lockedMap[foreground] ?: foreground
            val difficulty = prefs.getInt(KEY_DIFFICULTY, 1)

            // Setup new lock session
            prefs.edit()
                .putString(KEY_PENDING_NAME, appName)
                .putInt(KEY_PENDING_DIFF, difficulty)
                .putBoolean("is_unlocked", false)
                .apply()

            showLockScreen()
        } else {
            // User navigated away to an UNLOCKED app
            if (lastLockedPackage.isNotEmpty() && lastLockedPackage != foreground) {
                android.util.Log.d("AppLockService", "Navigated away to $foreground, resetting lastLockedPackage.")
                lastLockedPackage = ""
                prefs.edit().putBoolean("is_unlocked", false).apply()
            }
        }
    }

    private fun showLockScreen() {
        android.util.Log.d("AppLockService", "showLockScreen: Launching LockActivity for pending app")
        val intent = Intent(this, MathChallengeActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION
        }
        try {
            // Since we have SYSTEM_ALERT_WINDOW permission, we are exempt from background start restrictions.
            startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.e("AppLockService", "Failed to start LockActivity", e)
        }
    }

    // ── Notification helpers ────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Cobalt Fortress Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "App-lock protection is active"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Cobalt Fortress Aktif")
            .setContentText("Melindungi aplikasi Anda dari akses tidak sah")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
