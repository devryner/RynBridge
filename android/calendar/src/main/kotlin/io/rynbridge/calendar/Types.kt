package io.rynbridge.calendar

import io.rynbridge.core.BridgeValue

data class CalendarData(
    val id: String,
    val title: String,
    val color: String?,
    val isReadOnly: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "id" to BridgeValue.string(id),
        "title" to BridgeValue.string(title),
        "color" to (color?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "isReadOnly" to BridgeValue.bool(isReadOnly)
    )
}

data class CalendarEventData(
    val id: String,
    val calendarId: String,
    val title: String,
    val startDate: String,
    val endDate: String,
    val location: String?,
    val notes: String?,
    val isAllDay: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "id" to BridgeValue.string(id),
        "calendarId" to BridgeValue.string(calendarId),
        "title" to BridgeValue.string(title),
        "startDate" to BridgeValue.string(startDate),
        "endDate" to BridgeValue.string(endDate),
        "location" to (location?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "notes" to (notes?.let { BridgeValue.string(it) } ?: BridgeValue.nullValue()),
        "isAllDay" to BridgeValue.bool(isAllDay)
    )
}

data class CreateEventResult(val id: String) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "id" to BridgeValue.string(id)
    )
}

data class CreateReminderResult(val id: String) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "id" to BridgeValue.string(id)
    )
}

data class PermissionResult(val granted: Boolean) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "granted" to BridgeValue.bool(granted)
    )
}

data class PermissionStatus(val status: String) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "status" to BridgeValue.string(status)
    )
}

interface CalendarProvider {
    suspend fun getCalendars(): List<CalendarData>
    suspend fun getEvents(calendarId: String?, from: String, to: String): List<CalendarEventData>
    suspend fun getEvent(id: String): CalendarEventData
    suspend fun createEvent(calendarId: String?, title: String, startDate: String, endDate: String, location: String?, notes: String?, isAllDay: Boolean): String
    suspend fun updateEvent(id: String, title: String?, startDate: String?, endDate: String?, location: String?, notes: String?, isAllDay: Boolean?)
    suspend fun deleteEvent(id: String)
    suspend fun createReminder(title: String, dueDate: String?, notes: String?): String
    suspend fun requestPermission(): Boolean
    suspend fun getPermissionStatus(): String
}
