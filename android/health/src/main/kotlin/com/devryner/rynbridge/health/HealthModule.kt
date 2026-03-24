package com.devryner.rynbridge.health

import com.devryner.rynbridge.core.*

class HealthModule(provider: HealthProvider) : BridgeModule {

    override val name = "health"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "requestPermission" to { payload ->
            val readTypes = payload["readTypes"]?.arrayValue?.mapNotNull { it.stringValue }
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: readTypes")
            val writeTypes = payload["writeTypes"]?.arrayValue?.mapNotNull { it.stringValue } ?: emptyList()
            val granted = provider.requestPermission(readTypes, writeTypes)
            mapOf("granted" to BridgeValue.bool(granted))
        },
        "getPermissionStatus" to { _ ->
            val status = provider.getPermissionStatus()
            mapOf("status" to BridgeValue.string(status))
        },
        "queryData" to { payload ->
            val dataType = payload["dataType"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: dataType")
            val startDate = payload["startDate"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: startDate")
            val endDate = payload["endDate"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: endDate")
            val limit = payload["limit"]?.intValue?.toInt()
            val records = provider.queryData(dataType, startDate, endDate, limit)
            mapOf("records" to BridgeValue.array(records.map { BridgeValue.dict(it) }))
        },
        "writeData" to { payload ->
            val dataType = payload["dataType"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: dataType")
            val value = payload["value"]?.doubleValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: value")
            val unit = payload["unit"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: unit")
            val startDate = payload["startDate"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: startDate")
            val endDate = payload["endDate"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: endDate")
            val success = provider.writeData(dataType, value, unit, startDate, endDate)
            mapOf("success" to BridgeValue.bool(success))
        },
        "getSteps" to { payload ->
            val startDate = payload["startDate"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: startDate")
            val endDate = payload["endDate"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: endDate")
            val steps = provider.getSteps(startDate, endDate)
            mapOf("steps" to BridgeValue.double(steps))
        },
        "isAvailable" to { _ ->
            val available = provider.isAvailable()
            mapOf("available" to BridgeValue.bool(available))
        }
    )
}
