import EventKit
import Foundation
import SwiftUI

public class CalendarManager: ObservableObject {
    @Published public var selectedCalendarIDs: [String] = [] {
        didSet {
            if selectedCalendarIDs != oldValue {
                DispatchQueue.main.async {
                    SettingsManager.shared.selectedCalendarIDsArray =
                        self.selectedCalendarIDs
                }
                objectWillChange.send()
            }
        }
    }

    @MainActor public static let shared = CalendarManager()
    //  let calendarSyncManager = CalendarSyncManager.shared
    let eventStore = EKEventStore()

    @Published public var isAuthorized: Bool = false

    public init() {
        self.selectedCalendarIDs =
            SettingsManager.shared.selectedCalendarIDsArray
        NotificationCenter.default.addObserver(
            self, selector: #selector(settingsChanged),
            name: UserDefaults.didChangeNotification, object: nil)
        checkCalendarAuthorizationStatus()
    }

    @objc private func settingsChanged() {
        let newSelection = SettingsManager.shared.selectedCalendarIDsArray
        if Set(self.selectedCalendarIDs) != Set(newSelection) {
            self.selectedCalendarIDs = newSelection
        }
    }

    public func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.isAuthorized = (status == .fullAccess)
        }
    }

    public func requestCalendarAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized, .fullAccess:
            return true
        case .denied, .restricted, .writeOnly:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                self.eventStore.requestFullAccessToEvents { granted, error in
                    DispatchQueue.main.async {
                        self.isAuthorized = granted
                        continuation.resume(returning: granted)
                    }
                }
            }
        @unknown default:
            return false
        }
    }

    public func fetchEvents(
        startDate: Date, endDate: Date, calendars: [EKCalendar]
    ) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(
            withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
    }

    public func getCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }

    public func selectedCalendars() -> [EKCalendar] {
        let calendars = eventStore.calendars(for: .event)
        return calendars.filter {
            selectedCalendarIDs.contains($0.calendarIdentifier)
        }
    }

    var previousOutput: String = ""

    public func fetchCalendarEvents(
        for dateString: String, calendars: [EKCalendar]
    ) -> String {
        guard !calendars.isEmpty else {
            print("Warning: No calendars selected")
            return "No events scheduled for this day."
        }

        guard let startDate = getDate(from: dateString) else {
            print("Error: Invalid date format")
            return "Error: Invalid date format"
        }

        let endDate = Calendar.current.date(
            byAdding: .day, value: 1, to: startDate)!

        print(
            "Fetching events for date: \(dateString), using calendars: \(calendars.map { $0.title })"
        )

        let predicate = eventStore.predicateForEvents(
            withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        if events.isEmpty {
            print("No events found for the specified date")
            if previousOutput.isEmpty
                || previousOutput == "No events scheduled for this day."
            {
                previousOutput = "No events scheduled for this day."
            }
            return previousOutput
        } else {

            let now = Date()
            let formattedEvents = events.map { event in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                let startTimeString = formatter.string(from: event.startDate)
                let endTimeString = formatter.string(from: event.endDate)

                let status = event.endDate < now ? "x" : " "

                return
                    "- [\(status)] \(startTimeString) - \(endTimeString): \(event.title ?? "")"
            }.joined(separator: "\n")
            previousOutput = formattedEvents
        }

        return previousOutput
    }

    private func getDate(from dateString: String) -> Date? {
        let dateFormat = SettingsManager.shared.selectedDateFormat

        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        if let date = formatter.date(from: dateString) {
            return date
        }

        print("Failed to parse date: \(dateString) with format: \(dateFormat)")
        return nil
    }

    func extractDate(from text: String, withFormat dateFormat: String)
        -> String?
    {
        let regexPattern = regexFromDateFormat(dateFormat)

        guard
            let regex = try? NSRegularExpression(
                pattern: regexPattern, options: [])
        else {
            print(
                "Error al crear la expresión regular con el patrón: \(regexPattern)"
            )
            return nil
        }

        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let dateRange = Range(match.range, in: text) {
                let dateString = String(text[dateRange])
                return dateString
            }
        }

        return nil
    }

    func regexFromDateFormat(_ dateFormat: String) -> String {
        var regexPattern = NSRegularExpression.escapedPattern(for: dateFormat)

        let tokenMap: [String: String] = [
            "yyyy": "(\\d{4})",
            "yy": "(\\d{2})",
            "MM": "(0[1-9]|1[0-2])",
            "M": "(0?[1-9]|1[0-2])",
            "dd": "(0[1-9]|[12]\\d|3[01])",
            "d": "([1-9]|[12]\\d|3[01])",
            "HH": "([01]\\d|2[0-3])",
            "H": "(0?\\d|1\\d|2[0-3])",
            "mm": "([0-5]\\d)",
            "m": "([1-5]?\\d)",
            "ss": "([0-5]\\d)",
            "s": "([1-5]?\\d)",
        ]

        for (token, regex) in tokenMap {
            regexPattern = regexPattern.replacingOccurrences(
                of: NSRegularExpression.escapedPattern(for: token), with: regex)
        }

        return "^" + regexPattern + "$"
    }

    public func reloadCalendarConfiguration() {
        let savedIDs = SettingsManager.shared.selectedCalendarIDsArray
        if selectedCalendarIDs != savedIDs {
            selectedCalendarIDs = savedIDs
        }
    }

}
