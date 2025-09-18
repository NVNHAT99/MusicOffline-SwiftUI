//
//  GetAllSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol FetchSongUseCaseProtocol {
    func execute(_ songIdArray: [UUID]) async throws -> [Song]
    func executeGetAll() async throws -> [Song]
}

final class FetchSongUseCase : FetchSongUseCaseProtocol {
    let repository: SongRepositoryProtocol
    
    init(repository: SongRepositoryProtocol = SongRepository()) {
        self.repository = repository
        Logger.debug("FetchSongUseCase initialized")
    }
    
    func execute(_ songIdArray: [UUID]) async throws -> [Song] {
        Logger.debug("Fetching \(songIdArray.count) songs")
        let result = try await repository.fetchSongs(songIdArray)
        Logger.info("Fetched \(result.count) songs")
        return result
    }
    
    func executeGetAll() async throws -> [Song] {
        Logger.debug("Fetching all songs")
        let songs = try await repository.fetchAllSongs()
        Logger.info("Fetched \(songs.count) songs")
        return songs
    }
}
