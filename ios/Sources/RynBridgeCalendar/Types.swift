import Foundation
import RynBridge

public struct CalendarData: Sendable {
    public let id: String
    public let title: String
    public let color: String?
    public let isReadOnly: Bool

    public init(id: String, title: String, color: String?, isReadOnly: Bool) {
        self.id = id
        self.title = title
        self.color = color
        self.isReadOnly = isReadOnly
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "id": .string(id),
            "title": .string(title),
            "color": color.map { .string($0) } ?? .null,
            "isReadOnly": .bool(isReadOnly),
        ]
    }
}

public struct CalendarEventData: Sendable {
    public let id: String
    public let calendarId: String
    public let title: String
    public let startDate: String
    public let endDate: String
    public let location: String?
    public let notes: String?
    public let isAllDay: Bool

    public init(id: String, calendarId: String, title: String, startDate: String, endDate: String, location: String?, notes: String?, isAllDay: Bool) {
        self.id = id
        self.calendarId = calendarId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.isAllDay = isAllDay
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "id": .string(id),
            "calendarId": .string(calendarId),
            "title": .string(title),
            "startDate": .string(startDate),
            "endDate": .string(endDate),
            "location": location.map { .string($0) } ?? .null,
            "notes": notes.map { .string($0) } ?? .null,
            "isAllDay": .bool(isAllDay),
        ]
    }
}

public struct CreateEventResult: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    public func toPayload() -> [String: AnyCodable] {
        ["id": .string(id)]
    }
}

public struct CreateReminderResult: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    public func toPayload() -> [String: AnyCodable] {
        ["id": .string(id)]
    }
}

public struct PermissionResult: Sendable {
    public let granted: Bool

    public init(granted: Bool) {
        self.granted = granted
    }

    public func toPayload() -> [String: AnyCodable] {
        ["granted": .bool(granted)]
    }
}

public struct PermissionStatus: Sendable {
    public let status: String

    public init(status: String) {
        self.status = status
    }

    public func toPayload() -> [String: AnyCodable] {
        ["status": .string(status)]
    }
}

public protocol CalendarProvider: Sendable {
    func getCalendars() async throws -> [CalendarData]
    func getEvents(calendarId: String?, from: String, to: String) async throws -> [CalendarEventData]
    func getEvent(id: String) async throws -> CalendarEventData
    func createEvent(calendarId: String?, title: String, startDate: String, endDate: String, location: String?, notes: String?, isAllDay: Bool) async throws -> String
    func updateEvent(id: String, title: String?, startDate: String?, endDate: String?, location: String?, notes: String?, isAllDay: Bool?) async throws
    func deleteEvent(id: String) async throws
    func createReminder(title: String, dueDate: String?, notes: String?) async throws -> String
    func requestPermission() async throws -> Bool
    func getPermissionStatus() async throws -> String
}
