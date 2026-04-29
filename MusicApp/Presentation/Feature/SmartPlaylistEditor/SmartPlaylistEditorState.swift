import Foundation

struct SmartPlaylistEditorState {
    var id: UUID = UUID()
    var name: String = ""
    var rules: [SmartPlaylistRule] = []
    var matchCount: Int = 0
    var isSaving: Bool = false
    var errorMessage: String? = nil
    var isDismissed: Bool = false
}
