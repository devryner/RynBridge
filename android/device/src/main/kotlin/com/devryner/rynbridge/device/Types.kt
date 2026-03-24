package com.devryner.rynbridge.device

import com.devryner.rynbridge.core.BridgeValue

data class DeviceInfo(
    val platform: String,
    val osVersion: String,
    val model: String,
    val appVersion: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "platform" to BridgeValue.string(platform),
        "osVersion" to BridgeValue.string(osVersion),
        "model" to BridgeValue.string(model),
        "appVersion" to BridgeValue.string(appVersion)
    )
}

data class BatteryInfo(
    val level: Int,
    val isCharging: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "level" to BridgeValue.int(level),
        "isCharging" to BridgeValue.bool(isCharging)
    )
}

data class ScreenInfo(
    val width: Double,
    val height: Double,
    val scale: Double,
    val orientation: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "width" to BridgeValue.double(width),
        "height" to BridgeValue.double(height),
        "scale" to BridgeValue.double(scale),
        "orientation" to BridgeValue.string(orientation)
    )
}

data class CapturePhotoResult(
    val imageBase64: String,
    val width: Int,
    val height: Int
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "imageBase64" to BridgeValue.string(imageBase64),
        "width" to BridgeValue.int(width),
        "height" to BridgeValue.int(height)
    )
}

data class LocationInfo(
    val latitude: Double,
    val longitude: Double,
    val accuracy: Double
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "latitude" to BridgeValue.double(latitude),
        "longitude" to BridgeValue.double(longitude),
        "accuracy" to BridgeValue.double(accuracy)
    )
}

data class AuthenticateResult(
    val success: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "success" to BridgeValue.bool(success)
    )
}

interface DeviceInfoProvider {
    fun getDeviceInfo(): DeviceInfo
    fun getBatteryInfo(): BatteryInfo
    fun getScreenInfo(): ScreenInfo
    fun vibrate(pattern: List<Int>)
    suspend fun capturePhoto(quality: Double, camera: String): CapturePhotoResult
    suspend fun getLocation(): LocationInfo
    suspend fun authenticate(reason: String): AuthenticateResult
}
