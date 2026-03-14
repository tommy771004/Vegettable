package com.vegettable.app.util

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.result.ActivityResultLauncher
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment

/**
 * 動態權限管理 — 處理執行時權限申請
 */
object PermissionManager {
    private const val TAG = "PermissionManager"

    /**
     * 檢查位置權限
     */
    fun hasLocationPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true

        return (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED)
                && (ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
                == PackageManager.PERMISSION_GRANTED)
    }

    /**
     * 檢查通知權限 (API 33+)
     */
    fun hasNotificationPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true

        return (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED)
    }

    /**
     * 檢查網際網路權限 (預期總是擁有)
     */
    fun hasInternetPermission(context: Context): Boolean {
        return (ContextCompat.checkSelfPermission(context, Manifest.permission.INTERNET)
                == PackageManager.PERMISSION_GRANTED)
    }

    /**
     * 在 Activity 中請求位置權限
     */
    fun requestLocationPermission(
        activity: Activity?,
        launcher: ActivityResultLauncher<Array<String?>?>
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            launcher.launch(
                arrayOf<String?>(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        }
    }

    /**
     * 在 Activity 中請求通知權限 (API 33+)
     */
    fun requestNotificationPermission(
        activity: Activity?,
        launcher: ActivityResultLauncher<String?>
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    /**
     * 在 Fragment 中請求位置權限
     */
    fun requestLocationPermission(
        fragment: Fragment?,
        launcher: ActivityResultLauncher<Array<String?>?>
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            launcher.launch(
                arrayOf<String?>(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        }
    }

    /**
     * 在 Fragment 中請求通知權限 (API 33+)
     */
    fun requestNotificationPermission(
        fragment: Fragment?,
        launcher: ActivityResultLauncher<String?>
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }
}