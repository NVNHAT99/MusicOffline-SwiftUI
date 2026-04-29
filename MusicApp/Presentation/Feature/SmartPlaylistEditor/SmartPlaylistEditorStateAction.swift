import Foundation

enum SmartPlaylistEditorStateAction {
    case setName(String)
    case setRules([SmartPlaylistRule])
    case setMatchCount(Int)
    case setIsSaving(Bool)
    case setError(String?)
    case setDismissed(Bool)
    case loadPlaylist(SmartPlaylist)
}
