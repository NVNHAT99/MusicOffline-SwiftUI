//
//  BatchOperationUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/6/25.
//

import Foundation

protocol BatchOperationUseCaseProtocol {
    func trackFileUploaded(_ path: String)
    func trackFileDeleted(_ path: String)
    func trackFileUpdated(from oldPath: String, to newPath: String)
    func commitAllOperations() async throws
    func getPendingOperations() -> BatchOperations
    func hasPendingChanges() -> Bool
    func reset()
}

final class BatchOperationUseCase: BatchOperationUseCaseProtocol {
    
    private var operations = BatchOperations()
    
    // Dependencies
    private let addSongUseCase: AddSongUseCaseProtocol
    private let updateSongUseCase: UpdateSongUseCaseProtocol
    private let deleteSongUseCase: DeleteSongUseCaseProtocol
    private let completedUploadUseCase: CompletedUploadSongUseCaseProtocol
    
    init(addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase(),
         updateSongUseCase: UpdateSongUseCaseProtocol = UpdateSongUseCase(),
         deleteSongUseCase: DeleteSongUseCaseProtocol = DeleteSongUseCase(),
         completedUploadUseCase: CompletedUploadSongUseCaseProtocol = CompletedUploadSongUseCase()) {
        self.addSongUseCase = addSongUseCase
        self.updateSongUseCase = updateSongUseCase
        self.deleteSongUseCase = deleteSongUseCase
        self.completedUploadUseCase = completedUploadUseCase
    }
    
    // MARK: - Public Methods
    
    func trackFileUploaded(_ path: String) {
        operations.addPaths.append(path)
    }
    
    func trackFileDeleted(_ path: String) {
        if operations.addPaths.contains(path) {
            handleDeleteNewlyAddedFile(path)
        } else if let originalKey = findOriginalKeyForUpdatedPath(path) {
            handleDeleteUpdatedFile(originalKey)
        } else {
            handleDeleteExistingFile(path)
        }
    }
    
    func trackFileUpdated(from oldPath: String, to newPath: String) {
        if let index = operations.addPaths.firstIndex(of: oldPath) {
            handleUpdateNewlyAddedFile(at: index, to: newPath)
        } else if let originalKey = findOriginalKeyForUpdatedPath(oldPath) {
            handleUpdateAlreadyMovedFile(originalKey: originalKey, newPath: newPath)
        } else {
            handleUpdateExistingFile(from: oldPath, to: newPath)
        }
    }
    
    func commitAllOperations() async throws {
        // Option 1: Use existing separate use cases
        try await executeWithSeparateUseCases()
        
        // Option 2: Use batch operation (recommended for better performance)
        // try await executeWithBatchOperation()
        
        reset()
    }
    
    func getPendingOperations() -> BatchOperations {
        return operations
    }
    
    func hasPendingChanges() -> Bool {
        return operations.hasPendingChanges
    }
    
    func reset() {
        operations = BatchOperations()
    }
    
    // MARK: - Private Methods - Delete Logic
    
    /// Removes a newly added file (not yet saved to Core Data) from the add list,
    /// and adds it to the deleted list for local cleanup only.
    private func handleDeleteNewlyAddedFile(_ path: String) {
        operations.addPaths.removeAll { $0 == path }
        operations.deletePaths.append(.init(pathLocalFile: path, pathCoreData: nil))
    }
    
    /// Removes a previously updated file from the update tracking list,
    /// and marks it for deletion in both local storage and Core Data.
    private func handleDeleteUpdatedFile(_ originalKey: String) {
        operations.updatePaths.removeValue(forKey: originalKey)
        operations.deletePaths.append(.init(pathLocalFile: originalKey, pathCoreData: originalKey))
    }
    
    /// Marks an existing file as deleted (assumes it exists in Core Data).
    private func handleDeleteExistingFile(_ path: String) {
        operations.deletePaths.append(.init(pathLocalFile: path, pathCoreData: path))
    }
    
    // MARK: - Private Methods - Update Logic
    
    /// Updates the path of a newly added file (not yet saved to Core Data).
    private func handleUpdateNewlyAddedFile(at index: Int, to newPath: String) {
        operations.addPaths[index] = newPath
    }
    
    /// Handles updating a file that was already moved before.
    private func handleUpdateAlreadyMovedFile(originalKey: String, newPath: String) {
        if newPath == originalKey {
            // File moved back to its original path → cancel the update
            operations.updatePaths.removeValue(forKey: originalKey)
        } else {
            // File moved again → update the destination path
            operations.updatePaths[originalKey] = newPath
        }
    }
    
    /// Tracks the first time a file is being moved.
    private func handleUpdateExistingFile(from oldPath: String, to newPath: String) {
        operations.updatePaths[oldPath] = newPath
    }
    
    // MARK: - Helper Methods
    
    /// Finds the original key for a path that appears as a value in updatePaths.
    private func findOriginalKeyForUpdatedPath(_ path: String) -> String? {
        return operations.updatePaths.first { $0.value == path }?.key
    }
    
    // MARK: - Execution Methods
    
    /// Execute operations using separate use cases (current approach).
    private func executeWithSeparateUseCases() async throws {
        if !operations.addPaths.isEmpty {
            try await addSongUseCase.excuteList(from: operations.addPaths)
        }
        
        if !operations.updatePaths.isEmpty {
            try await updateSongUseCase.excuteWithList(with: operations.updatePaths)
        }
        
        if !operations.deletePaths.isEmpty {
            try await deleteSongUseCase.excute(operations.deletePaths)
        }
    }
    
    /// Execute operations using batch operation (better performance).
    private func executeWithBatchOperation() async throws {
        try await completedUploadUseCase.excuteTransfer(
            addPaths: operations.addPaths,
            updatePaths: operations.updatePaths,
            deletePaths: operations.deletePaths
        )
    }
}

