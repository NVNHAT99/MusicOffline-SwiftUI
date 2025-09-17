//
//  DeletetPlaylistUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/2/25.
//

import Foundation

protocol DeletetPlaylistUseCaseProtocol {
    func execute(by playlistID: UUID) async throws
}

final class DeletetPlaylistUseCase: DeletetPlaylistUseCaseProtocol {
    
    private let repository: PlaylistRepositoryProtocol
    
    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
    }
    
    func execute(by playlistID: UUID) async throws {
        try await repository.deletePlaylist(with: playlistID)
        PlaylistEventCenter.shared.subject.send(.deleted(playlistID))
    }
}
