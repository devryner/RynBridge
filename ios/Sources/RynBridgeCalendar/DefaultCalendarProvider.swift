import Foundation
import EventKit
import RynBridge

#if canImport(UIKit)
import UIKit
#endif

public final class DefaultCalendarProvider: CalendarProvider, @unchecked Sendable {
    private let eventStore: EKEventStore
    private let dateFormatter: ISO8601DateFormatter

    public init() {
        self.eventStore = EKEventStore()
        self.dateFormatter = ISO8601DateFormatter()
    }

    public func getCalendars() async throws -> [CalendarData] {
        let calendars = eventStore.calendars(for: .event)
        return calendars.map { calendar in
            CalendarData(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: calendar.cgColor.flatMap { cgColor in
                    #if canImport(UIKit)
                    return UIColor(cgColor: cgColor).hexString
                    #else
                    return nil
                    #endif
                },
                isReadOnly: !calendar.allowsContentModifications
            )
        }
    }

    public func getEvents(calendarId: String?, from: String, to: String) async throws -> [CalendarEventData] {
        guard let startDate = dateFormatter.date(from: from) else {
            throw RynBridgeError(code: .invalidMessage, message: "Invalid date format for 'from': \(from)")
        }
        guard let endDate = dateFormatter.date(from: to) else {
            throw RynBridgeError(code: .invalidMessage, message: "Invalid date format for 'to': \(to)")
        }

        var calendars: [EKCalendar]? = nil
        if let calendarId {
            if let calendar = eventStore.calendar(withIdentifier: calendarId) {
                calendars = [calendar]
            } else {
                throw RynBridgeError(code: .invalidMessage, message: "Calendar not found: \(calendarId)")
            }
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        return events.map { event in
            CalendarEventData(
                id: event.eventIdentifier,
                calendarId: event.calendar.calendarIdentifier,
                title: event.title ?? "",
                startDate: dateFormatter.string(from: event.startDate),
                endDate: dateFormatter.string(from: event.endDate),
                location: event.location,
                notes: event.notes,
                isAllDay: event.isAllDay
            )
        }
    }

    public func getEvent(id: String) async throws -> CalendarEventData {
        guard let event = eventStore.event(withIdentifier: id) else {
            throw RynBridgeError(code: .invalidMessage, message: "Event not found: \(id)")
        }
        return CalendarEventData(
            id: event.eventIdentifier,
            calendarId: event.calendar.calendarIdentifier,
            title: event.title ?? "",
            startDate: dateFormatter.string(from: event.startDate),
            endDate: dateFormatter.string(from: event.endDate),
            location: event.location,
            notes: event.notes,
            isAllDay: event.isAllDay
        )
    }

    public func createEvent(calendarId: String?, title: String, startDate: String, endDate: String, location: String?, notes: String?, isAllDay: Bool) async throws -> String {
        guard let start = dateFormatter.date(from: startDate) else {
            throw RynBridgeError(code: .invalidMessage, message: "Invalid date format for 'startDate': \(startDate)")
        }
        guard let end = dateFormatter.date(from: endDate) else {
            throw RynBridgeError(code: .invalidMessage, message: "Invalid date format for 'endDate': \(endDate)")
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.location = location
        event.notes = notes
        event.isAllDay = isAllDay

        if let calendarId {
            guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
                throw RynBridgeError(code: .invalidMessage, message: "Calendar not found: \(calendarId)")
            }
            event.calendar = calendar
        } else {
            event.calendar = eventStore.defaultCalendarForNewEvents
        }

        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    public func updateEvent(id: String, title: String?, startDate: String?, endDate: String?, location: String?, notes: String?, isAllDay: Bool?) async throws {
        guard let event = eventStore.event(withIdentifier: id) else {
            throw RynBridgeError(code: .invalidMessage, message: "Event not found: \(id)")
        }

        if let title { event.title = title }
        if let startDate {
            guard let date = dateFormatter.date(from: startDate) else {
                throw RynBridgeError(code: .invalidMessage, message: "Invalid date format for 'startDate': \(startDate)")
            }
            event.startDate = date
        }
        if let endDate {
            guard let date = dateFormatter.date(from: endDate) else {
                throw RynBridgeError(code: .invalidMessage, message: "Invalid date format for 'endDate': \(endDate)")
            }
            event.endDate = date
        }
        if let location { event.location = location }
        if let notes { event.notes = notes }
        if let isAllDay { event.isAllDay = isAllDay }

        try eventStore.save(event, span: .thisEvent)
    }

    public func deleteEvent(id: String) async throws {
        guard let event = eventStore.event(withIdentifier: id) else {
            throw RynBridgeError(code: .invalidMessage, message: "Event not found: \(id)")
        }
        try eventStore.remove(event, span: .thisEvent)
    }

    public func createReminder(title: String, dueDate: String?, notes: String?) async throws -> String {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        if let dueDate, let date = dateFormatter.date(from: dueDate) {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            reminder.dueDateComponents = components
        }

        try eventStore.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }

    public func requestPermission() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await eventStore.requestAccess(to: .event)
        }
    }

    public func getPermissionStatus() async throws -> String {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess:
            return "granted"
        case .denied, .restricted, .writeOnly:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        @unknown default:
            return "notDetermined"
        }
    }
}

#if canImport(UIKit)
private extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
#endif
