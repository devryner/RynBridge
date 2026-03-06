import XCTest
@testable import RynBridge
@testable import RynBridgeCalendar

final class CalendarModuleTests: XCTestCase {
    func testGetCalendars() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["getCalendars"]!

        let result = try await handler([:])
        let calendars = result["calendars"]?.arrayValue
        XCTAssertNotNil(calendars)
        XCTAssertEqual(calendars?.count, 1)
        let first = calendars?.first?.dictionaryValue
        XCTAssertEqual(first?["id"]?.stringValue, "cal-1")
        XCTAssertEqual(first?["title"]?.stringValue, "Personal")
        XCTAssertEqual(first?["color"]?.stringValue, "#FF0000")
        XCTAssertEqual(first?["isReadOnly"]?.boolValue, false)
    }

    func testGetEvents() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["getEvents"]!

        let result = try await handler([
            "calendarId": .string("cal-1"),
            "from": .string("2026-01-01"),
            "to": .string("2026-12-31"),
        ])
        let events = result["events"]?.arrayValue
        XCTAssertNotNil(events)
        XCTAssertEqual(events?.count, 1)
        let first = events?.first?.dictionaryValue
        XCTAssertEqual(first?["id"]?.stringValue, "event-1")
        XCTAssertEqual(first?["title"]?.stringValue, "Meeting")
    }

    func testGetEvent() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["getEvent"]!

        let result = try await handler(["id": .string("event-1")])
        XCTAssertEqual(result["id"]?.stringValue, "event-1")
        XCTAssertEqual(result["title"]?.stringValue, "Meeting")
        XCTAssertEqual(result["calendarId"]?.stringValue, "cal-1")
        XCTAssertEqual(result["startDate"]?.stringValue, "2026-03-06T10:00:00Z")
        XCTAssertEqual(result["endDate"]?.stringValue, "2026-03-06T11:00:00Z")
        XCTAssertEqual(result["isAllDay"]?.boolValue, false)
    }

    func testCreateEvent() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["createEvent"]!

        let result = try await handler([
            "calendarId": .string("cal-1"),
            "title": .string("New Event"),
            "startDate": .string("2026-03-06T10:00:00Z"),
            "endDate": .string("2026-03-06T11:00:00Z"),
            "location": .string("Office"),
            "notes": .string("Important meeting"),
            "isAllDay": .bool(false),
        ])
        XCTAssertEqual(result["id"]?.stringValue, "new-event-id")
        XCTAssertEqual(provider.lastCreatedTitle, "New Event")
    }

    func testUpdateEvent() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["updateEvent"]!

        let result = try await handler([
            "id": .string("event-1"),
            "title": .string("Updated Event"),
        ])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastUpdatedId, "event-1")
        XCTAssertEqual(provider.lastUpdatedTitle, "Updated Event")
    }

    func testDeleteEvent() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["deleteEvent"]!

        let result = try await handler(["id": .string("event-1")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastDeletedId, "event-1")
    }

    func testCreateReminder() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["createReminder"]!

        let result = try await handler([
            "title": .string("Buy groceries"),
            "dueDate": .string("2026-03-07T09:00:00Z"),
            "notes": .string("Milk and eggs"),
        ])
        XCTAssertEqual(result["id"]?.stringValue, "new-reminder-id")
        XCTAssertEqual(provider.lastReminderTitle, "Buy groceries")
    }

    func testRequestPermission() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        let result = try await handler([:])
        XCTAssertEqual(result["granted"]?.boolValue, true)
    }

    func testGetPermissionStatus() async throws {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        let handler = module.actions["getPermissionStatus"]!

        let result = try await handler([:])
        XCTAssertEqual(result["status"]?.stringValue, "authorized")
    }

    func testModuleNameAndVersion() {
        let provider = MockCalendarProvider()
        let module = CalendarModule(provider: provider)
        XCTAssertEqual(module.name, "calendar")
        XCTAssertEqual(module.version, "0.1.0")
    }
}

private final class MockCalendarProvider: CalendarProvider, @unchecked Sendable {
    var lastCreatedTitle: String?
    var lastUpdatedId: String?
    var lastUpdatedTitle: String?
    var lastDeletedId: String?
    var lastReminderTitle: String?

    func getCalendars() async throws -> [CalendarData] {
        [
            CalendarData(id: "cal-1", title: "Personal", color: "#FF0000", isReadOnly: false),
        ]
    }

    func getEvents(calendarId: String?, from: String, to: String) async throws -> [CalendarEventData] {
        [
            CalendarEventData(
                id: "event-1",
                calendarId: "cal-1",
                title: "Meeting",
                startDate: "2026-03-06T10:00:00Z",
                endDate: "2026-03-06T11:00:00Z",
                location: "Office",
                notes: nil,
                isAllDay: false
            ),
        ]
    }

    func getEvent(id: String) async throws -> CalendarEventData {
        CalendarEventData(
            id: id,
            calendarId: "cal-1",
            title: "Meeting",
            startDate: "2026-03-06T10:00:00Z",
            endDate: "2026-03-06T11:00:00Z",
            location: "Office",
            notes: nil,
            isAllDay: false
        )
    }

    func createEvent(calendarId: String?, title: String, startDate: String, endDate: String, location: String?, notes: String?, isAllDay: Bool) async throws -> String {
        lastCreatedTitle = title
        return "new-event-id"
    }

    func updateEvent(id: String, title: String?, startDate: String?, endDate: String?, location: String?, notes: String?, isAllDay: Bool?) async throws {
        lastUpdatedId = id
        lastUpdatedTitle = title
    }

    func deleteEvent(id: String) async throws {
        lastDeletedId = id
    }

    func createReminder(title: String, dueDate: String?, notes: String?) async throws -> String {
        lastReminderTitle = title
        return "new-reminder-id"
    }

    func requestPermission() async throws -> Bool {
        true
    }

    func getPermissionStatus() async throws -> String {
        "authorized"
    }
}
