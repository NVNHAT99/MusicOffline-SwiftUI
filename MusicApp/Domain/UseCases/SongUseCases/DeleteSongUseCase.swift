//
//  DeleteSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol DeleteSongUseCaseProtocol {
    func excute(_ pathFileElemets: [PathFileElement]) async throws
    func excuteDeleteAll() async throws
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
    
    func excute(_ pathFileElemets: [PathFileElement]) async throws {
        try await repository.deleteSongs(with: pathFileElemets)
        try await documentFileService.removeFiles(pathFileElemets)
        
    }
    
    func excuteDeleteAll() async throws {
        try await repository.deleteAllSongs()
        try await documentFileService.removeAllFiles()
    }
}
