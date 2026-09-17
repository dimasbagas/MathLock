package com.danibaret014.mathlock

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
    private var isScheduled = false

    /** Last package that a lock screen was shown for */
    private var lastLockedPackage: String = ""
    
    /** State variables for efficient UsageStats querying */
    private var lastEventTime: Long = 0
    private var currentForegroundPackage: String? = null
    
    /** Prevent duplicate lock screens from splash screens (cooldown in ms) */
    private var lastLockScreenTime: Long = 0
    private val LOCK_SCREEN_COOLDOWN_MS = 1000L  // 1 second
    
    /** Prevent fallback from continuously triggering lock for same app */
    private var lastLockAttemptTime: Long = 0
    private val LOCK_ATTEMPT_COOLDOWN_MS = 10000L  // 10 seconds
    
    /** Track when app was closed to prevent delayed lock */
    private var lastAppClosedTime: Long = 0
    private var lastClosedPackage: String = ""
    private val APP_CLOSE_GRACE_PERIOD_MS = 2000L  // 2 seconds

    // ── Intra-session re-lock (M2: progressive cognitive friction) ────────────
    /** package → epoch ms kapan kunci harus muncul lagi di tengah sesi */
    private val relockDeadlines = HashMap<String, Long>()

    /** Menerima deadline re-lock dari MathChallengeActivity lewat result intent */
    private val lockResultReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val pkg = intent?.getStringExtra("package_name") ?: return
            val deadline = intent.getLongExtra(MathChallengeActivity.EXTRA_RELOCK_DEADLINE, -1L)
            if (deadline > 0) {
                relockDeadlines[pkg] = deadline
                android.util.Log.d("AppLockService", "Session deadline armed for $pkg → re-lock at $deadline")
            }
        }
    }

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
        const val KEY_PENDING_PACKAGE = "pending_lock_package"
        const val KEY_SESSION_ID     = "pending_session_id"
        const val OWN_PACKAGE        = "com.danibaret014.mathlock"
        const val POLL_INTERVAL_MS   = 500L
        const val SESSION_LIMIT_MS   = 15 * 60 * 1000L  // M2: re-lock tiap 15 menit pemakaian
        const val ACTION_SESSION_ARM = "com.danibaret014.mathlock.SESSION_ARM"
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

        // M2: terima deadline re-lock intra-session dari MathChallengeActivity
        registerReceiver(lockResultReceiver, android.content.IntentFilter(ACTION_SESSION_ARM))

        executor = Executors.newSingleThreadScheduledExecutor()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Guard against multiple schedulers being created if startService() is called repeatedly
        if (!isScheduled) {
            isScheduled = true
            executor.scheduleAtFixedRate(
                ::checkForegroundApp, 0, POLL_INTERVAL_MS, TimeUnit.MILLISECONDS
            )
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        unregisterReceiver(screenReceiver)
        unregisterReceiver(lockResultReceiver)
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

            // If the last tracked app was removed from the locked list, clear session state
            if (lastLockedPackage.isNotEmpty() && !lockedMap.containsKey(lastLockedPackage)) {
                android.util.Log.d("AppLockService", "App $lastLockedPackage removed from lock list. Clearing session.")
                lastLockedPackage = ""
                currentForegroundPackage = null
                prefs.edit().putBoolean("is_unlocked", false).apply()
            }

            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return
            val now = System.currentTimeMillis()
            val startTime = if (lastEventTime == 0L) now - 1000 * 60 * 60 else lastEventTime
            
            val events = usm.queryEvents(startTime, now)
            val event = UsageEvents.Event()
            
            var latestForegroundPackage: String? = null
            var hasNewEvents = false
            
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                lastEventTime = event.timeStamp
                
                if (event.eventType == 1) { // RESUMED
                    latestForegroundPackage = event.packageName
                    hasNewEvents = true
                } else if (event.eventType == 2) { // PAUSED
                    if (event.packageName == latestForegroundPackage) {
                        latestForegroundPackage = null
                    }
                    hasNewEvents = true
                }
            }

            // Jika Android telat lapor event (umum di MIUI), tanya langsung state saat ini
            val actualForeground = latestForegroundPackage ?: getForegroundPackage(usm)

            if (actualForeground != null) {
                if (latestForegroundPackage == OWN_PACKAGE) {
                    currentForegroundPackage = null
                    // Jika user kembali ke MathLock (MainActivity), reset lastLockedPackage untuk mencegah lock telat.
                    if (lastLockedPackage.isNotEmpty() && MainActivity.isActivityActive) {
                        android.util.Log.d("AppLockService", "User di MathLock (MainActivity). Reset lastLockedPackage ($lastLockedPackage).")
                        lastLockedPackage = ""
                        prefs.edit().putBoolean("is_unlocked", false).apply()
                    }
                } else {
                    currentForegroundPackage = actualForeground
                    processForegroundApp(actualForeground, lockedMap, prefs)
                }
            } else {
                currentForegroundPackage = null
            }

            // ── M2: intra-session re-lock ──────────────────────────────────────
            // Untuk app yang sedang aktif dan sudah di-unlock, kalau timer sesi
            // sudah habis → paksa masuk lock screen lagi (re-lock mid-session).
            val active = currentForegroundPackage
            if (active != null && prefs.getBoolean("is_unlocked", false)) {
                val deadline = relockDeadlines[active]
                if (deadline != null && now >= deadline) {
                    android.util.Log.d("AppLockService", "RE-LOCK intra-session: $active (session limit hit)")
                    relockDeadlines.remove(active)
                    // Mulai siklus lock baru untuk app yang sama → re-challenge
                    lastLockedPackage = ""
                    prefs.edit()
                        .putString(KEY_PENDING_NAME, lockedMap[active] ?: active)
                        .putInt(KEY_PENDING_DIFF, prefs.getInt(KEY_DIFFICULTY, 1))
                        .putString(KEY_PENDING_PACKAGE, active)
                        .putBoolean("is_unlocked", false)
                        .apply()
                    showLockScreen()
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AppLockService", "Error in checkForegroundApp: ", e)
        }
    }

    /**
     * Cara lebih akurat untuk HP Xiaomi: Tanya langsung aplikasi apa yang aktif detik ini.
     */
    private fun getForegroundPackage(usm: UsageStatsManager): String? {
        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 1000 * 10, now)
        if (stats.isNullOrEmpty()) return null
        
        // Cari aplikasi yang waktu pemakaian terakhirnya paling baru
        return stats.maxByOrNull { it.lastTimeUsed }?.packageName
    }

    private fun processForegroundApp(foreground: String, lockedMap: Map<String, String>, prefs: SharedPreferences) {
        // Never lock our own app
        if (foreground == OWN_PACKAGE) return

        if (lockedMap.containsKey(foreground)) {
            // Already tracking this app session
            if (foreground == lastLockedPackage) {
                // Check if user authenticated
                if (prefs.getBoolean("is_unlocked", false)) {
                    return  // User unlock, biarkan main
                } else {
                    // User belum unlock, tapi lock screen SUDAH ditampilkan sebelumnya
                    // Jangan trigger ulang - cukup 1x saja per session
                    android.util.Log.d("AppLockService", "Already locked: $foreground. Skip re-trigger.")
                    return
                }
            }
            android.util.Log.d("AppLockService", "Target locked app detected: $foreground. Showing Lock Screen.")
            lastLockedPackage = foreground
            android.util.Log.d("AppLockService", "Updated lastLockedPackage to: $foreground")

            val appName = lockedMap[foreground] ?: foreground
            val difficulty = prefs.getInt(KEY_DIFFICULTY, 1)

            // Setup new lock session
            prefs.edit()
                .putString(KEY_PENDING_NAME, appName)
                .putInt(KEY_PENDING_DIFF, difficulty)
                .putString(KEY_PENDING_PACKAGE, foreground)
                .putString(KEY_SESSION_ID, "$foreground-${System.currentTimeMillis()}")
                .putBoolean("is_unlocked", false)
                .apply()

            lastLockAttemptTime = System.currentTimeMillis()
            showLockScreen()
        } else {
            // User navigated away to an UNLOCKED app
            if (lastLockedPackage.isNotEmpty() && lastLockedPackage != foreground) {
                android.util.Log.d("AppLockService", "Navigated away to $foreground, resetting lastLockedPackage.")
                lastClosedPackage = lastLockedPackage  // Track which app was closed
                lastAppClosedTime = System.currentTimeMillis()  // Track when it was closed
                lastLockedPackage = ""
                prefs.edit().putBoolean("is_unlocked", false).apply()
            }
        }
    }

    private fun showLockScreen() {
        val now = System.currentTimeMillis()
        // Prevent duplicate lock screens from splash screen transitions or rapid events
        if (now - lastLockScreenTime < LOCK_SCREEN_COOLDOWN_MS) {
            android.util.Log.d("AppLockService", "showLockScreen: Skipped (cooldown active)")
            return
        }
        
        lastLockScreenTime = now
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val appName = prefs.getString(KEY_PENDING_NAME, "Unknown")
        // Log saat showLockScreen dipanggil
        android.util.Log.d("AppLockService", "showLockScreen: Launching LockActivity for target: $appName")
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
            .setSmallIcon(R.mipmap.gambar)
            .setContentIntent(pi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
