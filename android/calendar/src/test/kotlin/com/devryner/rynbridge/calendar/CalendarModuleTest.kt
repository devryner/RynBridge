package com.devryner.rynbridge.calendar

import com.devryner.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class CalendarModuleTest {

    @Test
    fun `getCalendars returns calendar list`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["getCalendars"]!!

        val result = handler(emptyMap())
        val calendars = result["calendars"]?.arrayValue
        assertNotNull(calendars)
        assertEquals(1, calendars!!.size)
        assertEquals("cal-1", calendars[0].dictionaryValue?.get("id")?.stringValue)
        assertEquals("Personal", calendars[0].dictionaryValue?.get("title")?.stringValue)
    }

    @Test
    fun `getEvents returns event list`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["getEvents"]!!

        val result = handler(mapOf(
            "calendarId" to BridgeValue.string("cal-1"),
            "from" to BridgeValue.string("2026-01-01"),
            "to" to BridgeValue.string("2026-12-31")
        ))
        val events = result["events"]?.arrayValue
        assertNotNull(events)
        assertEquals(1, events!!.size)
        assertEquals("Meeting", events[0].dictionaryValue?.get("title")?.stringValue)
    }

    @Test
    fun `getEvent returns single event`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["getEvent"]!!

        val result = handler(mapOf("id" to BridgeValue.string("evt-1")))
        assertEquals("evt-1", result["id"]?.stringValue)
        assertEquals("Meeting", result["title"]?.stringValue)
        assertEquals("2026-03-06T10:00:00", result["startDate"]?.stringValue)
    }

    @Test
    fun `createEvent returns id`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["createEvent"]!!

        val result = handler(mapOf(
            "calendarId" to BridgeValue.string("cal-1"),
            "title" to BridgeValue.string("New Event"),
            "startDate" to BridgeValue.string("2026-03-07T09:00:00"),
            "endDate" to BridgeValue.string("2026-03-07T10:00:00"),
            "location" to BridgeValue.string("Office"),
            "notes" to BridgeValue.string("Important"),
            "isAllDay" to BridgeValue.bool(false)
        ))
        assertEquals("new-evt", result["id"]?.stringValue)
    }

    @Test
    fun `updateEvent calls provider`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["updateEvent"]!!

        val result = handler(mapOf(
            "id" to BridgeValue.string("evt-1"),
            "title" to BridgeValue.string("Updated Meeting")
        ))
        assertTrue(result.isEmpty())
        assertEquals("evt-1", provider.lastUpdateId)
        assertEquals("Updated Meeting", provider.lastUpdateTitle)
    }

    @Test
    fun `deleteEvent calls provider`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["deleteEvent"]!!

        val result = handler(mapOf("id" to BridgeValue.string("evt-1")))
        assertTrue(result.isEmpty())
        assertEquals("evt-1", provider.lastDeleteId)
    }

    @Test
    fun `createReminder returns id`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["createReminder"]!!

        val result = handler(mapOf(
            "title" to BridgeValue.string("Buy groceries"),
            "dueDate" to BridgeValue.string("2026-03-07"),
            "notes" to BridgeValue.string("Milk, eggs")
        ))
        assertEquals("rem-1", result["id"]?.stringValue)
    }

    @Test
    fun `requestPermission returns granted`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["requestPermission"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["granted"]?.boolValue)
    }

    @Test
    fun `getPermissionStatus returns status`() = runTest {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        val handler = module.actions["getPermissionStatus"]!!

        val result = handler(emptyMap())
        assertEquals("granted", result["status"]?.stringValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockCalendarProvider()
        val module = CalendarModule(provider)
        assertEquals("calendar", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockCalendarProvider : CalendarProvider {
    var lastUpdateId: String? = null
    var lastUpdateTitle: String? = null
    var lastDeleteId: String? = null

    private val mockCalendar = CalendarData(
        id = "cal-1",
        title = "Personal",
        color = "#FF0000",
        isReadOnly = false
    )

    private val mockEvent = CalendarEventData(
        id = "evt-1",
        calendarId = "cal-1",
        title = "Meeting",
        startDate = "2026-03-06T10:00:00",
        endDate = "2026-03-06T11:00:00",
        location = "Room A",
        notes = "Discuss project",
        isAllDay = false
    )

    override suspend fun getCalendars(): List<CalendarData> = listOf(mockCalendar)

    override suspend fun getEvents(calendarId: String?, from: String, to: String): List<CalendarEventData> =
        listOf(mockEvent)

    override suspend fun getEvent(id: String): CalendarEventData = mockEvent

    override suspend fun createEvent(
        calendarId: String?,
        title: String,
        startDate: String,
        endDate: String,
        location: String?,
        notes: String?,
        isAllDay: Boolean
    ): String = "new-evt"

    override suspend fun updateEvent(
        id: String,
        title: String?,
        startDate: String?,
        endDate: String?,
        location: String?,
        notes: String?,
        isAllDay: Boolean?
    ) {
        lastUpdateId = id
        lastUpdateTitle = title
    }

    override suspend fun deleteEvent(id: String) {
        lastDeleteId = id
    }

    override suspend fun createReminder(title: String, dueDate: String?, notes: String?): String = "rem-1"

    override suspend fun requestPermission(): Boolean = true

    override suspend fun getPermissionStatus(): String = "granted"
}
