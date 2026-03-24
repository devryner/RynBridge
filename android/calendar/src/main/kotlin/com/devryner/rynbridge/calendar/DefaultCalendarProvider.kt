package com.devryner.rynbridge.calendar

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CalendarContract
import com.devryner.rynbridge.core.ErrorCode
import com.devryner.rynbridge.core.RynBridgeError
import java.time.Instant
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

class DefaultCalendarProvider(private val context: Context) : CalendarProvider {

    private val contentResolver: ContentResolver
        get() = context.contentResolver

    private val isoFormatter: DateTimeFormatter = DateTimeFormatter.ISO_DATE_TIME

    private fun requireReadPermission() {
        if (context.checkSelfPermission(android.Manifest.permission.READ_CALENDAR) != PackageManager.PERMISSION_GRANTED) {
            throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Calendar read permission denied. Required: READ_CALENDAR")
        }
    }

    private fun requireWritePermission() {
        if (context.checkSelfPermission(android.Manifest.permission.WRITE_CALENDAR) != PackageManager.PERMISSION_GRANTED) {
            throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Calendar write permission denied. Required: WRITE_CALENDAR")
        }
    }

    private fun parseIsoToMillis(iso: String): Long {
        val zdt = ZonedDateTime.parse(iso, isoFormatter)
        return zdt.toInstant().toEpochMilli()
    }

    private fun millisToIso(millis: Long): String {
        return Instant.ofEpochMilli(millis).toString()
    }

    override suspend fun getCalendars(): List<CalendarData> {
        requireReadPermission()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.CALENDAR_COLOR,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL
        )

