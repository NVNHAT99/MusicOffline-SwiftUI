//
//  AddPlaylistUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/10/25.
//

import Foundation

enum AddPlaylistError: Error {
    case playListNameExtisted
    case nameEmpty
    case nameTooLong
}

protocol AddPlaylistUseCaseProtocol {
    func execute(with name: String) async throws
}

final class AddPlaylistUseCase: AddPlaylistUseCaseProtocol {

    private let repository: PlaylistRepositoryProtocol

    init(repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.repository = repository
    }

    func execute(with name: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AddPlaylistError.nameEmpty }
        guard trimmed.count <= 50 else { throw AddPlaylistError.nameTooLong }

        if let _ = try await repository.fetchPlaylist(with: trimmed) {
            throw AddPlaylistError.playListNameExtisted
        }

        try await repository.addPlaylist(with: .init(id: UUID(), name: trimmed, songIDs: []))
    }
}
