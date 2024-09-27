import Foundation

#if canImport(AppKit)
    import AppKit
#endif

#if canImport(UIKit)
    import UIKit
#endif

public class BearManager {
    public static let shared = BearManager()

    public func updateNoteContent(
        newContent: String, noteID: String, open: Bool, show: Bool
    ) {
        let open = open ? "yes" : "no"
        let show = show ? "yes" : "no"

        if let encodedContent = newContent.addingPercentEncodingForRFC3986() {
            if let url = URL(
                string:
                    "bear://x-callback-url/add-text?id=\(noteID)&open_note=\(open)&show_window=\(show)&exclude_trashed=yes&mode=replace_all&text=\(encodedContent)"
            ) {
                openURL(url)
            }
        } else {
            print("Failed to encode new content for URL.")
        }
    }

    public func updateHomeNoteContent(newContent: String, homeNoteID: String) {
        if let encodedContent = newContent.addingPercentEncodingForRFC3986() {
            if let url = URL(
                string:
                    "bear://x-callback-url/add-text?open_note=no&new_window=no&show_window=no&id=\(homeNoteID)&mode=replace_all&text=\(encodedContent)"
            ) {
                print("Updating home note with URL: \(url)")
                openURL(url)
            }
        } else {
            print("Failed to encode new content for URL.")
        }
    }

    public func createNoteWithContent(_ content: String) {
        if let encodedContent = content.addingPercentEncodingForRFC3986() {
            if let url = URL(
                string: "bear://x-callback-url/create?text=\(encodedContent)")
            {
                print("Creating new note with URL: \(url)")
                openURL(url)
            }
        } else {
            print("Failed to encode content for URL.")
        }
    }

    @MainActor public func openTemplate(_ template: Template) {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        let dateString = formatter.string(from: Date())

        let processedTemplate = NoteManager.shared.templateManager
            .processTemplate(
                template.content, for: dateString, with: template.tag)
        let encodedTemplate =
            processedTemplate.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(
            string:
                "bear://x-callback-url/create?title=&text=\(encodedTemplate)")
        {
            print("Creating note with URL: \(url)")
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
