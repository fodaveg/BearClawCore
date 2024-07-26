import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif


public class BearIntegrationManager {
    public static let shared = BearIntegrationManager()
    
    public func isBearInstalled() -> Bool {
        if let url = URL(string: "bear://") {
#if canImport(AppKit)
            return NSWorkspace.shared.urlForApplication(toOpen: url) != nil
#elseif canImport(UIKit)
            return UIApplication.shared.canOpenURL(url)
#else
            return false
#endif
        }
        return false
    }
    
    public func showErrorMessage() {
#if canImport(AppKit)
        let alert = NSAlert()
        alert.messageText = "Bear is not installed"
        alert.informativeText = "This companion application requires Bear to be installed in order to function. Please install Bear and try again."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Close")
        alert.runModal()
#elseif canImport(UIKit)
        let alert = UIAlertController(title: "Bear is not installed", message: "This companion application requires Bear to be installed in order to function. Please install Bear and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(alert, animated: true, completion: nil)
        }
#endif
    }
    
    public func handleCallback(url: URL) {
        print("Handling callback for URL: \(url)")
        
        if let host = url.host {
            switch host {
            case "update-home-note-if-needed-success":
                NoteHandler.shared.updateHomeNoteIfNeededSuccess(url: url)
            case "update-home-note-if-needed-error":
                NoteHandler.shared.updateHomeNoteIfNeededError(url: url)
            case "update-daily-note-if-needed-success":
                NoteHandler.shared.updateDailyNoteIfNeededSuccess(url: url)
            case "update-daily-note-if-needed-success-for-sync":
                NoteHandler.shared.updateDailyNoteIfNeededSuccessForSync(url: url)
            case "update-daily-note-if-needed-error":
                NoteHandler.shared.updateDailyNoteIfNeededError(url: url)
            case "open-daily-note-success":
                NoteHandler.shared.openDailyNoteSuccess(url: url)
            case "open-daily-note-error":
                NoteHandler.shared.openDailyNoteError(url: url)
            case "sync-note":
                NoteHandler.shared.syncNoteById(url: url)
            case "replace-sync-placeholder":
                NoteHandler.shared.openNoteForNoteAndOpen(url: url)
            case "replace-sync-placeholder-action":
                NoteHandler.shared.updateNoteAndOpen(url: url)
            case "open-daily-note-for-date":
                NoteHandler.shared.openDailyNoteForDate(url: url)
            case "create-daily-note-for-date":
                NoteHandler.shared.createDailyNoteWithDate(url: url)
            default:
                print("Unhandled URL host: \(host)")
                break
            }
        } else {
            print("URL host is nil")
        }
    }
    
    public func performBackgroundSync(completion: @escaping (Bool) -> Void) {
        // Realiza tareas de sincronización aquí
        completion(true)
    }
}
