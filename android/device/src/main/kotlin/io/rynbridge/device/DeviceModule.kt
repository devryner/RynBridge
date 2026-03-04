package io.rynbridge.device

import io.rynbridge.core.*

class DeviceModule(provider: DeviceInfoProvider) : BridgeModule {

    override val name = "device"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "getInfo" to { _ ->
            provider.getDeviceInfo().toPayload()
        },
        "getBattery" to { _ ->
            provider.getBatteryInfo().toPayload()
        },
        "getScreen" to { _ ->
            provider.getScreenInfo().toPayload()
        },
        "vibrate" to { payload ->
            val pattern = payload["pattern"]?.arrayValue
                ?.mapNotNull { it.intValue?.toInt() }
                ?: emptyList()
            provider.vibrate(pattern)
            emptyMap()
        },
        "capturePhoto" to { payload ->
            val quality = payload["quality"]?.doubleValue ?: 0.8
            val camera = payload["camera"]?.stringValue ?: "back"
            val result = provider.capturePhoto(quality, camera)
            result.toPayload()
        },
        "getLocation" to { _ ->
            val location = provider.getLocation()
            location.toPayload()
        },
        "authenticate" to { payload ->
            val reason = payload["reason"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: reason")
            val result = provider.authenticate(reason)
            result.toPayload()
        }
    )
}
