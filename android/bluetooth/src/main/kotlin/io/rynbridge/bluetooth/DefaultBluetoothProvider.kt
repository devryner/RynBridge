package io.rynbridge.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import io.rynbridge.core.BridgeValue
import io.rynbridge.core.ErrorCode
import io.rynbridge.core.RynBridgeError
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class DefaultBluetoothProvider(private val context: Context) : BluetoothProvider {

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    private val connectedGatts = ConcurrentHashMap<String, BluetoothGatt>()
    private var scanCallback: ScanCallback? = null

    private fun requireBluetoothPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED ||
                context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED
            ) {
                throw RynBridgeError(
                    code = ErrorCode.UNKNOWN,
                    message = "Bluetooth permissions denied. Required: BLUETOOTH_SCAN, BLUETOOTH_CONNECT"
                )
            }
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun startScan(serviceUUIDs: List<String>?): Boolean {
        requireBluetoothPermission()
        val adapter = bluetoothAdapter ?: return false
        val scanner = adapter.bluetoothLeScanner ?: return false

        stopScan()

        val filters = serviceUUIDs?.map { uuid ->
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(UUID.fromString(uuid)))
                .build()
        }

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                // Scan results are available; consumers should register a listener
            }

            override fun onScanFailed(errorCode: Int) {
                // Scan failed
            }
        }

        if (filters != null) {
            scanner.startScan(filters, settings, scanCallback!!)
        } else {
            scanner.startScan(null, settings, scanCallback!!)
        }

        return true
    }

    @SuppressLint("MissingPermission")
    override fun stopScan() {
        val adapter = bluetoothAdapter ?: return
        val scanner = adapter.bluetoothLeScanner ?: return
        scanCallback?.let {
            scanner.stopScan(it)
            scanCallback = null
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun connect(deviceId: String): Boolean {
        requireBluetoothPermission()
        val adapter = bluetoothAdapter ?: return false
        val device = adapter.getRemoteDevice(deviceId) ?: return false

        return suspendCancellableCoroutine { cont ->
            val gatt = device.connectGatt(context, false, object : BluetoothGattCallback() {
                override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                    if (newState == BluetoothProfile.STATE_CONNECTED) {
                        connectedGatts[deviceId] = gatt
                        gatt.discoverServices()
                        cont.resume(true)
                    } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                        connectedGatts.remove(deviceId)
                        if (cont.isActive) cont.resume(false)
                    }
                }
            })

            cont.invokeOnCancellation {
                gatt.close()
            }
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun disconnect(deviceId: String): Boolean {
        val gatt = connectedGatts.remove(deviceId)
        if (gatt != null) {
            gatt.disconnect()
            gatt.close()
            return true
        }
        return false
    }

    override suspend fun getServices(deviceId: String): List<Map<String, BridgeValue>> {
        val gatt = connectedGatts[deviceId]
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Device not connected: $deviceId")

        return gatt.services.map { service ->
            val characteristics = service.characteristics.map { char ->
                mapOf(
                    "uuid" to BridgeValue.string(char.uuid.toString()),
                    "properties" to BridgeValue.int(char.properties)
                )
            }
            mapOf(
                "uuid" to BridgeValue.string(service.uuid.toString()),
                "characteristics" to BridgeValue.array(characteristics.map { c ->
                    BridgeValue.dict(c)
                })
            )
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun readCharacteristic(
        deviceId: String,
        serviceUUID: String,
        characteristicUUID: String
    ): String {
        val gatt = connectedGatts[deviceId]
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Device not connected: $deviceId")

        val service = gatt.getService(UUID.fromString(serviceUUID))
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Service not found: $serviceUUID")
        val characteristic = service.getCharacteristic(UUID.fromString(characteristicUUID))
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Characteristic not found: $characteristicUUID")

        return suspendCancellableCoroutine { cont ->
            gatt.readCharacteristic(characteristic)
            // Note: In production, you would need a more sophisticated callback mechanism
            // to handle async characteristic reads. This is a simplified implementation.
            @Suppress("DEPRECATION")
            val bytes = characteristic.value
            if (bytes != null) {
                cont.resume(android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP))
            } else {
                cont.resume("")
            }
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun writeCharacteristic(
        deviceId: String,
        serviceUUID: String,
        characteristicUUID: String,
        value: String
    ): Boolean {
        val gatt = connectedGatts[deviceId]
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Device not connected: $deviceId")

        val service = gatt.getService(UUID.fromString(serviceUUID))
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Service not found: $serviceUUID")
        val characteristic = service.getCharacteristic(UUID.fromString(characteristicUUID))
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Characteristic not found: $characteristicUUID")

        val bytes = android.util.Base64.decode(value, android.util.Base64.NO_WRAP)
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            gatt.writeCharacteristic(
                characteristic,
                bytes,
                BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            ) == BluetoothStatusCodes.SUCCESS
        } else {
            @Suppress("DEPRECATION")
            characteristic.value = bytes
            @Suppress("DEPRECATION")
            gatt.writeCharacteristic(characteristic)
        }
    }

    override suspend fun requestPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    override suspend fun getState(): String {
        val adapter = bluetoothAdapter ?: return "unsupported"
        return if (adapter.isEnabled) "poweredOn" else "poweredOff"
    }
}
