//
//  CompletedUploadSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/6/25.
//

import Foundation

protocol CompletedUploadSongUseCaseProtocol {
    func executeTransfer(addPaths: [String], updatePaths: [String: String], deletePaths: [PathFileElement]) async throws
}

final class CompletedUploadSongUseCase: CompletedUploadSongUseCaseProtocol {
    
    private let repository: SongRepositoryProtocol
    private let songMetadataRepository: SongMetadataRepositoryProtocol
    
    init(repository: SongRepositoryProtocol = SongRepository(),
         songMetadataRepository: SongMetadataRepositoryProtocol = SongMetadataRepository()) {
        self.repository = repository
        self.songMetadataRepository = songMetadataRepository
    }
    
    func executeTransfer(addPaths: [String],
                        updatePaths: [String : String],
                        deletePaths: [PathFileElement]) async throws {
        let songs = try await songMetadataRepository.loadSongs(from: addPaths)
        try await repository.performBatchOperation(songsToAdd: songs,
                                                   pathsToUpdate: updatePaths,
                                                   elementsToDelete: deletePaths)
    }
}
