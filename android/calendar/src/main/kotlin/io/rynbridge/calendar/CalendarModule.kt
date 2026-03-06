package io.rynbridge.calendar

import io.rynbridge.core.*

class CalendarModule(provider: CalendarProvider) : BridgeModule {

    override val name = "calendar"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "getCalendars" to { _ ->
            val calendars = provider.getCalendars()
            mapOf("calendars" to BridgeValue.array(calendars.map { BridgeValue.dict(it.toPayload()) }))
        },
        "getEvents" to { payload ->
            val calendarId = payload["calendarId"]?.stringValue
            val from = payload["from"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: from")
            val to = payload["to"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: to")
            val events = provider.getEvents(calendarId, from, to)
            mapOf("events" to BridgeValue.array(events.map { BridgeValue.dict(it.toPayload()) }))
        },
        "getEvent" to { payload ->
            val id = payload["id"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: id")
            val event = provider.getEvent(id)
            event.toPayload()
        },
        "createEvent" to { payload ->
            val calendarId = payload["calendarId"]?.stringValue
            val title = payload["title"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: title")
            val startDate = payload["startDate"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: startDate")
            val endDate = payload["endDate"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: endDate")
            val location = payload["location"]?.stringValue
            val notes = payload["notes"]?.stringValue
            val isAllDay = payload["isAllDay"]?.boolValue ?: false
            val id = provider.createEvent(calendarId, title, startDate, endDate, location, notes, isAllDay)
            CreateEventResult(id).toPayload()
        },
        "updateEvent" to { payload ->
            val id = payload["id"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: id")
            val title = payload["title"]?.stringValue
            val startDate = payload["startDate"]?.stringValue
            val endDate = payload["endDate"]?.stringValue
            val location = payload["location"]?.stringValue
            val notes = payload["notes"]?.stringValue
            val isAllDay = payload["isAllDay"]?.boolValue
            provider.updateEvent(id, title, startDate, endDate, location, notes, isAllDay)
            emptyMap()
        },
        "deleteEvent" to { payload ->
            val id = payload["id"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: id")
            provider.deleteEvent(id)
            emptyMap()
        },
        "createReminder" to { payload ->
            val title = payload["title"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: title")
            val dueDate = payload["dueDate"]?.stringValue
            val notes = payload["notes"]?.stringValue
            val id = provider.createReminder(title, dueDate, notes)
            CreateReminderResult(id).toPayload()
        },
        "requestPermission" to { _ ->
            val granted = provider.requestPermission()
            PermissionResult(granted).toPayload()
        },
        "getPermissionStatus" to { _ ->
            val status = provider.getPermissionStatus()
            PermissionStatus(status).toPayload()
        }
    )
}
