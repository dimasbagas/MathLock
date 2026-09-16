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
                        result.success(mapOf("appName" to appName, "difficulty" to difficulty))
                    }
                    "dismissLock" -> {
                        prefs.edit().putBoolean("is_unlocked", true).apply()
                        finish()
                        result.success(null)
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
