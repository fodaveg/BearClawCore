import Foundation
import SwiftUI

#if canImport(ServiceManagement)
    import ServiceManagement
#endif
#if canImport(AppKit)
    import AppKit
#endif
#if canImport(UserNotifications)
    import UserNotifications
#endif

public class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()

    @AppStorage("homeNoteID") public var homeNoteID: String = ""
    @AppStorage("defaultAction") public var defaultAction: String = "home"
    @AppStorage("templates") public var templatesData: Data = Data()
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("calendarSectionHeader") public var calendarSectionHeader:
        String = "## Calendar Events"
    @AppStorage("dailySectionHeader") public var dailySectionHeader: String =
        "## Daily"
    @AppStorage("dailyNoteTag") public var dailyNoteTag: String = ""
    @AppStorage("dailyNoteTemplate") public var dailyNoteTemplate: String = ""
    @AppStorage("selectedDateFormat") public var selectedDateFormat: String =
        "yyyy-MM-dd"
    @AppStorage("customDateFormat") public var customDateFormat: String = ""
    @AppStorage("selectedCalendarIDs") public var selectedCalendarIDs: String =
        ""

    public var selectedCalendarIDsArray: [String] {
        get {
            return selectedCalendarIDs.split(separator: ",").map(String.init)
        }
        set {
            let newString = newValue.joined(separator: ",")
            if selectedCalendarIDs != newString {
                selectedCalendarIDs = newString
                NotificationCenter.default.post(
                    name: .calendarSelectionChanged, object: nil)
            }
        }
    }

    public init() {}

    public func loadTemplates() -> [Template] {
        if let loadedTemplates = try? JSONDecoder().decode(
            [Template].self, from: templatesData)
        {
            return loadedTemplates
        }
        return []
    }

    public func saveTemplates(_ templates: [Template]) {
        if let encodedTemplates = try? JSONEncoder().encode(templates) {
            templatesData = encodedTemplates
        }
    }

    #if canImport(AppKit) && canImport(ServiceManagement)
        public func setLaunchAtLogin(enabled: Bool) {
            let helperAppIdentifier = "net.fodaveg.BearHelperLauncher"  // Cambia esto por el bundle identifier de tu helper app

            print("Helper App Identifier: \(helperAppIdentifier)")

            // Imprimir la ruta del bundle de la aplicación principal
            let bundlePath = Bundle.main.bundlePath
            print("Bundle Path: \(bundlePath)")

            // Crear el servicio de la app con el identificador del helper app
            let helperAppService = SMAppService.loginItem(
                identifier: helperAppIdentifier)

            // Imprimir el estado del servicio de la app
            let status = helperAppService.status
            print("Helper App Service Status: \(status.rawValue)")

            switch status {
            case .enabled:
                print("Status: enabled")
            case .notRegistered:
                print("Status: not registered")
            case .requiresApproval:
                print("Status: requires approval")
            case .notFound:
                print("Status: not found")
            @unknown default:
                print("Status: unknown")
            }

            // Solicitar permiso para notificaciones
            requestNotificationPermission()

            do {
                if enabled {
                    if status == .notRegistered || status == .notFound {
                        try helperAppService.register()
                        print(
                            "Successfully set launch at login for \(helperAppIdentifier)"
                        )
                        sendNotification(
                            title: "Login Item Enabled",
                            body: "The application will now launch at login.")
                    } else if status == .enabled {
                        print("Launch at login is already enabled")
                    } else {
                        print("Unknown status: \(status.rawValue)")
                    }
                } else {
                    if status == .enabled {
                        try helperAppService.unregister()
                        print(
                            "Successfully unset launch at login for \(helperAppIdentifier)"
                        )
                        sendNotification(
                            title: "Login Item Disabled",
                            body:
                                "The application will no longer launch at login."
                        )
                    } else {
                        print(
                            "Launch at login is already disabled or not registered"
                        )
                    }
                }
            } catch {
                print(
                    "Failed to update launch at login status for \(helperAppIdentifier): \(error.localizedDescription)"
                )
            }
        }

        func requestNotificationPermission() {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) {
                granted, error in
                if let error = error {
                    print(
                        "Notification permission request error: \(error.localizedDescription)"
                    )
                }
            }
        }

        func sendNotification(title: String, body: String) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: UUID().uuidString, content: content,
                trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print(
                        "Failed to send notification: \(error.localizedDescription)"
                    )
                }
            }
        }
    #endif
}
