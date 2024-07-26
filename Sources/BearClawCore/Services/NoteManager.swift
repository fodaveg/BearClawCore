import Foundation
#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

import EventKit


public class NoteManager: ObservableObject {
    public static let shared = NoteManager()
    public var calendarManager = CalendarManager()
    public var templateManager = TemplateManager()
    public var bearManager = BearManager()
    
    public init() {}  
    
    var noteContent: String?
    let semaphore = DispatchSemaphore(value: 0)
    
    public func createDailyNoteForDate(selectedDate: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        let dateString = formatter.string(from: selectedDate)
        
        getDailyNoteID(for: dateString) { noteContent in
            if noteContent.isEmpty {
                self.templateManager.createDailyNoteWithTemplate(for: dateString)
            } else {
                //self.updateDailyNoteWithCalendarEvents(for: dateString)
            }
        }
    }
    
    
    
    public func getDailyNoteID(for dateString: String, completion: @escaping (String) -> Void) {
        let searchText = dateString
        
        let tag = UserDefaults.standard.string(forKey: "dailyNoteTag")?.addingPercentEncodingForRFC3986() ?? ""
        
        let searchURLString = "bear://x-callback-url/search?term=\(searchText)&tag=\(tag)&x-success=fodabear://open-note-success&x-error=fodabear://open-note-error&token=XXXXX"
        if let searchURL = URL(string: searchURLString) {
            print("Searching daily note with URL: \(searchURL)")
            openURL(searchURL)
            DispatchQueue.global().async {
                let result = self.semaphore.wait(timeout: .now() + 10)
                if result == .success {
                    print("Daily note search succeeded")
                    completion(self.noteContent ?? "")
                } else {
                    print("Daily note search timed out")
                    completion("")
                }
            }
        }
    }
    
    public func updateDailyNoteWithCalendarEvents(for dateString: String, noteContent: String, noteId: String, open: Bool = true) {
        let selectedCalendars = calendarManager.selectedCalendars()
        print("Updating daily note with events from selected calendars: \(selectedCalendars.map { $0.title })")
        let events = calendarManager.fetchCalendarEvents(for: dateString, calendars: selectedCalendars)
        let cleanedEvents = events.replacingOccurrences(of: "Optional(\"", with: "").replacingOccurrences(of: "\")", with: "")
        
        print("update daily calendar: \(events)")
        var updatedContent = self.templateManager.replaceCalendarSection(in: noteContent, with: cleanedEvents)
        updatedContent = self.templateManager.replaceSyncSection(in: updatedContent, id: noteId)
        
        DispatchQueue.main.async {
            self.bearManager.updateNoteContent(newContent: updatedContent, noteID: noteId, open: open, show: open)
        }
    }
    
    public func updateHomeNoteWithCalendarEvents(for dateString: String, noteContent: String, homeNoteId: String) {
        let selectedCalendars = calendarManager.selectedCalendars()
        let events = calendarManager.fetchCalendarEvents(for: dateString, calendars: selectedCalendars)
        let cleanedEvents = events.replacingOccurrences(of: "Optional(\"", with: "").replacingOccurrences(of: "\")", with: "")
        
        let updatedContent = templateManager.replaceDailySection(in: noteContent, with: dateString)
        let fullyUpdatedContent = templateManager.replaceCalendarSection(in: updatedContent, with: cleanedEvents)
        bearManager.updateNoteContent(newContent: fullyUpdatedContent, noteID: homeNoteId, open: false, show: false)
    }
    
    public func getCurrentDateFormatted(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        return formatter.string(from: date)
    }
    
    private func openURL(_ url: URL) {
#if canImport(AppKit)
        NSWorkspace.shared.open(url)
#elseif canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
#endif
    }
}
