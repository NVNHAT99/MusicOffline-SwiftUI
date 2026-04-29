import Foundation

enum RuleField: String, Codable, CaseIterable {
    case artist, album, duration, dateAdded
}

enum RuleOperator: String, Codable, CaseIterable {
    case equals, contains, greaterThan, lessThan
}

struct SmartPlaylistRule: Codable, Equatable {
    let field: RuleField
    let `operator`: RuleOperator
    let value: String
}

struct SmartPlaylist: Identifiable, Equatable {
    let id: UUID
    var name: String
    var rules: [SmartPlaylistRule]
    var createdAt: Date
}
