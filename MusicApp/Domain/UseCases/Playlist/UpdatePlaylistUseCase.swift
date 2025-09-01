//
//  UpdatePlaylistUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/25/25.
//

import Foundation

enum UpdatePlaylistError: Error {
    case invalidUUID
}
protocol UpdatePlaylistUseCaseProtocol {
    func execute(from playlistId: String, with songIds: [String]) async throws
}

final class UpdatePlaylistUseCase: UpdatePlaylistUseCaseProtocol {
    
    private let repository: PlaylistRepositoryProtocol
    
    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
    }
    
    
    func execute(from playlistId: String, with songIds: [String]) async throws {
        if let uuidPlaylist = UUID(uuidString: playlistId) {
            try await repository.updatePlaylist(by: uuidPlaylist, with: songIds)
            PlaylistEventCenter.shared.subject.send(.updated(uuidPlaylist))
        } else {
            throw UpdatePlaylistError.invalidUUID
        }
    }
}
