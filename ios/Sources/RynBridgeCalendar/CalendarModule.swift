import Foundation
import RynBridge

public struct CalendarModule: BridgeModule, Sendable {
    public let name = "calendar"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: CalendarProvider) {
        actions = [
            "getCalendars": { _ in
                let calendars = try await provider.getCalendars()
                return ["calendars": .array(calendars.map { calendar in
                    .dictionary(calendar.toPayload())
                })]
            },
            "getEvents": { payload in
                let calendarId = payload["calendarId"]?.stringValue
                guard let from = payload["from"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: from")
                }
                guard let to = payload["to"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: to")
                }
                let events = try await provider.getEvents(calendarId: calendarId, from: from, to: to)
                return ["events": .array(events.map { event in
                    .dictionary(event.toPayload())
                })]
            },
            "getEvent": { payload in
                guard let id = payload["id"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: id")
                }
                let event = try await provider.getEvent(id: id)
                return event.toPayload()
            },
            "createEvent": { payload in
                let calendarId = payload["calendarId"]?.stringValue
                guard let title = payload["title"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: title")
                }
                guard let startDate = payload["startDate"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: startDate")
                }
                guard let endDate = payload["endDate"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: endDate")
                }
                let location = payload["location"]?.stringValue
                let notes = payload["notes"]?.stringValue
                let isAllDay = payload["isAllDay"]?.boolValue ?? false
                let id = try await provider.createEvent(calendarId: calendarId, title: title, startDate: startDate, endDate: endDate, location: location, notes: notes, isAllDay: isAllDay)
                return CreateEventResult(id: id).toPayload()
            },
            "updateEvent": { payload in
                guard let id = payload["id"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: id")
                }
                let title = payload["title"]?.stringValue
                let startDate = payload["startDate"]?.stringValue
                let endDate = payload["endDate"]?.stringValue
                let location = payload["location"]?.stringValue
                let notes = payload["notes"]?.stringValue
                let isAllDay = payload["isAllDay"]?.boolValue
                try await provider.updateEvent(id: id, title: title, startDate: startDate, endDate: endDate, location: location, notes: notes, isAllDay: isAllDay)
                return [:]
            },
            "deleteEvent": { payload in
                guard let id = payload["id"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: id")
                }
                try await provider.deleteEvent(id: id)
                return [:]
            },
            "createReminder": { payload in
                guard let title = payload["title"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: title")
                }
                let dueDate = payload["dueDate"]?.stringValue
                let notes = payload["notes"]?.stringValue
                let id = try await provider.createReminder(title: title, dueDate: dueDate, notes: notes)
                return CreateReminderResult(id: id).toPayload()
            },
            "requestPermission": { _ in
                let granted = try await provider.requestPermission()
                return PermissionResult(granted: granted).toPayload()
            },
            "getPermissionStatus": { _ in
                let status = try await provider.getPermissionStatus()
                return PermissionStatus(status: status).toPayload()
            },
        ]
    }
}

#if canImport(UIKit)
extension CalendarModule {
    public init() {
        self.init(provider: DefaultCalendarProvider())
    }
}
#endif
