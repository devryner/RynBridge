package io.rynbridge.device

import android.content.Context
import android.content.res.Configuration
import android.os.BatteryManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.rynbridge.core.ErrorCode
import io.rynbridge.core.RynBridgeError

class DefaultDeviceInfoProvider(private val context: Context) : DeviceInfoProvider {

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
        val metrics = windowManager.currentWindowMetrics
        val bounds = metrics.bounds
        val density = context.resources.displayMetrics.density
        val orientation = if (context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            "landscape"
        } else {
            "portrait"
        }
        return ScreenInfo(
            width = (bounds.width() / density).toDouble(),
            height = (bounds.height() / density).toDouble(),
            scale = density.toDouble(),
            orientation = orientation
        )
    }

    override fun vibrate(pattern: List<Int>) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (pattern.isEmpty()) {
            vibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            val timings = pattern.map { it.toLong() }.toLongArray()
            vibrator.vibrate(VibrationEffect.createWaveform(timings, -1))
        }
    }

    override suspend fun capturePhoto(quality: Double, camera: String): CapturePhotoResult {
        throw RynBridgeError(
            code = ErrorCode.UNKNOWN,
            message = "capturePhoto requires an Activity context. Use a custom provider with Activity-based camera integration."
        )
    }

    override suspend fun getLocation(): LocationInfo {
        throw RynBridgeError(
            code = ErrorCode.UNKNOWN,
            message = "getLocation requires location permissions and an Activity context. Use a custom provider with FusedLocationProviderClient."
        )
    }

    override suspend fun authenticate(reason: String): AuthenticateResult {
        throw RynBridgeError(
            code = ErrorCode.UNKNOWN,
            message = "authenticate requires an Activity context. Use a custom provider with BiometricPrompt."
        )
    }
}
