package com.detox.detox_launcher

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class DetoxAccessibilityService : AccessibilityService() {

    private val TAG = "DetoxAccessibility"
    private var blockedPackages = mutableSetOf<String>()
    private var isLockMode = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Monitor app launches
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()

            if (packageName != null && packageName != this.packageName) {
                Log.d(TAG, "App launched: $packageName")

                // Check if in lock mode and app is blocked
                if (isLockMode && shouldBlockApp(packageName)) {
                    Log.d(TAG, "Blocking app: $packageName")
                    returnToLauncher()
                }

                // Track app usage (communicate with Flutter)
                trackAppUsage(packageName)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    private fun shouldBlockApp(packageName: String): Boolean {
        // Don't block system apps or important apps
        if (packageName.startsWith("com.android")) return false
        if (packageName == "com.google.android.dialer") return false
        if (packageName == "com.android.systemui") return false

        // Check against blocked list (should be synced from Flutter)
        return blockedPackages.contains(packageName)
    }

    private fun returnToLauncher() {
        try {
            // Return to launcher (this app)
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            intent.putExtra("show_lock_screen", true)
            startActivity(intent)

            // Also perform back action to close the blocked app
            performGlobalAction(GLOBAL_ACTION_BACK)
        } catch (e: Exception) {
            Log.e(TAG, "Error returning to launcher", e)
        }
    }

    private fun trackAppUsage(packageName: String) {
        // This would communicate with Flutter via MethodChannel
        // For now, just log it
        Log.d(TAG, "Tracking usage for: $packageName")
    }

    fun setLockMode(locked: Boolean) {
        isLockMode = locked
        Log.d(TAG, "Lock mode set to: $locked")
    }

    fun setBlockedPackages(packages: Set<String>) {
        blockedPackages.clear()
        blockedPackages.addAll(packages)
        Log.d(TAG, "Blocked packages updated: ${packages.size} packages")
    }
}
