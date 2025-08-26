//
//  GetAllSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol FetchSongUseCaseProtocol {
    func execute(_ songIdArray: [String]) async throws -> [Song]
    func executeGetAll() async throws -> [Song]
}

final class FetchSongUseCase : FetchSongUseCaseProtocol {
    let repository: SongRepositoryProtocol
    
    init(repository: SongRepositoryProtocol = SongRepository()) {
        self.repository = repository
    }
    
    func execute(_ songIdArray: [String]) async throws -> [Song] {
        let uuidArray: [UUID] = songIdArray.compactMap { UUID(uuidString: $0) }
        let result = try await repository.fetchSongs(uuidArray)
        return result
    }
    
    func executeGetAll() async throws -> [Song] {
        return try await repository.fetchAllSongs()
    }
}
