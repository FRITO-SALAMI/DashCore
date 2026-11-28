package com.dashcore.app

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import android.provider.Settings

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "io.dashcore.app/launcher"
    private val PERSISTENCE_CHANNEL = "io.dashcore.app/persistence"
    private var screenOnReceiver: BroadcastReceiver? = null
    private var screenOffReceiver: BroadcastReceiver? = null
    private var accReceiver: BroadcastReceiver? = null
    private var alertPlayer: MediaPlayer? = null

    override fun onResume() {
        super.onResume()
        // Si la actividad está en primer plano, el usuario está interactuando.
        // Forzamos el despertar si estaba en modo sueño para evitar quedar atrapados.
        getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("acc_sleeping", false)
            .apply()

        flutterEngine?.dartExecutor?.binaryMessenger?.let {
            MethodChannel(it, PERSISTENCE_CHANNEL).invokeMethod("onScreenWakeup", null)
        }

    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LocalVehicleArt.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)

        // Launcher channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWindowBrightness" -> {
                    val value = call.argument<Double>("value") ?: -1.0
                    val attributes = window.attributes
                    attributes.screenBrightness = if (value < 0) -1f else value.coerceIn(0.05, 1.0).toFloat()
                    window.attributes = attributes
                    result.success(true)
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = launchApp(packageName)
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("UNAVAILABLE", "Could not launch $packageName", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null", null)
                    }
                }
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
                }
                "getRenderCapabilities" -> {
                    val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    result.success(mapOf(
                        "lowRam" to manager.isLowRamDevice,
                        "maxHeapMb" to (Runtime.getRuntime().maxMemory() / (1024L * 1024L))
                    ))
                }
                "getPerformanceSnapshot" -> {
                    val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val memory = manager.getProcessMemoryInfo(
                        intArrayOf(android.os.Process.myPid())
                    ).first()
                    result.success(mapOf(
                        "totalPssKb" to memory.totalPss,
                        "javaPssKb" to memory.dalvikPss,
                        "nativePssKb" to memory.nativePss,
                        "graphicsPssKb" to (memory.getMemoryStat("summary.graphics")?.toIntOrNull() ?: 0),
                        "nativeHeapKb" to (Debug.getNativeHeapAllocatedSize() / 1024L),
                        "cpuTimeMs" to android.os.Process.getElapsedCpuTime()
                    ))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.dashcore.app/alert_audio").setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val path = call.argument<String>("path")
                    val loop = call.argument<Boolean>("loop") ?: false
                    if (path.isNullOrBlank()) {
                        result.error("INVALID_PATH", "Alert sound path is empty", null)
                    } else {
                        try {
                            alertPlayer?.release()
                            alertPlayer = MediaPlayer().apply {
                                setDataSource(path)
                                isLooping = loop
                                setAudioStreamType(AudioManager.STREAM_ALARM)
                                prepare()
                                start()
                            }
                            result.success(true)
                        } catch (error: Exception) {
                            alertPlayer?.release()
                            alertPlayer = null
                            result.error("PLAYBACK_ERROR", error.message, null)
                        }
                    }
                }
                "stop" -> {
                    alertPlayer?.run { if (isPlaying) stop(); release() }
                    alertPlayer = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Persistence Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERSISTENCE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterAccBackground" -> {
                    result.success(moveTaskToBack(true))
                }
                "getAccSleeping" -> {
                    result.success(getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE).getBoolean("acc_sleeping", false))
                }
                "setKeepAppActive" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE)
                        .edit()
                        .putBoolean("keep_app_active", enabled)
                        .apply()
                    result.success(true)
                }
                "startService" -> {
                    try {
                        startPersistenceService()
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("SERVICE_UNAVAILABLE", error.message, null)
                    }
                }
                "stopService" -> {
                    stopPersistenceService()
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
                }
                "saveState" -> {
                    val vehicle = call.argument<String>("vehicle")
                    val dashboard = call.argument<String>("dashboard")
                    val connection = call.argument<String>("connection")
                    savePersistenceState(vehicle, dashboard, connection)
                    result.success(true)
                }
                "getSavedState" -> {
                    result.success(getSavedPersistenceState())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        setupScreenOnReceiver(flutterEngine)
        setupScreenOffReceiver(flutterEngine)
        setupAccReceiver(flutterEngine)
    }

    private fun startPersistenceService() {
        val prefs = getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("keep_app_active", false) || prefs.getBoolean("acc_sleeping", false)) return
        val serviceIntent = Intent(this, DashCoreService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopPersistenceService() {
        getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("service_explicitly_stopped", true)
            .apply()
        val serviceIntent = Intent(this, DashCoreService::class.java)
        stopService(serviceIntent)
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback to settings if the direct intent fails
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(intent)
            }
        }
    }

    private fun setupScreenOnReceiver(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERSISTENCE_CHANNEL)
        screenOnReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE).edit().putBoolean("acc_sleeping", false).apply()
                channel.invokeMethod("onScreenWakeup", null)
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction("android.intent.action.QUICKBOOT_POWERON")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenOnReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenOnReceiver, filter)
        }
    }

    private fun setupScreenOffReceiver(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERSISTENCE_CHANNEL)
        screenOffReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE).edit().putBoolean("acc_sleeping", true).apply()
                stopPersistenceService()
                channel.invokeMethod("onScreenSleep", null)
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
            addAction("android.intent.action.QUICKBOOT_POWEROFF")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenOffReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenOffReceiver, filter)
        }
    }

    private fun setupAccReceiver(engine: FlutterEngine) {
        // These actions are sent by MCU services on supported automotive ROMs.
        val off = setOf("android.intent.action.ACC_OFF", "com.microntek.ACC_OFF")
        val on = setOf("android.intent.action.ACC_ON", "com.microntek.ACC_ON")
        accReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val sleeping = when (intent.action) { in off -> true; in on -> false; else -> return }
                getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE).edit().putBoolean("acc_sleeping", sleeping).apply()
                if (sleeping) stopPersistenceService()
                MethodChannel(engine.dartExecutor.binaryMessenger, PERSISTENCE_CHANNEL)
                    .invokeMethod(if (sleeping) "onScreenSleep" else "onScreenWakeup", null)
            }
        }
        val filter = IntentFilter().apply { (off + on).forEach { addAction(it) } }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(accReceiver, filter, RECEIVER_EXPORTED)
        else registerReceiver(accReceiver, filter)
    }

    private fun savePersistenceState(vehicle: String?, dashboard: String?, connection: String?) {
        val prefs = getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("vehicle", vehicle)
            putString("dashboard", dashboard)
            putString("connection", connection)
            apply()
        }
    }

    private fun getSavedPersistenceState(): Map<String, String?> {
        val prefs = getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE)
        return mapOf(
            "vehicle" to prefs.getString("vehicle", null),
            "dashboard" to prefs.getString("dashboard", null),
            "connection" to prefs.getString("connection", null)
        )
    }

    override fun onDestroy() {
        alertPlayer?.release()
        alertPlayer = null
        super.onDestroy()
        screenOnReceiver?.let { unregisterReceiver(it) }
        screenOffReceiver?.let { unregisterReceiver(it) }
        accReceiver?.let { unregisterReceiver(it) }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, String>>()
        val seen = mutableSetOf<String>()

        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
        for (info in resolveInfos) {
            val pkgName = info.activityInfo.packageName
            // Exclude DashCore itself from shortcuts
            if (pkgName != packageName && seen.add(pkgName)) {
                val appName = info.loadLabel(pm).toString()
                apps.add(mapOf(
                    "name" to appName,
                    "packageName" to pkgName
                ))
            }
        }
        return apps.sortedBy { it["name"]?.lowercase() }
    }

    private fun launchApp(packageName: String): Boolean {
        val pm = packageManager
        return try {
            val intent = pm.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }
}
