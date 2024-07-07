import Foundation
import SwiftUI
import ServiceManagement

public class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()
    
    @AppStorage("homeNoteID") public var homeNoteID: String = ""
    @AppStorage("defaultAction") public var defaultAction: String = "home"
    @AppStorage("templates") public var templatesData: Data = Data()
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("calendarSectionHeader") public var calendarSectionHeader: String = "## Calendar Events"
    @AppStorage("dailySectionHeader") public var dailySectionHeader: String = "## Daily"
    @AppStorage("dailyNoteTag") public var dailyNoteTag: String = ""
    @AppStorage("dailyNoteTemplate") public var dailyNoteTemplate: String = ""
    @AppStorage("selectedDateFormat") public var selectedDateFormat: String = "yyyy-MM-dd"
    @AppStorage("customDateFormat") public var customDateFormat: String = ""
    
    public init() {}
    
    public func loadTemplates() -> [Template] {
        if let loadedTemplates = try? JSONDecoder().decode([Template].self, from: templatesData) {
            return loadedTemplates
        }
        return []
    }
    
    public func saveTemplates(_ templates: [Template]) {
        if let encodedTemplates = try? JSONEncoder().encode(templates) {
            templatesData = encodedTemplates
        }
    }
    
    public func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .notRegistered {
                    try SMAppService.mainApp.register()
                    print("Successfully set launch at login")
                } else {
                    print("Launch at login is already enabled")
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    print("Successfully unset launch at login")
                } else {
                    print("Launch at login is already disabled")
                }
            }
        } catch {
            print("Failed to update launch at login status: \(error.localizedDescription)")
        }
    }
}
