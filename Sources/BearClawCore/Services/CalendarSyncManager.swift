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
    public static let shared = CalendarSyncManager(calendarManager: CalendarManager.shared)
    lazy var noteManager = NoteManager.shared
    private let calendarManager: CalendarManager
    
    // var updateTimer: Timer?
    
    public init(calendarManager: CalendarManager = .shared) {
        self.calendarManager = calendarManager
        super.init()
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
    
    private func openURL(_ url: URL) {
#if canImport(AppKit)
        NSWorkspace.shared.open(url)
#elseif canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
#endif
    }
}
