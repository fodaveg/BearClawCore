import Foundation
#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif


public class TemplateManager {
    public static let shared = TemplateManager()
    
    public let calendarManager = CalendarManager()
    
    public func processTemplateVariables(_ content: String, for dateString: String) -> String {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: "%date\\(([-+]?\\d*)\\)%", options: [])
        } catch {
            print("Regex pattern error: \(error.localizedDescription)")
            return content
        }
        
        let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
        
        var processedTemplate = content
        for match in matches.reversed() {
            let matchRange = match.range(at: 0)
            let daysRange = match.range(at: 1)
            
            let daysString = (content as NSString).substring(with: daysRange)
            let days = Int(daysString) ?? 0
            
            let formatter = DateFormatter()
            formatter.dateFormat = SettingsManager.shared.selectedDateFormat
            let today = formatter.date(from: dateString) ?? Date()
            let targetDate = Calendar.current.date(byAdding: .day, value: days, to: today)!
            let targetDateString = formatter.string(from: targetDate)
            
            processedTemplate = (processedTemplate as NSString).replacingCharacters(in: matchRange, with: targetDateString)
        }
        
        let selectedCalendars = calendarManager.selectedCalendars()        
        let updatedProcessedTemplate = replaceCalendarSection(in: processedTemplate, with: calendarManager.fetchCalendarEvents(for: dateString, calendars: selectedCalendars))
        
        return updatedProcessedTemplate
    }
    
    func replaceCalendarSection(in content: String, with events: String) -> String {
        let calendarSectionHeader = UserDefaults.standard.string(forKey: "calendarSectionHeader") ?? "## Calendar Events"
        let pattern = "\(calendarSectionHeader)\\n(?:- \\[ \\] .*\\n|- \\[x\\] .*\\n|No events scheduled for this day.\\n)*"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            
            if let match = regex.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count)) {
                let range = Range(match.range, in: content)!
                let before = content[..<range.lowerBound]
                let after = content[range.upperBound...]
                return before + "\(calendarSectionHeader)\n" + events + "\n" + after
            } else {
                return content
            }
        } catch {
            print("Error al crear la expresión regular: \(error.localizedDescription)")
            return content
        }
    }
    
    func replaceSyncSection(in content: String, id : String) -> String {
        let targetString = "%syncnow()%"
        
        if let range = content.range(of: targetString) {
            let before = content[..<range.lowerBound]
            let after = content[range.upperBound...]
            return before + "fodabear://sync-note?id=\(id)" + after
        } else {
            return content
        }
    }
    
    func replaceDailySection(in content: String, with currentDate: String) -> String {
        let dailySectionHeader = SettingsManager.shared.dailySectionHeader
        let pattern = "\(dailySectionHeader)\\n- \\[\\[\\d{4}-\\d{2}-\\d{2}\\]\\]"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            
            if let match = regex.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count)) {
                let range = Range(match.range, in: content)!
                let before = content[..<range.lowerBound]
                let after = content[range.upperBound...]
                return before + "\(dailySectionHeader)\n- [[\(currentDate)]]" + "\(after)"
            } else {
                return content
            }
        } catch {
            print("Error al crear la expresión regular: \(error.localizedDescription)")
            return content
        }
    }
    
    func processTemplate(_ template: String, for dateString: String, with tag: String) -> String {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: "%date\\(([-+]?\\d*)\\)%", options: [])
        } catch {
            print("Regex pattern error: \(error.localizedDescription)")
            return template
        }
        
        let matches = regex.matches(in: template, options: [], range: NSRange(template.startIndex..., in: template))
        
        var processedTemplate = template
        for match in matches.reversed() {
            let matchRange = match.range(at: 0)
            let daysRange = match.range(at: 1)
            
            let daysString = (template as NSString).substring(with: daysRange)
            let days = Int(daysString) ?? 0
            
            let formatter = DateFormatter()
            formatter.dateFormat = SettingsManager.shared.selectedDateFormat
            let today = formatter.date(from: dateString) ?? Date()
            let targetDate = Calendar.current.date(byAdding: .day, value: days, to: today)!
            let targetDateString = formatter.string(from: targetDate)
            
            processedTemplate = (processedTemplate as NSString).replacingCharacters(in: matchRange, with: targetDateString)
        }
        
        if processedTemplate.contains("%tag_placeholder%") {
            processedTemplate = processedTemplate.replacingOccurrences(of: "%tag_placeholder%", with: "#\(tag)#")
        } else {
            processedTemplate += "\n\n#\(tag)#"
        }
        
        return processedTemplate
    }
    
    func createDailyNoteWithTemplate(for dateString: String, with dailyTemplate: String? = "Daily") {
        print("template content: \(dailyTemplate ?? "Daily")")
        let tag = UserDefaults.standard.string(forKey: "dailyNoteTag") ?? ""
        let processedTemplate = processTemplate(dailyTemplate ?? "Daily", for: dateString, with: tag)
        print(processedTemplate)
        print("processed template: \(processedTemplate)")
        
        let urlString = "bear://x-callback-url/create?title=&text=\(processedTemplate)"
        
        if let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
            openURL(url)
        }
    }
    
    private func openURL(_ url: URL) {
#if canImport(AppKit)
        NSWorkspace.shared.open(url)
#elseif canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
#endif
    }
}
