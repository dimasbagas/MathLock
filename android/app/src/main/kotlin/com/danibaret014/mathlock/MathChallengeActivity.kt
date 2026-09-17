package com.danibaret014.mathlock

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * A dedicated FlutterActivity that renders the math-lock screen.
 *
 * Launched by [AppLockService] whenever a locked app enters the foreground.
 * The back-button is disabled so the user cannot bypass the math challenge.
 * Data for the lock screen (app name, difficulty) is read from SharedPreferences
 * that were written by [AppLockService] just before launching this activity.
 */
class MathChallengeActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.mathlockv2/lock"
        /** package → epoch ms kapan re-lock intra-sesi harus memicu (dibaca AppLockService) */
        const val EXTRA_RELOCK_DEADLINE = "relock_deadline"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots and hide content in recent-apps screen
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    /** Tell Flutter to start at the /lock route so only the lock screen renders. */
    override fun getInitialRoute(): String = "/lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(AppLockService.PREFS_NAME, Context.MODE_PRIVATE)
                when (call.method) {
                    "getLockData" -> {
                        val appName    = prefs.getString(AppLockService.KEY_PENDING_NAME, "App") ?: "App"
                        val difficulty = prefs.getInt(AppLockService.KEY_PENDING_DIFF, 1)
                        result.success(mapOf(
                            "appName"     to appName,
                            "difficulty"  to difficulty,
                            "packageName" to prefs.getString(AppLockService.KEY_PENDING_PACKAGE, "")!!,
                            "sessionId"   to prefs.getString(AppLockService.KEY_SESSION_ID, "")!!
                        ))
                    }
                    "dismissLock" -> {
                        prefs.edit().putBoolean("is_unlocked", true).apply()
                        // M2: mulai timer intra-session — app akan di-re-lock sesuai relock_interval_minutes.
                        val pkg = prefs.getString(AppLockService.KEY_PENDING_PACKAGE, null)
                        if (pkg != null) {
                            val intervalMinutes = prefs.getInt(AppLockService.KEY_RELOCK_INTERVAL, 15)
                            val sessionLimitMs = if (intervalMinutes == 0) 3000L else intervalMinutes * 60 * 1000L
                            val deadline = System.currentTimeMillis() + sessionLimitMs
                            val arm = Intent(AppLockService.ACTION_SESSION_ARM)
                                .setPackage(AppLockService.OWN_PACKAGE)
                                .putExtra("package_name", pkg)
                                .putExtra(EXTRA_RELOCK_DEADLINE, deadline)
                            sendBroadcast(arm)
                            android.util.Log.d("MathChallenge", "Session timer armed for $pkg (re-lock in ${if (intervalMinutes == 0) "3 sec [DEV]" else "$intervalMinutes min"})")
                        }
                        finish()
                        result.success(null)
                    }
                    "recordForcedExit" -> {
                        val pkg = prefs.getString(AppLockService.KEY_PENDING_PACKAGE, "") ?: ""
                        val sessionId = prefs.getString(AppLockService.KEY_SESSION_ID, "") ?: ""
                        result.success(mapOf("packageName" to pkg, "sessionId" to sessionId))
                    }
                    "exitToHome" -> {
                        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(homeIntent)
                        finish()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Block the back button — user must solve the math to dismiss. */
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // intentionally empty
    }
}
