//
//  FetchPlaylistUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation

protocol FetchPlaylistUseCaseProtocol {
    func executeGetAll() async throws -> [Playlist]
}

final class FetchPlaylistUseCase: FetchPlaylistUseCaseProtocol {
    private let repository: PlaylistRepositoryProtocol
    
    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
    }
    
    func executeGetAll() async throws -> [Playlist] {
        try await repository.fetchAllPlayList()
    }
}
