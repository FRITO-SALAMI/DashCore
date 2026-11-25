package com.dashcore.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val actions = listOf(
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED
        )
        
        if (actions.contains(intent.action)) {
            val prefs = context.getSharedPreferences("dashcore_persistence", Context.MODE_PRIVATE)
            if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) {
                prefs.edit().putBoolean("acc_sleeping", false).apply()
            }
            if (!prefs.getBoolean("keep_app_active", false) || prefs.getBoolean("service_explicitly_stopped", true) || prefs.getBoolean("acc_sleeping", false)) return
            // Restore only a previously enabled service.
            val serviceIntent = Intent(context, DashCoreService::class.java)
            try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (_: Exception) {
                // Some Android radio ROMs enforce newer background-start rules.
                // START_STICKY or the next foreground launch restores the service.
            }

            // We do NOT start MainActivity here anymore to avoid stealing focus on boot
            // DashCoreService will bring it to foreground on SCREEN_ON if needed
        }
    }
}
