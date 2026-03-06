package io.rynbridge.bluetooth

import io.rynbridge.core.*

class BluetoothModule(provider: BluetoothProvider) : BridgeModule {

    override val name = "bluetooth"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "startScan" to { payload ->
            val serviceUUIDs = payload["serviceUUIDs"]?.arrayValue?.mapNotNull { it.stringValue }
            val success = provider.startScan(serviceUUIDs)
            mapOf("success" to BridgeValue.bool(success))
        },
        "stopScan" to { _ ->
            provider.stopScan()
            emptyMap()
        },
        "connect" to { payload ->
            val deviceId = payload["deviceId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: deviceId")
            val success = provider.connect(deviceId)
            mapOf("success" to BridgeValue.bool(success))
        },
        "disconnect" to { payload ->
            val deviceId = payload["deviceId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: deviceId")
            val success = provider.disconnect(deviceId)
            mapOf("success" to BridgeValue.bool(success))
        },
        "getServices" to { payload ->
            val deviceId = payload["deviceId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: deviceId")
            val services = provider.getServices(deviceId)
            mapOf("services" to BridgeValue.array(services.map { BridgeValue.dict(it) }))
        },
        "readCharacteristic" to { payload ->
            val deviceId = payload["deviceId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: deviceId")
            val serviceUUID = payload["serviceUUID"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: serviceUUID")
            val characteristicUUID = payload["characteristicUUID"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: characteristicUUID")
            val value = provider.readCharacteristic(deviceId, serviceUUID, characteristicUUID)
            mapOf("value" to BridgeValue.string(value))
        },
        "writeCharacteristic" to { payload ->
            val deviceId = payload["deviceId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: deviceId")
            val serviceUUID = payload["serviceUUID"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: serviceUUID")
            val characteristicUUID = payload["characteristicUUID"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: characteristicUUID")
            val value = payload["value"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: value")
            val success = provider.writeCharacteristic(deviceId, serviceUUID, characteristicUUID, value)
            mapOf("success" to BridgeValue.bool(success))
        },
        "requestPermission" to { _ ->
            val granted = provider.requestPermission()
            mapOf("granted" to BridgeValue.bool(granted))
        },
        "getState" to { _ ->
            val state = provider.getState()
            mapOf("state" to BridgeValue.string(state))
        }
    )
}
