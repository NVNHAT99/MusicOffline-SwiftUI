//
//  CoreData.swift
//  MusicApp
//
//  Created by Nhat on 6/8/23.
//

import Foundation
import CoreData

enum CoreDataError: Error, LocalizedError {
    case initializationFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidTitle
    case entityNotFound
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let error):
            return "Failed to initialize Core Data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save context: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .invalidTitle:
            return "Song title cannot be empty"
        case .entityNotFound:
            return "Entity not found"
        }
    }
}

// MARK: - CoreData
protocol CoreDataProtocol {
    var viewContext: NSManagedObjectContext { get }
    func newBackgroundContext() -> NSManagedObjectContext
    func performWithSerialQueue<T>(
        _ operation: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T
}

final class CoreDataManager: CoreDataProtocol, @unchecked Sendable {
    
    static let shared = CoreDataManager()
    private let container: NSPersistentContainer
    private let operationQueue = DispatchQueue(label: "com.musicapp.songrepository", qos: .userInitiated)
    
    private init() {
        container = NSPersistentContainer(name: "Library")
        
        // Configure container
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        
        var initError: Error?
        let group = DispatchGroup()
        group.enter()
        
        container.loadPersistentStores { _, error in
            initError = error
            group.leave()
        }
        
        group.wait()
        
        if let error = initError {
            fatalError("Failed to load Core Data store: \(error)")
        }
        
        // Configure contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - performWithSerialQueue Implementation
    func performWithSerialQueue<T>(
        _ operation: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: CoreDataError.entityNotFound) // hoặc error khác phù hợp
                return
            }
            operationQueue.async {
                let context = self.newBackgroundContext()
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                context.perform {
                    do {
                        let result = try operation(context)
                        
                        context.reset()
                        continuation.resume(returning: result)
                    } catch {
                        context.reset()
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
