//
//  GetAllSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol GetSongUseCaseProtocol {
    func excute(_ songIdArray: [UUID]) async throws -> [Song]
    func excuteGetAll() async throws -> [Song]
}

final class GetSongUseCase : GetSongUseCaseProtocol {
    let repository: SongRepositoryProtocol
    
    init(repository: SongRepositoryProtocol = SongRepository()) {
        self.repository = repository
    }
    
    func excute(_ songIdArray: [UUID]) async throws -> [Song] {
        let result = try await repository.fetchSongs(songIdArray)
        return result
    }
    
    func excuteGetAll() async throws -> [Song] {
        return try await repository.fetchAllSongs()
    }
}
