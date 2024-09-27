import Foundation

public struct Template: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var content: String
    public var tag: String
    public var isDaily: Bool
    public var isHome: Bool
    
    public init(id: UUID = UUID(), name: String, content: String, tag: String, isDaily: Bool = false, isHome: Bool = false) {
        self.id = id
        self.name = name
        self.content = content
        self.tag = tag
        self.isDaily = isDaily
        self.isHome = isHome
    }
}
