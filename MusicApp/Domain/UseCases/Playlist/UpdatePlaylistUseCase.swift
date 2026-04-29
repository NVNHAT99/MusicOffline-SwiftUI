//
//  UpdatePlaylistUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/25/25.
//

import Foundation

protocol UpdatePlaylistUseCaseProtocol {
    func execute(from playlistId: UUID, with songIds: [UUID]) async throws
    func removeDeleteSong(from path: String) async throws
}

final class UpdatePlaylistUseCase: UpdatePlaylistUseCaseProtocol {
    
    private let repository: PlaylistRepositoryProtocol
    
    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
    }
    
    
    func execute(from playlistId: UUID, with songIds: [UUID]) async throws {
        try await repository.updatePlaylist(by: playlistId, with: songIds)
        PlaylistEventCenter.shared.subject.send(.updated(playlistId))
    }
    
    func removeDeleteSong(from path: String) async throws {
        guard let songId = UUID(uuidString: path) else { return }
        try await repository.removeDeleteSong(from: songId)
    }
}
