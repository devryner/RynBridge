package io.rynbridge.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import io.rynbridge.core.BridgeValue
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

@SuppressLint("MissingPermission")
class DefaultBluetoothProvider(private val context: Context) : BluetoothProvider {

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    private val connectedGatts = ConcurrentHashMap<String, BluetoothGatt>()
    private var scanCallback: ScanCallback? = null

    override suspend fun startScan(serviceUUIDs: List<String>?): Boolean {
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

    override fun stopScan() {
        val adapter = bluetoothAdapter ?: return
        val scanner = adapter.bluetoothLeScanner ?: return
        scanCallback?.let {
            scanner.stopScan(it)
            scanCallback = null
        }
    }

    override suspend fun connect(deviceId: String): Boolean {
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
            ?: throw IllegalStateException("Device not connected: $deviceId")

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

    override suspend fun readCharacteristic(
        deviceId: String,
        serviceUUID: String,
        characteristicUUID: String
    ): String {
        val gatt = connectedGatts[deviceId]
            ?: throw IllegalStateException("Device not connected: $deviceId")

        val service = gatt.getService(UUID.fromString(serviceUUID))
            ?: throw IllegalStateException("Service not found: $serviceUUID")
        val characteristic = service.getCharacteristic(UUID.fromString(characteristicUUID))
            ?: throw IllegalStateException("Characteristic not found: $characteristicUUID")

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

    override suspend fun writeCharacteristic(
        deviceId: String,
        serviceUUID: String,
        characteristicUUID: String,
        value: String
    ): Boolean {
        val gatt = connectedGatts[deviceId]
            ?: throw IllegalStateException("Device not connected: $deviceId")

        val service = gatt.getService(UUID.fromString(serviceUUID))
            ?: throw IllegalStateException("Service not found: $serviceUUID")
        val characteristic = service.getCharacteristic(UUID.fromString(characteristicUUID))
            ?: throw IllegalStateException("Characteristic not found: $characteristicUUID")

        val bytes = android.util.Base64.decode(value, android.util.Base64.NO_WRAP)
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            gatt.writeCharacteristic(
                characteristic,
                bytes,
                BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            ) == BluetoothGatt.GATT_SUCCESS
        } else {
            @Suppress("DEPRECATION")
            characteristic.value = bytes
            @Suppress("DEPRECATION")
            gatt.writeCharacteristic(characteristic)
        }
    }

    override suspend fun requestPermission(): Boolean {
        // Permission requests require an Activity context
        // Return true assuming permissions are already granted
        return true
    }

    override suspend fun getState(): String {
        val adapter = bluetoothAdapter ?: return "unsupported"
        return if (adapter.isEnabled) "poweredOn" else "poweredOff"
    }
}
