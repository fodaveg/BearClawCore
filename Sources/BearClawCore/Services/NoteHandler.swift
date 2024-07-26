#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

import Foundation
import Combine


public class NoteHandler: NSObject, ObservableObject {
    public static let shared = NoteHandler()
    var bearManager = BearManager.shared
    var templateManager = TemplateManager.shared
    @Published var currentTodayDateString: String?
    @Published var currentHomeNoteID: String?
    @Published var currentDailyNoteID: String?
    
    @objc public func openHomeNote() {
        print("Opening home note")
        let homeNoteID = SettingsManager.shared.homeNoteID
        updateHomeNoteIfNeeded()
        if let url = URL(string: "bear://x-callback-url/open-note?id=\(homeNoteID)") {
            openURL(url)
        }
    }
    
    @objc public func syncCalendarForDate(_ date: String?) {
        let date = date ?? getCurrentDateFormatted()
        let fetchURLString = "bear://x-callback-url/open-note?title=\(date)&show_window=no&open_note=no&x-success=fodabear://update-daily-note-if-needed-success-for-sync"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching daily note with URL: \(fetchURL)")
            openURL(fetchURL)
        }
    }
    
    @objc func syncNoteById(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            let noteId = queryItems.first(where: { $0.name == "id" })?.value
            
            let fetchURLString = "bear://x-callback-url/open-note?id=\(noteId ?? "")&show_window=no&open_note=no&x-success=fodabear://update-daily-note-if-needed-success-for-sync"
            
            if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                print("Fetching note with URL: \(fetchURL)")
                openURL(fetchURL)
            }
        }
    }
    
    @objc public func updateHomeNoteIfNeeded() {
        let homeNoteId = SettingsManager.shared.homeNoteID
        let fetchURLString = "bear://x-callback-url/open-note?id=\(homeNoteId)&show_window=no&open_note=no&x-success=fodabear://update-home-note-if-needed-success&x-error=fodabear://update-home-note-if-needed-error"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching home note with URL: \(fetchURL)")
            openURL(fetchURL)
        }
    }
    
    @objc public func updateDailyNoteIfNeeded(_ date: String?) {
        let currentDateFormatted = getCurrentDateFormatted()
        let fetchURLString = "bear://x-callback-url/open-note?title=\(date ?? currentDateFormatted)&show_window=no&open_note=no&x-success=fodabear://update-daily-note-if-needed-success"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching daily note with URL: \(fetchURL)")
            openURL(fetchURL)
        }
    }
    
    @objc public func updateDailyNoteIfNeededError(url: URL) {}
    
    @objc public func updateDailyNoteIfNeededSuccess(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        
        guard let title = queryItems.first(where: { $0.name == "title" })?.value,
              let note = queryItems.first(where: { $0.name == "note" })?.value,
              let id = queryItems.first(where: { $0.name == "identifier" })?.value else { return }
        
        DispatchQueue.main.async {
            NoteManager.shared.updateDailyNoteWithCalendarEvents(for: title, noteContent: note, noteId: id)
        }
    }
    
    @objc public func updateDailyNoteIfNeededSuccessForSync(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        
        guard let title = queryItems.first(where: { $0.name == "title" })?.value,
              let note = queryItems.first(where: { $0.name == "note" })?.value,
              let id = queryItems.first(where: { $0.name == "identifier" })?.value else { return }
        
        DispatchQueue.main.async {
            NoteManager.shared.updateDailyNoteWithCalendarEvents(for: title, noteContent: note, noteId: id, open: false)
        }
    }
    
    @objc public func updateNoteAndOpen(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        
        guard let title = queryItems.first(where: { $0.name == "title" })?.value else { return }
        guard let note = queryItems.first(where: { $0.name == "note" })?.value else { return }
        guard let id = queryItems.first(where: { $0.name == "identifier" })?.value else { return }
        NoteManager.shared.updateDailyNoteWithCalendarEvents(for: title, noteContent: note, noteId: id, open: true)
    }
    
    @objc public func openNoteForNoteAndOpen(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        guard let id = queryItems.first(where: { $0.name == "identifier" })?.value else { return }
        let fetchURLString = "bear://x-callback-url/open-note?id=\(id)&show_window=no&open_note=no&x-success=fodabear://replace-sync-placeholder-action"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching daily note with URL: \(fetchURL)")
            openURL(fetchURL)
        }
    }
    
    
    @objc public func updateHomeNoteIfNeededSuccess(url: URL) {
        let homeNoteId = SettingsManager.shared.homeNoteID
        let currentDateFormatted = getCurrentDateFormatted()
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let note = queryItems.first(where: { $0.name == "note" })?.value else {
            return
        }
        
        DispatchQueue.main.async {
            NoteManager.shared.updateHomeNoteWithCalendarEvents(for: currentDateFormatted, noteContent: note, homeNoteId: homeNoteId)
        }
    }
    
    @objc public func updateHomeNoteIfNeededError(url: URL) {
        print("updateHomeNoteIfNeededError: \(url)")
    }
    
    public func testOk(url: URL) {
        print("URL OK: \(url)")
    }
    
    public func testKo(url: URL) {
        print("URL KO: \(url)")
    }
    
    @objc public func openDailyNoteForDate(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        guard let date = queryItems.first(where: { $0.name == "date" })?.value else { return }
        print("URL: \(url)")
        self.openDailyNoteWithDate(date)
    }
    
    @objc public func openDailyNote() {
        print("Opening daily note")
        let dateToday = getCurrentDateFormatted()
        let successParameter = "fodabear://open-daily-note-success"
        let errorParameter = "fodabear://open-daily-note-error"
        updateDailyNoteIfNeeded(dateToday)
        if let dailyUrl = URL(string: "bear://x-callback-url/open-note?title=\(dateToday)&open_note=no&show_window=no&exclude_trashed=yes&x-success=\(successParameter)&x-error=\(errorParameter)") {
            openURL(dailyUrl)
        }
    }
    
    @objc public func openDailyNoteSuccess(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            let dailyId = queryItems.first(where: { $0.name == "id" })?.value
            if let dailyUrl = URL(string: "bear://x-callback-url/open-note?id=\(String(describing: dailyId))") {
                openURL(dailyUrl)
            }
        }
    }
    
    @objc public func openDailyNoteError(url: URL) {
        createDailyNoteWithDateString(getCurrentDateFormatted())
    }
    
    @objc public func openDailyNoteWithDate(_ date: String?) {
        print("Opening daily note")
        let date = date ?? getCurrentDateFormatted()
        let successParameter = "fodabear://open-daily-note-with-date-success"
        let errorParameter = "fodabear://create-daily-note-for-date?date=\(date)"
        updateDailyNoteIfNeeded(date)
        if let dailyUrl = URL(string: "bear://x-callback-url/open-note?title=\(date)&open_note=no&show_window=no&exclude_trashed=yes&x-success=\(successParameter.addingPercentEncodingForRFC3986() ?? "")&x-error=\(errorParameter.addingPercentEncodingForRFC3986() ?? "")") {
            print("openDailyNoteWithDate: \(dailyUrl)")
            openURL(dailyUrl)
        }
    }
    
    @objc public func openDailyNoteWithDateSuccess(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            let dailyId = queryItems.first(where: { $0.name == "id" })?.value
            if let dailyUrl = URL(string: "bear://x-callback-url/open-note?id=\(String(describing: dailyId))") {
                openURL(dailyUrl)
            }
        }
    }
    
    @objc public func openDailyNoteWithDateError(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            let dailyDate = queryItems.first(where: { $0.name == "date" })?.value
            createDailyNoteWithDateString(dailyDate)
        }
    }
    
    @objc public func createDailyNoteWithDate(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        guard let date = queryItems.first(where: { $0.name == "date" })?.value else { return }
        self.createDailyNoteWithDateString(date)
    }
    
    @objc public func createDailyNoteWithDateString(_ date: String?) {
        
        let date = date.flatMap { $0 } ?? getCurrentDateFormatted()
        print(date)
        guard let template = SettingsManager.shared.loadTemplates().first(where: { $0.name == "Daily" }) else { return }
        print(template)
        
        let processedContent = templateManager.processTemplateVariables(template.content, for: date)
        print(processedContent)
        
        let tags = [template.tag]
        print(tags)
        
        let success = "fodabear://replace-sync-placeholder"
        
        let createURLString = "bear://x-callback-url/create?text=\(processedContent.addingPercentEncodingForRFC3986() ?? "")&tags=\(tags.joined(separator: ",").addingPercentEncodingForRFC3986() ?? "")&open_note=no&show_window=no&x-success=\(success.addingPercentEncodingForRFC3986() ?? "")"
        print(createURLString)
        if let fetchURL = URL(string: createURLString) {
            openURL(fetchURL)
        }
    }
    
    @objc public func getCurrentDateFormatted(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        return formatter.string(from: date)
    }
    
#if canImport(AppKit)
    @objc public func openTemplateNote(_ sender: NSMenuItem) {
        let templateTitle = sender.title
        let templateNameComponents = templateTitle.components(separatedBy: " ")
        
        guard templateNameComponents.count > 2 else { return }
        
        let templateName = templateNameComponents.dropFirst().dropLast().joined(separator: " ")
        
        guard let template = SettingsManager.shared.loadTemplates().first(where: { $0.name == templateName }) else { return }
        
        DispatchQueue.main.async {
            self.bearManager.openTemplate(template)
        }
    }
#endif
    
    private func openURL(_ url: URL) {
#if canImport(AppKit)
        NSWorkspace.shared.open(url)
#elseif canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
#endif
    }
}
