//
//  DeleteSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol DeleteSongUseCaseProtocol {
    func executeList(_ pathFileElemets: [PathFileElement]) async throws
    func executeDeleteAll() async throws
    func execute(width path: String) async throws -> UUID
}

final class DeleteSongUseCase: DeleteSongUseCaseProtocol {
    let repository: SongRepositoryProtocol
    let documentFileService: DocumentFileServiceProtocol
    // TODO: need delete file also
    init(repository: SongRepositoryProtocol = SongRepository(),
         documentFileService: DocumentFileServiceProtocol = DocumentFileService()) {
        self.repository = repository
        self.documentFileService = documentFileService
    }
    
    func executeList(_ pathFileElemets: [PathFileElement]) async throws {
        try await repository.deleteSongs(with: pathFileElemets)
        
    }
    
    func executeDeleteAll() async throws {
        try await repository.deleteAllSongs()
    }
    
    func execute(width path: String) async throws -> UUID {
        try await repository.deleteSong(withURL: path)
    }
}
