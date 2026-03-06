package io.rynbridge.bluetooth

import io.rynbridge.core.BridgeValue

interface BluetoothProvider {
    suspend fun startScan(serviceUUIDs: List<String>?): Boolean
    fun stopScan()
    suspend fun connect(deviceId: String): Boolean
    suspend fun disconnect(deviceId: String): Boolean
    suspend fun getServices(deviceId: String): List<Map<String, BridgeValue>>
    suspend fun readCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String): String
    suspend fun writeCharacteristic(deviceId: String, serviceUUID: String, characteristicUUID: String, value: String): Boolean
    suspend fun requestPermission(): Boolean
    suspend fun getState(): String
}
