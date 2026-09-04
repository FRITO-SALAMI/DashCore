package com.dashcore.app

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

class DashCoreService : Service() {
    private val TAG = "DashCoreService"
    private val CHANNEL_ID = "DashCorePersistenceChannel"
    private val NOTIFICATION_ID = 101
    private var wakeLock: PowerManager.WakeLock? = null
    private lateinit var screenStateReceiver: BroadcastReceiver

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        createNotificationChannel()
        registerScreenStateReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service onStartCommand")
        getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("service_explicitly_stopped", false)
            .apply()

        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Android head units are externally powered. Keep the process runnable
        // while the user has explicitly enabled a real OBD session.
        acquireWakeLock()

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "DashCore Persistence Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DashCore Activo")
            .setContentText("Manteniendo activa la sesión OBD de DashCore.")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun registerScreenStateReceiver() {
        screenStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_SCREEN_OFF,
                    Intent.ACTION_POWER_DISCONNECTED,
                    "android.intent.action.QUICKBOOT_POWEROFF" -> {
                        Log.d(TAG, "Screen Off/Power Disconnected - keeping OBD session active")
                        notifyFlutterScreenOff()
                    }
                    Intent.ACTION_SCREEN_ON,
                    Intent.ACTION_USER_PRESENT,
                    Intent.ACTION_POWER_CONNECTED,
                    "android.intent.action.QUICKBOOT_POWERON" -> {
                        Log.d(TAG, "Screen On/Power Connected - Restoring app and OBD")
                        acquireWakeLock()
                        notifyFlutterScreenOn()
                    }
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
            addAction("android.intent.action.QUICKBOOT_POWERON")
            addAction("android.intent.action.QUICKBOOT_POWEROFF")
        }

        // FIX: Android 13+ (API 33) exige declarar EXPORTED/NOT_EXPORTED en
        // registerReceiver dinámico, o lanza SecurityException en tiempo de
        // ejecución. Sin este flag, el servicio crasheaba en onCreate() antes
        // de llegar a hacer nada útil.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenStateReceiver, filter)
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "DashCore::PersistenceWakeLock"
            )
        }
        if (wakeLock?.isHeld == false) {
            wakeLock?.acquire()
            Log.d(TAG, "WakeLock acquired for active OBD session")
        }
    }

    private fun releaseWakeLock() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
            Log.d(TAG, "WakeLock released")
        }
    }

    private fun notifyFlutterScreenOn() {
        val intent = Intent("com.dashcore.app.SCREEN_ON")
        sendBroadcast(intent)
    }

    private fun notifyFlutterScreenOff() {
        val intent = Intent("com.dashcore.app.SCREEN_OFF")
        sendBroadcast(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service onDestroy")
        try {
            unregisterReceiver(screenStateReceiver)
        } catch (_: Exception) {}
        releaseWakeLock()

    }
}
