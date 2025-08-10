//
//  AddPlaylistUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/10/25.
//

import Foundation

protocol AddPlaylistUseCaseProtocol {
    func execute(with name: String) async throws
}

final class AddPlaylistUseCase: AddPlaylistUseCaseProtocol {
    
    private let repository: PlaylistRepositoryProtocol
    
    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
    }
    
    func execute(with name: String) async throws {
        try await repository.addPlaylist(with: .init(id: UUID(),
                                                     name: name,
                                                     songIDs: []))
    }
}
