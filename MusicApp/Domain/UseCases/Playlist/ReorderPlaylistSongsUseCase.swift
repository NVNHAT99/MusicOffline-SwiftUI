//
//  ReorderPlaylistSongsUseCase.swift
//  MusicApp
//

import Foundation

protocol ReorderPlaylistSongsUseCaseProtocol {
    func execute(playlistId: UUID, orderedSongIDs: [UUID]) async throws
}

final class ReorderPlaylistSongsUseCase: ReorderPlaylistSongsUseCaseProtocol {

    private let repository: PlaylistRepositoryProtocol

    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
    }

    func execute(playlistId: UUID, orderedSongIDs: [UUID]) async throws {
        try await repository.updateSongOrder(playlistId: playlistId, orderedSongIDs: orderedSongIDs)
        PlaylistEventCenter.shared.subject.send(.updated(playlistId))
    }
}
