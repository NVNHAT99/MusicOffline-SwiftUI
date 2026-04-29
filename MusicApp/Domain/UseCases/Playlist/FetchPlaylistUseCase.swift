//
//  FetchPlaylistUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation

protocol FetchPlaylistUseCaseProtocol {
    func executeGetAll(sortBy: PlaylistSortOption) async throws -> [Playlist]
    func execute(with playlistId: String) async throws -> Playlist
    func excute(with playlistIdArray: [String]) async throws -> [Playlist]
}

final class FetchPlaylistUseCase: FetchPlaylistUseCaseProtocol {
    private let repository: PlaylistRepositoryProtocol
    
    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
        Logger.debug("FetchPlaylistUseCase initialized")
    }
    
    func executeGetAll(sortBy: PlaylistSortOption = .nameAscending) async throws -> [Playlist] {
        Logger.debug("Fetching all playlists")
        let playlists = try await repository.fetchAllPlayList(sortBy: sortBy)
        Logger.info("Fetched \(playlists.count) playlists")
        return playlists
    }
    
    func execute(with playlistId: String) async throws -> Playlist {
        Logger.debug("Fetching playlist with ID: \(playlistId)")
        guard let playlistUUID = UUID(uuidString: playlistId) else {
            Logger.error("Invalid playlist ID format: \(playlistId)")
            throw CoreDataError.entityNotFound
        }

        guard let playlist = try await repository.fetchPlaylist(with: playlistUUID) else {
            Logger.error("Playlist not found with ID: \(playlistId)")
            throw CoreDataError.entityNotFound
        }

        Logger.info("Successfully fetched playlist: \(playlist.name)")
        return playlist
    }
    
    func excute(with playlistIdArray: [String]) async throws -> [Playlist] {
        Logger.debug("Fetching \(playlistIdArray.count) playlists")
        let playlistUUIDs = playlistIdArray.compactMap({ UUID(uuidString: $0 )})
        let playlists = try await repository.fetchPlaylist(with: playlistUUIDs)
        Logger.info("Fetched \(playlists.count) playlists from \(playlistIdArray.count) requested")
        return playlists
    }
}
