package com.devryner.rynbridge.playground.providers

import android.content.Context
import android.content.res.Configuration
import android.os.BatteryManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.DisplayMetrics
import android.view.WindowManager
import com.devryner.rynbridge.device.*

class AndroidDeviceInfoProvider(private val context: Context) : DeviceInfoProvider {

    override fun getDeviceInfo(): DeviceInfo {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        return DeviceInfo(
            platform = "android",
            osVersion = Build.VERSION.RELEASE,
            model = "${Build.MANUFACTURER} ${Build.MODEL}",
            appVersion = packageInfo.versionName ?: "0.0.0"
        )
    }

    override fun getBatteryInfo(): BatteryInfo {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val isCharging = batteryManager.isCharging
        return BatteryInfo(level = level, isCharging = isCharging)
    }

    override fun getScreenInfo(): ScreenInfo {
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager.defaultDisplay.getRealMetrics(metrics)
        val orientation = if (context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            "landscape"
        } else {
            "portrait"
        }
        return ScreenInfo(
            width = (metrics.widthPixels / metrics.density).toDouble(),
            height = (metrics.heightPixels / metrics.density).toDouble(),
            scale = metrics.density.toDouble(),
            orientation = orientation
        )
    }

    override fun vibrate(pattern: List<Int>) {
        val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
        if (pattern.isEmpty()) {
            vibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            val timings = pattern.map { it.toLong() }.toLongArray()
            vibrator.vibrate(VibrationEffect.createWaveform(timings, -1))
        }
    }

    override suspend fun capturePhoto(quality: Double, camera: String): CapturePhotoResult {
        throw UnsupportedOperationException("capturePhoto not implemented in playground")
    }

    override suspend fun getLocation(): LocationInfo {
        throw UnsupportedOperationException("getLocation not implemented in playground")
    }

    override suspend fun authenticate(reason: String): AuthenticateResult {
        throw UnsupportedOperationException("authenticate not implemented in playground")
    }
}
