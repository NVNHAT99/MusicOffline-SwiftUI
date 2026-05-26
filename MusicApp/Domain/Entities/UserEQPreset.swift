import Foundation

/// A user-saved custom EQ curve. Persisted as a JSON array under
/// `UserDefaults` key `user_eq_presets_v2`.
struct UserEQPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var gains: [Float]
    let createdAt: Date

    init(id: UUID = UUID(), name: String, gains: [Float], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.gains = gains
        self.createdAt = createdAt
    }
}
