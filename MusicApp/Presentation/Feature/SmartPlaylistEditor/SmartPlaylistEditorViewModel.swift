import Foundation
import Combine

@MainActor
final class SmartPlaylistEditorViewModel: ObservableObject {

    @Published var state: SmartPlaylistEditorState

    private let reducer = SmartPlaylistEditorStateReducer()
    private let saveUseCase: SaveSmartPlaylistUseCaseProtocol
    private let matchUseCase: SmartPlaylistUseCase

    init(
        playlist: SmartPlaylist? = nil,
        saveUseCase: SaveSmartPlaylistUseCaseProtocol,
        matchUseCase: SmartPlaylistUseCase = SmartPlaylistUseCase()
    ) {
        self.saveUseCase = saveUseCase
        self.matchUseCase = matchUseCase
        var initial = SmartPlaylistEditorState()
        if let pl = playlist {
            initial = SmartPlaylistEditorStateReducer().reduce(initial, with: .loadPlaylist(pl))
        }
        self.state = initial
    }

    func send(_ intent: SmartPlaylistEditorIntent) {
        switch intent {
        case .setName(let name):
            state = reducer.reduce(state, with: .setName(name))

        case .addRule:
            var rules = state.rules
            rules.append(SmartPlaylistRule(field: .artist, operator: .contains, value: ""))
            state = reducer.reduce(state, with: .setRules(rules))
            refreshCount()

        case .removeRule(let idx):
            var rules = state.rules
            guard rules.indices.contains(idx) else { return }
            rules.remove(at: idx)
            state = reducer.reduce(state, with: .setRules(rules))
            refreshCount()

        case .updateRule(let idx, let rule):
            var rules = state.rules
            guard rules.indices.contains(idx) else { return }
            rules[idx] = rule
            state = reducer.reduce(state, with: .setRules(rules))
            refreshCount()

        case .save:
            guard !state.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                state = reducer.reduce(state, with: .setError("Name is required"))
                return
            }
            state = reducer.reduce(state, with: .setIsSaving(true))
            let playlist = SmartPlaylist(id: state.id, name: state.name, rules: state.rules, createdAt: Date())
            do {
                try saveUseCase.execute(playlist)
                PlaylistEventCenter.shared.smartSubject.send(.added(playlist.id))
                state = reducer.reduce(state, with: .setDismissed(true))
            } catch {
                state = reducer.reduce(state, with: .setError(error.localizedDescription))
            }
            state = reducer.reduce(state, with: .setIsSaving(false))

        case .delete:
            try? saveUseCase.delete(id: state.id)
            PlaylistEventCenter.shared.smartSubject.send(.deleted(state.id))
            state = reducer.reduce(state, with: .setDismissed(true))

        case .dismiss:
            state = reducer.reduce(state, with: .setDismissed(true))
        }
    }

    private func refreshCount() {
        let count = matchUseCase.count(rules: state.rules)
        state = reducer.reduce(state, with: .setMatchCount(count))
    }
}
