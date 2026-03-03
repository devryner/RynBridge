package io.rynbridge.device

import io.rynbridge.core.ActionHandler
import io.rynbridge.core.BridgeModule
import io.rynbridge.core.BridgeValue

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
        }
    )
}