        val calendars = mutableListOf<CalendarData>()
        contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
            val colorIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_COLOR)
            val accessIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex).toString()
                val title = cursor.getString(nameIndex) ?: ""
                val color = cursor.getInt(colorIndex)
                val accessLevel = cursor.getInt(accessIndex)
                val isReadOnly = accessLevel < CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR

                calendars.add(
                    CalendarData(
                        id = id,
                        title = title,
                        color = String.format("#%06X", 0xFFFFFF and color),
                        isReadOnly = isReadOnly
                    )
                )
            }
        }
        return calendars
    }

    override suspend fun getEvents(calendarId: String?, from: String, to: String): List<CalendarEventData> {
        requireReadPermission()
        val startMillis = parseIsoToMillis(from)
        val endMillis = parseIsoToMillis(to)

        val projection = arrayOf(
            CalendarContract.Events._ID,
            CalendarContract.Events.CALENDAR_ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DTSTART,
            CalendarContract.Events.DTEND,
            CalendarContract.Events.EVENT_LOCATION,
            CalendarContract.Events.DESCRIPTION,
            CalendarContract.Events.ALL_DAY
        )

        var selection = "${CalendarContract.Events.DTSTART} >= ? AND ${CalendarContract.Events.DTEND} <= ?"
        val selectionArgs = mutableListOf(startMillis.toString(), endMillis.toString())

        if (calendarId != null) {
            selection += " AND ${CalendarContract.Events.CALENDAR_ID} = ?"
            selectionArgs.add(calendarId)
        }

        val events = mutableListOf<CalendarEventData>()
        contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            projection,
            selection,
            selectionArgs.toTypedArray(),
            "${CalendarContract.Events.DTSTART} ASC"
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events._ID)
            val calIdIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID)
            val titleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.TITLE)
            val startIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.DTSTART)
            val endIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.DTEND)
            val locationIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.EVENT_LOCATION)
            val descIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION)
            val allDayIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)

            while (cursor.moveToNext()) {
                events.add(
                    CalendarEventData(
                        id = cursor.getLong(idIndex).toString(),
                        calendarId = cursor.getLong(calIdIndex).toString(),
                        title = cursor.getString(titleIndex) ?: "",
                        startDate = millisToIso(cursor.getLong(startIndex)),
                        endDate = millisToIso(cursor.getLong(endIndex)),
                        location = cursor.getString(locationIndex),
                        notes = cursor.getString(descIndex),
                        isAllDay = cursor.getInt(allDayIndex) == 1
                    )
                )
            }
        }
        return events
    }

    override suspend fun getEvent(id: String): CalendarEventData {
        requireReadPermission()
        val projection = arrayOf(
            CalendarContract.Events._ID,
            CalendarContract.Events.CALENDAR_ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DTSTART,
            CalendarContract.Events.DTEND,
            CalendarContract.Events.EVENT_LOCATION,
            CalendarContract.Events.DESCRIPTION,
            CalendarContract.Events.ALL_DAY
        )

        val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id.toLong())
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                return CalendarEventData(
                    id = cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Events._ID)).toString(),
                    calendarId = cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID)).toString(),
                    title = cursor.getString(cursor.getColumnIndexOrThrow(CalendarContract.Events.TITLE)) ?: "",
                    startDate = millisToIso(cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Events.DTSTART))),
                    endDate = millisToIso(cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Events.DTEND))),
                    location = cursor.getString(cursor.getColumnIndexOrThrow(CalendarContract.Events.EVENT_LOCATION)),
                    notes = cursor.getString(cursor.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION)),
                    isAllDay = cursor.getInt(cursor.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)) == 1
                )
            }
        }
        throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Event not found: $id")
    }

    override suspend fun createEvent(
        calendarId: String?,
        title: String,
        startDate: String,
        endDate: String,
        location: String?,
        notes: String?,
        isAllDay: Boolean
    ): String {
        requireWritePermission()
        val values = ContentValues().apply {
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DTSTART, parseIsoToMillis(startDate))
            put(CalendarContract.Events.DTEND, parseIsoToMillis(endDate))
            put(CalendarContract.Events.ALL_DAY, if (isAllDay) 1 else 0)
            put(CalendarContract.Events.EVENT_TIMEZONE, java.util.TimeZone.getDefault().id)
            location?.let { put(CalendarContract.Events.EVENT_LOCATION, it) }
            notes?.let { put(CalendarContract.Events.DESCRIPTION, it) }
            if (calendarId != null) {
                put(CalendarContract.Events.CALENDAR_ID, calendarId.toLong())
            } else {
                put(CalendarContract.Events.CALENDAR_ID, getDefaultCalendarId())
            }
        }

        val uri = contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Failed to create event")
        return ContentUris.parseId(uri).toString()
    }

    override suspend fun updateEvent(
        id: String,
        title: String?,
        startDate: String?,
        endDate: String?,
        location: String?,
        notes: String?,
        isAllDay: Boolean?
    ) {
        requireWritePermission()
        val values = ContentValues().apply {
            title?.let { put(CalendarContract.Events.TITLE, it) }
            startDate?.let { put(CalendarContract.Events.DTSTART, parseIsoToMillis(it)) }
            endDate?.let { put(CalendarContract.Events.DTEND, parseIsoToMillis(it)) }
            location?.let { put(CalendarContract.Events.EVENT_LOCATION, it) }
            notes?.let { put(CalendarContract.Events.DESCRIPTION, it) }
            isAllDay?.let { put(CalendarContract.Events.ALL_DAY, if (it) 1 else 0) }
        }

        val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id.toLong())
        contentResolver.update(uri, values, null, null)
    }

    override suspend fun deleteEvent(id: String) {
        requireWritePermission()
        val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id.toLong())
        contentResolver.delete(uri, null, null)
    }

    override suspend fun createReminder(title: String, dueDate: String?, notes: String?): String {
        val eventId = createEvent(
            calendarId = null,
            title = title,
            startDate = dueDate ?: Instant.now().toString(),
            endDate = dueDate ?: Instant.now().toString(),
            location = null,
            notes = notes,
            isAllDay = false
        )

        if (dueDate != null) {
            val reminderValues = ContentValues().apply {
                put(CalendarContract.Reminders.EVENT_ID, eventId.toLong())
                put(CalendarContract.Reminders.MINUTES, 0)
                put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
            }
            contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, reminderValues)
        }

        return eventId
    }

    override suspend fun requestPermission(): Boolean {
        return context.checkSelfPermission(
            android.Manifest.permission.READ_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
    }

    override suspend fun getPermissionStatus(): String {
        val readGranted = context.checkSelfPermission(
            android.Manifest.permission.READ_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED

        return if (readGranted) "granted" else "denied"
    }

    private fun getDefaultCalendarId(): Long {
        val projection = arrayOf(CalendarContract.Calendars._ID)
        val selection = "${CalendarContract.Calendars.IS_PRIMARY} = 1"

        contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(0)
            }
        }

        // Fallback: get first available calendar
        contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(0)
            }
        }

        throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "No calendar found on device")
    }
}
