package io.rynbridge.device

import io.rynbridge.core.BridgeValue

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

interface DeviceInfoProvider {
    fun getDeviceInfo(): DeviceInfo
    fun getBatteryInfo(): BatteryInfo
    fun getScreenInfo(): ScreenInfo
    fun vibrate(pattern: List<Int>)
}
