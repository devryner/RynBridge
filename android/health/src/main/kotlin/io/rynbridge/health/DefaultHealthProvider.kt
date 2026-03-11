package io.rynbridge.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.rynbridge.core.BridgeValue
import io.rynbridge.core.ErrorCode
import io.rynbridge.core.RynBridgeError
import java.time.Instant
import java.time.ZoneOffset

class DefaultHealthProvider(private val context: Context) : HealthProvider {

    private val healthConnectClient: HealthConnectClient by lazy {
        HealthConnectClient.getOrCreate(context)
    }

    override suspend fun requestPermission(readTypes: List<String>, writeTypes: List<String>): Boolean {
        val granted = healthConnectClient.permissionController.getGrantedPermissions()
        return granted.isNotEmpty()
    }

    override suspend fun getPermissionStatus(): String {
        return try {
            val granted = healthConnectClient.permissionController
                .getGrantedPermissions()
            if (granted.isNotEmpty()) "granted" else "denied"
        } catch (e: Exception) {
            "denied"
        }
    }

    override suspend fun queryData(
        dataType: String,
        startDate: String,
        endDate: String,
        limit: Int?
    ): List<Map<String, BridgeValue>> {
        val start = Instant.parse(startDate)
        val end = Instant.parse(endDate)
        val timeRangeFilter = TimeRangeFilter.between(start, end)

        return when (dataType) {
            "steps" -> {
                val request = ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = timeRangeFilter
                )
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startDate" to BridgeValue.string(record.startTime.toString()),
                        "endDate" to BridgeValue.string(record.endTime.toString()),
                        "value" to BridgeValue.double(record.count.toDouble()),
                        "type" to BridgeValue.string("steps")
                    )
                }
            }
            else -> throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Unsupported data type: $dataType")
        }
    }

    override suspend fun writeData(
        dataType: String,
        value: Double,
        unit: String,
        startDate: String,
        endDate: String
    ): Boolean {
        val start = Instant.parse(startDate)
        val end = Instant.parse(endDate)

        return when (dataType) {
            "steps" -> {
                val record = StepsRecord(
                    count = value.toLong(),
                    startTime = start,
                    endTime = end,
                    startZoneOffset = ZoneOffset.UTC,
                    endZoneOffset = ZoneOffset.UTC
                )
                healthConnectClient.insertRecords(listOf(record))
                true
            }
            else -> throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Unsupported data type: $dataType")
        }
    }

    override suspend fun getSteps(startDate: String, endDate: String): Double {
        val start = Instant.parse(startDate)
        val end = Instant.parse(endDate)

        val response = healthConnectClient.aggregate(
            AggregateRequest(
                metrics = setOf(StepsRecord.COUNT_TOTAL),
                timeRangeFilter = TimeRangeFilter.between(start, end)
            )
        )

        return (response[StepsRecord.COUNT_TOTAL] ?: 0L).toDouble()
    }

    override suspend fun isAvailable(): Boolean {
        return try {
            HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE
        } catch (e: Exception) {
            false
        }
    }
}
