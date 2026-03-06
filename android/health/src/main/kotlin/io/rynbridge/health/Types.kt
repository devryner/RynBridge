package io.rynbridge.health

import io.rynbridge.core.BridgeValue

interface HealthProvider {
    suspend fun requestPermission(readTypes: List<String>, writeTypes: List<String>): Boolean
    suspend fun getPermissionStatus(): String
    suspend fun queryData(dataType: String, startDate: String, endDate: String, limit: Int?): List<Map<String, BridgeValue>>
    suspend fun writeData(dataType: String, value: Double, unit: String, startDate: String, endDate: String): Boolean
    suspend fun getSteps(startDate: String, endDate: String): Double
    suspend fun isAvailable(): Boolean
}
