import Foundation

enum SmartPlaylistEditorIntent {
    case setName(String)
    case addRule
    case removeRule(Int)
    case updateRule(Int, SmartPlaylistRule)
    case save
    case delete
    case dismiss
}
