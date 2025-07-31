//
//  GetAllSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol GetAllSongUseCaseProtocol {
    func excute() async throws -> [Song]
}

final class GetAllSongUseCase : GetAllSongUseCaseProtocol {
    let repository: SongRepositoryProtocol
    
    init(repository: SongRepositoryProtocol = SongRepository()) {
        self.repository = repository
    }
    func excute() async throws -> [Song] {
        let result = try await repository.fetchAllSongs()
        return result
    }
}
