//
//  CompletedUploadSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/6/25.
//

import Foundation

protocol CompletedUploadSongUseCaseProtocol {
    func excuteTransfer(addPaths: [String], updatePaths: [String: String], deletePaths: [PathFileElement]) async throws
}

final class CompletedUploadSongUseCase: CompletedUploadSongUseCaseProtocol {
    private let repositoty: SongRepositoryProtocol
    init(repositoty: SongRepositoryProtocol = SongRepository()) {
        self.repositoty = repositoty
    }
    
    func excuteTransfer(addPaths: [String],
                        updatePaths: [String : String],
                        deletePaths: [PathFileElement]) async throws {
        let songs = try await SongMapper.loadSongs(from: addPaths)
        try await repositoty.performBatchOperation(songsToAdd: songs,
                                                   pathsToUpdate: updatePaths,
                                                   elementsToDelete: deletePaths)
    }
}
