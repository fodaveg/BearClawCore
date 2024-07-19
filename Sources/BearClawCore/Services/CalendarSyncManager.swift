import Foundation

#if canImport(ServiceManagement)
import ServiceManagement
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public class CalendarSyncManager: NSObject, ObservableObject {
    public static let shared = CalendarSyncManager()
    let noteManager = NoteManager.shared
    var updateTimer: Timer?

    public func updateHomeNoteWithCurrentDateEvents() {
        let dateString = getCurrentDateString()
        let events = noteManager.calendarManager.fetchCalendarEvents(for: dateString)
        noteManager.bearManager.createNoteWithContent(events)
    }

    @objc public func syncNow() {
        let calendar = Calendar.current
        let today = Date()
        for i in -7...7 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                let formattedDate = DateUtils.getCurrentDateFormatted(date: date)
                syncCalendarForDate(formattedDate)
            }
        }
    }

    public func syncCalendarForDate(_ date: String?) {
        let date = date ?? DateUtils.getCurrentDateFormatted()
        let fetchURLString = "bear://x-callback-url/open-note?title=\(date)&show_window=no&open_note=no&x-success=fodabear://update-daily-note-if-needed-success-for-sync"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching daily note with URL: \(fetchURL)")
            openURL(fetchURL)
        }
    }

    public func scheduleCalendarUpdates() {}

    public func getDateString(forDaysBefore daysBefore: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        let date = Calendar.current.date(byAdding: .day, value: -daysBefore, to: Date())!
        return formatter.string(from: date)
    }

    public func getDateString(forDaysAfter daysAfter: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        let date = Calendar.current.date(byAdding: .day, value: daysAfter, to: Date())!
        return formatter.string(from: date)
    }

    public func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        return formatter.string(from: Date())
    }

    private func openURL(_ url: URL) {
        #if canImport(AppKit)
        NSWorkspace.shared.open(url)
        #elseif canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #endif
    }
}
