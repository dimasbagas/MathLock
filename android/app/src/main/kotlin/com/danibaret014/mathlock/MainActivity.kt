package com.danibaret014.mathlock

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.mathlockv2/applock"
        var isActivityActive = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        isActivityActive = true
    }

    override fun onResume() {
        super.onResume()
        isActivityActive = true
    }

    override fun onPause() {
        isActivityActive = false
        super.onPause()
    }

    override fun onDestroy() {
        isActivityActive = false
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(AppLockService.PREFS_NAME, Context.MODE_PRIVATE)
                when (call.method) {

                    // ── Service control ───────────────────────────────────────
                    "startService" -> {
                        prefs.edit().putBoolean(AppLockService.KEY_MASTER_LOCK, true).apply()
                        val intent = Intent(this, AppLockService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }

                    "stopService" -> {
                        prefs.edit().putBoolean(AppLockService.KEY_MASTER_LOCK, false).apply()
                        stopService(Intent(this, AppLockService::class.java))
                        result.success(null)
                    }

                    // ── Update locked-apps list ───────────────────────────────
                    // apps: List<Map<String,String>>  { "package": "...", "name": "..." }
                    // difficulty: Int
                    "updateLockedApps" -> {
                        val apps = call.argument<List<Map<String, Any>>>("apps") ?: emptyList()
                        val appsSet = apps.mapNotNull { 
                            val pkg = it["package"]?.toString()
                            val name = it["name"]?.toString()
                            if (pkg != null) "$pkg|$name" else null
                        }.toSet()
                        val difficulty = call.argument<Int>("difficulty") ?: 1
                        val relockIntervalMinutes = call.argument<Int>("relockIntervalMinutes") ?: 15
                        prefs.edit()
                            .putStringSet(AppLockService.KEY_LOCKED_APPS, appsSet)
                            .putInt(AppLockService.KEY_DIFFICULTY, difficulty)
                            .putInt(AppLockService.KEY_RELOCK_INTERVAL, relockIntervalMinutes)
                            .apply()
                        result.success(null)
                    }

                    "getLockedApps" -> {
                        val lockedSet = prefs.getStringSet(AppLockService.KEY_LOCKED_APPS, emptySet()) ?: emptySet()
                        val packages = lockedSet.map { it.split("|")[0] }
                        result.success(packages)
                    }

                    // ── Permission checks ─────────────────────────────────────
                    "checkUsagePermission"   -> result.success(hasUsageStatsPermission())
                    "checkOverlayPermission" -> result.success(hasOverlayPermission())

                    "requestUsagePermission" -> {
                        startActivity(
                            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                        )
                        result.success(null)
                    }

                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                            )
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── Permission helpers ────────────────────────────────────────────────────

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun hasOverlayPermission(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(this)
        else true
}
