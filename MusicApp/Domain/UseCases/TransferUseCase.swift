//
//  BatchOperationUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/6/25.
//

import Foundation

protocol TransferUseCaseProtocol {
    func executeAdd(by path: String) async throws
    func executeUpdate(from oldPath: String, to newPath: String) async throws
    func executeDelete(from path: String) async throws
    func isAllTaskDone() -> Bool
    func reset()
}

final class TransferUseCase: TransferUseCaseProtocol {
    
    // Dependencies
    private let addSongUseCase: AddSongUseCaseProtocol
    private let updateSongUseCase: UpdateSongUseCaseProtocol
    private let deleteSongUseCase: DeleteSongUseCaseProtocol
    private let coreDataService: CoreDataProtocol
    // TODO: - Remove all use case must using service
    private let repository: PlaylistRepositoryProtocol
    
    init(addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase(),
         updateSongUseCase: UpdateSongUseCaseProtocol = UpdateSongUseCase(),
         deleteSongUseCase: DeleteSongUseCaseProtocol = DeleteSongUseCase(),
         coreDataService: CoreDataProtocol = CoreDataManager.shared,
         repository: PlaylistRepositoryProtocol = PlaylistRepository()) {
        self.addSongUseCase = addSongUseCase
        self.updateSongUseCase = updateSongUseCase
        self.deleteSongUseCase = deleteSongUseCase
        self.coreDataService = coreDataService
        self.repository = repository
    }
    
    func executeAdd(by path: String) async throws {
        try await addSongUseCase.execute(from: path)
    }
    
    func executeUpdate(from oldPath: String, to newPath: String) async throws {
        try await updateSongUseCase.execute(from: oldPath, to: newPath)
    }
    
    func executeDelete(from path: String) async throws {
        let songId = try await deleteSongUseCase.execute(width: path)
        try await repository.removeDeleteSong(from: songId)
    }
    
    func isAllTaskDone() -> Bool {
        return coreDataService.isTransferQueueIdle
    }
    
    func reset() {
        // TODO: - need check later like reset context or not
        let songIDs = ["0BAA947F-BC6C-4FCF-9A29-FF4F54817DC7", "invalid", "D2D41DBA-355D-4EED-BB2B-3B82A16B9B18"]

        _ = songIDs.compactMap(UUID.init)
    }
    
}

