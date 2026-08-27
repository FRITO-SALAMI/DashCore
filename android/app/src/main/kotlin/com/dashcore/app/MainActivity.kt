package com.dashcore.app

import android.content.Context
import android.media.AudioManager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.pm.PackageManager
import android.view.KeyEvent
import android.media.session.MediaSessionManager
import android.media.session.MediaController
import android.content.ComponentName
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "io.dashcore.app/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun sendMediaCommand(command: String?) {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val eventTime = System.currentTimeMillis()
        val keyCode = when (command) {
            "playPause" -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
            "previous" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            else -> return
        }

        // Method 1: AudioManager (Legacy but reliable for many)
        am.dispatchMediaKeyEvent(KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, keyCode, 0))
        am.dispatchMediaKeyEvent(KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, keyCode, 0))

        // Method 2: MediaSession (Modern, requires notification access for full control)
        try {
            val mm = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
            val controllers = mm.getActiveSessions(null)
            if (controllers.isNotEmpty()) {
                for (controller in controllers) {
                    val controls = controller.transportControls
                    when (command) {
                        "playPause" -> {
                            val state = controller.playbackState
                            if (state != null && state.state == android.media.session.PlaybackState.STATE_PLAYING) {
                                controls.pause()
                            } else {
                                controls.play()
                            }
                        }
                        "next" -> controls.skipToNext()
                        "previous" -> controls.skipToPrevious()
                    }
                }
            } else {
                // Fallback to broadcast if no active sessions found via Manager
                val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
                intent.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, keyCode, 0))
                sendOrderedBroadcast(intent, null)
                intent.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, keyCode, 0))
                sendOrderedBroadcast(intent, null)
            }
        } catch (e: Exception) {
            // Fallback to broadcasts on any error (like security exception)
            val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
            intent.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, keyCode, 0))
            sendOrderedBroadcast(intent, null)
            intent.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, keyCode, 0))
            sendOrderedBroadcast(intent, null)
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, String>>()
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        for (packageInfo in packages) {
            if (pm.getLaunchIntentForPackage(packageInfo.packageName) != null) {
                val appName = packageInfo.loadLabel(pm).toString()
                val pkgName = packageInfo.packageName
                
                val appMap = mapOf(
                    "name" to appName,
                    "packageName" to pkgName
                )
                apps.add(appMap)
            }
        }
        return apps.sortedBy { it["name"] }
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
