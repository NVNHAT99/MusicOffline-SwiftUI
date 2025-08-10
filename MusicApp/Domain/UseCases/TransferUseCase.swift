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
    
    init(addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase(),
         updateSongUseCase: UpdateSongUseCaseProtocol = UpdateSongUseCase(),
         deleteSongUseCase: DeleteSongUseCaseProtocol = DeleteSongUseCase(),
         coreDataService: CoreDataProtocol = CoreDataManager.shared) {
        self.addSongUseCase = addSongUseCase
        self.updateSongUseCase = updateSongUseCase
        self.deleteSongUseCase = deleteSongUseCase
        self.coreDataService = coreDataService
    }
    
    func executeAdd(by path: String) async throws {
        try await addSongUseCase.execute(from: path)
    }
    
    func executeUpdate(from oldPath: String, to newPath: String) async throws {
        try await updateSongUseCase.execute(from: oldPath, to: newPath)
    }
    
    func executeDelete(from path: String) async throws {
        try await deleteSongUseCase.execute(width: path)
    }
    
    func isAllTaskDone() -> Bool {
        return coreDataService.isTransferQueueIdle
    }
    
    func reset() {
        // TODO: - need check later like reset context or not
        let songIDs = ["0BAA947F-BC6C-4FCF-9A29-FF4F54817DC7", "invalid", "D2D41DBA-355D-4EED-BB2B-3B82A16B9B18"]

        let uuids = songIDs.compactMap(UUID.init)
    }
    
}

