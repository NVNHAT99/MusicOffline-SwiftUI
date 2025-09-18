//
//  FetchPlaylistUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation

protocol FetchPlaylistUseCaseProtocol {
    func executeGetAll() async throws -> [Playlist]
    func execute(with playlistId: String) async throws -> Playlist
    func excute(with playlistIdArray: [String]) async throws -> [Playlist]
}

final class FetchPlaylistUseCase: FetchPlaylistUseCaseProtocol {
    private let repository: PlaylistRepositoryProtocol
    
    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
    }
    
    func executeGetAll() async throws -> [Playlist] {
        try await repository.fetchAllPlayList()
    }
    
    func execute(with playlistId: String) async throws -> Playlist {
        if let playlistUUID = UUID(uuidString: playlistId),
           let playlist = try await repository.fetchPlaylist(with: playlistUUID) {
            return playlist
        }
        
        throw CoreDataError.entityNotFound
    }
    
    func excute(with playlistIdArray: [String]) async throws -> [Playlist] {
        let playlistUUIDs = playlistIdArray.compactMap({ UUID(uuidString: $0 )})
        return try await repository.fetchPlaylist(with: playlistUUIDs)
    }
}
