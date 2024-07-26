import SwiftUI

public class CalendarManagerContainer: ObservableObject {
    @Published public var calendarManager: CalendarManager
    
    public init() {
        self.calendarManager = CalendarManager.shared
    }
}
