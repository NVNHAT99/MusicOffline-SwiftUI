import Foundation

final class SmartPlaylistEditorStateReducer {

    func reduce(_ state: SmartPlaylistEditorState, with action: SmartPlaylistEditorStateAction) -> SmartPlaylistEditorState {
        var s = state
        switch action {
        case .setName(let name):
            s.name = name
        case .setRules(let rules):
            s.rules = rules
        case .setMatchCount(let count):
            s.matchCount = count
        case .setIsSaving(let saving):
            s.isSaving = saving
        case .setError(let msg):
            s.errorMessage = msg
        case .setDismissed(let v):
            s.isDismissed = v
        case .loadPlaylist(let pl):
            s.id = pl.id
            s.name = pl.name
            s.rules = pl.rules
        }
        return s
    }
}
