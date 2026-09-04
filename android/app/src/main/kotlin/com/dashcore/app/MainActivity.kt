package com.dashcore.app

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.os.PowerManager
import android.provider.Settings
import android.view.KeyEvent

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "io.dashcore.app/launcher"
    private val PERSISTENCE_CHANNEL = "io.dashcore.app/persistence"
    private var screenOnReceiver: BroadcastReceiver? = null
    private var screenOffReceiver: BroadcastReceiver? = null
    private var musicBroadcastReceiver: BroadcastReceiver? = null
    
    private var mediaSessionManager: MediaSessionManager? = null
    private var activeControllers = mutableListOf<MediaController>()
    private var primaryController: MediaController? = null
    
    private val mediaCallback = object : MediaController.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadata?) {
            updateMediaMetadata(metadata)
        }
        override fun onPlaybackStateChanged(state: PlaybackState?) {
            updatePlaybackState(state)
        }
    }

    private val sessionsChangedListener = MediaSessionManager.OnActiveSessionsChangedListener { controllers ->
        updateActiveSessions(controllers)
    }

    override fun onResume() {
        super.onResume()
        refreshMediaSessions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Launcher & Media Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
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
                "mediaControl" -> {
                    val command = call.argument<String>("command")
                    sendMediaCommand(command)
                    result.success(true)
                }
                "checkNotificationAccess" -> {
                    result.success(isNotificationAccessGranted())
                }
                "openNotificationAccessSettings" -> {
                    openNotificationAccessSettings()
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
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
                "refreshMediaSession" -> {
                    refreshMediaSessions()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Persistence Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERSISTENCE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    startPersistenceService()
                    result.success(true)
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
                "checkNotificationAccess" -> {
                    result.success(isNotificationAccessGranted())
                }
                "openNotificationAccessSettings" -> {
                    openNotificationAccessSettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        setupScreenOnReceiver(flutterEngine)
        setupScreenOffReceiver(flutterEngine)
        setupMediaSessionListener(flutterEngine)
        setupMusicBroadcastReceiver(flutterEngine)
    }

    private fun startPersistenceService() {
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

    private fun isNotificationAccessGranted(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (flat != null && flat.isNotEmpty()) {
            val names = flat.split(":")
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && cn.packageName == packageName) {
                    return true
                }
            }
        }
        return false
    }

    private fun openNotificationAccessSettings() {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            } else {
                Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
            }
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback
            startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }

    private fun setupScreenOnReceiver(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERSISTENCE_CHANNEL)
        screenOnReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                channel.invokeMethod("onScreenWakeup", null)
            }
        }
        val filter = IntentFilter().apply {
            addAction("com.dashcore.app.SCREEN_ON")
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
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
                channel.invokeMethod("onScreenSleep", null)
            }
        }
        val filter = IntentFilter().apply {
            addAction("com.dashcore.app.SCREEN_OFF")
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

    private fun setupMusicBroadcastReceiver(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.dashcore.app/media_updates")
        musicBroadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // MediaSession is authoritative when notification access exists.
                if (primaryController != null) return
                val action = intent.action ?: return
                val artist = intent.getStringExtra("artist") ?: intent.getStringExtra("me.aallam.fluttermusic.ARTIST")
                val track = intent.getStringExtra("track") ?: intent.getStringExtra("title") ?: intent.getStringExtra("me.aallam.fluttermusic.TITLE")
                val album = intent.getStringExtra("album") ?: ""
                val isPlaying = intent.getBooleanExtra("playing", false)
                    || intent.getBooleanExtra("isplaying", false)
                    || action.contains("playstatechanged")
                    || action.contains("START_STATE")

                if (track != null || artist != null) {
                    val data = mapOf(
                        "title" to (track ?: "Desconocido"),
                        "artist" to (artist ?: "Artista Desconocido"),
                        "album" to album,
                        "artwork" to null
                    )
                    channel.invokeMethod("onMetadataChanged", data)
                    channel.invokeMethod("onPlaybackStateChanged", mapOf(
                        "isPlaying" to isPlaying,
                        "position" to intent.getLongExtra("position", 0L),
                        "duration" to intent.getLongExtra("duration", 0L)
                    ))
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction("com.android.music.metachanged")
            addAction("com.android.music.playstatechanged")
            addAction("com.android.music.playbackcomplete")
            addAction("com.android.music.queuechanged")
            addAction("com.spotify.music.metadatachanged")
            addAction("com.spotify.music.playbackstatechanged")
            addAction("com.google.android.music.metachanged")
            addAction("com.htc.music.metachanged")
            addAction("com.miui.player.metachanged")
            addAction("com.real.IMP.metachanged")
            addAction("fm.last.android.metachanged")
            addAction("com.amazon.mp3.metachanged")
            addAction("com.samsung.sec.android.MusicPlayer.metachanged")
            addAction("com.samsung.sec.android.MusicPlayer.playstatechanged")
            addAction("com.musixmatch.android.lyrify.metadatachanged")
            addAction("com.rdio.android.metadatachanged")
            addAction("com.rdio.android.playstatechanged")
            addAction("com.andrew.apollo.metachanged")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(musicBroadcastReceiver, filter, RECEIVER_EXPORTED)
        } else {
            registerReceiver(musicBroadcastReceiver, filter)
        }
    }

    private fun setupMediaSessionListener(flutterEngine: FlutterEngine) {
        mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        try {
            val componentName = ComponentName(this, "com.gomes.nowplaying.NowPlayingListenerService")
            mediaSessionManager?.addOnActiveSessionsChangedListener(sessionsChangedListener, componentName)
            updateActiveSessions(mediaSessionManager?.getActiveSessions(componentName))
        } catch (e: SecurityException) {
            android.util.Log.e("MainActivity", "Notification Access not granted for MediaSession")
        }
    }

    private fun refreshMediaSessions() {
        if (mediaSessionManager == null) {
            mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as? MediaSessionManager
        }
        try {
            val componentName = ComponentName(this, "com.gomes.nowplaying.NowPlayingListenerService")
            val sessions = mediaSessionManager?.getActiveSessions(componentName)
            updateActiveSessions(sessions)
        } catch (_: Exception) {}
    }

    private fun updateActiveSessions(controllers: List<MediaController>?) {
        // Unregister from old controllers
        for (controller in activeControllers) {
            try {
                controller.unregisterCallback(mediaCallback)
            } catch (e: Exception) {}
        }
        activeControllers.clear()
        primaryController = null

        controllers?.let {
            activeControllers.addAll(it)
            
            // Prioritize playing session
            primaryController = it.find { c ->
                c.playbackState?.state == PlaybackState.STATE_PLAYING
            } ?: it.firstOrNull()

            primaryController?.let { controller ->
                try {
                    controller.registerCallback(mediaCallback)
                    updateMediaMetadata(controller.metadata)
                    updatePlaybackState(controller.playbackState)
                } catch (_: Exception) {}
            }
        }
    }

    private fun updateMediaMetadata(metadata: MediaMetadata?) {
        if (metadata == null) return
        
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "Desconocido"

        val data = mapOf(
            "title" to title,
            "artist" to "",
            "album" to "",
            "artwork" to null
        )
        
        flutterEngine?.dartExecutor?.binaryMessenger?.let {
            MethodChannel(it, "io.dashcore.app/media_updates").invokeMethod("onMetadataChanged", data)
        }
    }

    private fun updatePlaybackState(state: PlaybackState?) {
        if (state == null) return
        
        val isPlaying = state.state == PlaybackState.STATE_PLAYING
        val position = state.position
        val duration = primaryController?.metadata?.getLong(MediaMetadata.METADATA_KEY_DURATION) ?: 0L

        val data = mapOf(
            "isPlaying" to isPlaying,
            "position" to position,
            "duration" to duration
        )
        
        flutterEngine?.dartExecutor?.binaryMessenger?.let {
            MethodChannel(it, "io.dashcore.app/media_updates").invokeMethod("onPlaybackStateChanged", data)
        }
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
        super.onDestroy()
        screenOnReceiver?.let { unregisterReceiver(it) }
        screenOffReceiver?.let { unregisterReceiver(it) }
        musicBroadcastReceiver?.let { unregisterReceiver(it) }
        mediaSessionManager?.removeOnActiveSessionsChangedListener(sessionsChangedListener)
    }

    private fun sendMediaCommand(command: String?) {
        primaryController?.let { controller ->
            val controls = controller.transportControls
            when (command) {
                "playPause" -> {
                    val state = controller.playbackState
                    if (state != null && state.state == PlaybackState.STATE_PLAYING) {
                        controls.pause()
                    } else {
                        controls.play()
                    }
                }
                "next" -> controls.skipToNext()
                "previous" -> controls.skipToPrevious()
            }
            return
        }

        // Always also dispatch via AudioManager & Intent as fallback for automotive radios/headunits
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val eventTime = System.currentTimeMillis()
        val keyCode = when (command) {
            "playPause" -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
            "previous" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            else -> return
        }

        val downEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, keyCode, 0)
        val upEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, keyCode, 0)
        am.dispatchMediaKeyEvent(downEvent)
        am.dispatchMediaKeyEvent(upEvent)

        try {
            val mediaDown = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                putExtra(Intent.EXTRA_KEY_EVENT, downEvent)
            }
            sendOrderedBroadcast(mediaDown, null)
            val mediaUp = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                putExtra(Intent.EXTRA_KEY_EVENT, upEvent)
            }
            sendOrderedBroadcast(mediaUp, null)
        } catch (_: Exception) {}
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
