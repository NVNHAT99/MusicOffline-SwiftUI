//
//  SongPrepository.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation
import CoreData

final class SongRepository: SongRepositoryProtocol, @unchecked Sendable {
    
    private let coreData: CoreDataProtocol
    
    init(coreData: CoreDataProtocol = CoreDataManager.shared) {
        self.coreData = coreData
    }
    
    func addSong(_ song: Song) async throws {
        guard !song.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreDataError.invalidTitle
        }
        
        try await coreData.performTransferInTransferContext { context in
            let songEntity = SongEntityMapper.makeEntity(song, context: context)
            do {
                try context.save()
                print("✓ Saved song: \(songEntity.title ?? "") with ID: \(songEntity.id?.uuidString ?? "")")
            } catch {
                context.rollback()
                throw CoreDataError.saveFailed(error)
            }
        }
    }
    
    func addSongs(_ songs: [Song]) async throws {
        return try await coreData.performTransferInTransferContext { context in
            for song in songs {
                let _ = SongEntityMapper.makeEntity(song, context: context)
            }
            do {
                try context.save()
                print("✓ Saved list song success")
            } catch {
                context.rollback()
                throw CoreDataError.saveFailed(error)
            }
        }
    }
    
    func fetchSongs(_ songIdArray: [UUID]) async throws -> [Song] {
        return try await coreData.performTransferInTransferContext { context in
            let request: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", songIdArray)
            
            let result = try context.fetch(request)
            
            return result.compactMap { entity in
                SongEntityMapper.mapToSong(entity)
            }
        }
    }
    
    func fetchAllSongs() async throws -> [Song] {
        return try await coreData.performTransferInTransferContext { context in
            let fetchRequest: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)] // Sắp xếp theo title tăng dần
            
            do {
                let listSongEntity = try context.fetch(fetchRequest)
                let results = listSongEntity.map { SongEntityMapper.mapToSong( $0 ) }
                return results
            } catch {
                throw CoreDataError.fetchFailed(error)
            }
        }
    }
    
    func updateSong(from oldPath: String, to newPath: String) async throws {
        try await coreData.performTransferInTransferContext { context in
            let request: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
            request.predicate = NSPredicate(format: "url == %@", oldPath)
            request.fetchLimit = 1
            
            guard let song = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }
            
            song.url = newPath
            
            try context.save()
        }
    }
    
    func updateSongs(from dictionaryFileURLs: [String : String]) async throws {
        try await coreData.performTransferInTransferContext { context in
            do {
                for (oldPath, newPath) in dictionaryFileURLs {
                    
                    let request: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "url == %@", oldPath)
                    request.fetchLimit = 1
                    
                    guard let song = try context.fetch(request).first else {
                        throw CoreDataError.entityNotFound
                    }
                    
                    song.url = newPath
                    try context.save()
                }
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
                throw error
            }
        }
    }
    

    
    func deleteSong(withURL url: String) async throws -> UUID {
        try await coreData.performTransferInTransferContext { context in
            let fetchRequest: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "url == %@", url)
            fetchRequest.fetchLimit = 1
            
            do {
                if let songToDelete = try context.fetch(fetchRequest).first {
                    context.delete(songToDelete)
                    try context.save()
                    return songToDelete.id ?? UUID()
                    print("✓ Deleted song with url: \(url)")
                } else {
                    throw CoreDataError.entityNotFound
                }
            } catch {
                context.rollback()
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
    
    func deleteSongs(with elements: [PathFileElement]) async throws {
        try await coreData.performTransferInTransferContext { context in
            do {
                for element in elements {
                    guard let coreDataPath = element.pathCoreData else { continue }
                    
                    let request: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "url == %@", coreDataPath)
                    request.fetchLimit = 1
                    
                    if let song = try context.fetch(request).first {
                        context.delete(song)
                    }
                }
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
                throw error
            }
        }
    }
    
    func deleteAllSongs() async throws {
        try await coreData.performTransferInTransferContext { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SongEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.coreData.viewContext])
                }
                print("✓ Deleted all songs")
            } catch {
                context.rollback()
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
}

// MARK: - For CompletedUpload usecase
extension SongRepository {
    func performBatchOperation(
        songsToAdd: [Song],
        pathsToUpdate: [String: String],
        elementsToDelete: [PathFileElement]
    ) async throws {
        try await coreData.performWithSerialQueue { context in
            // Add
            for song in songsToAdd {
                let _ = SongEntityMapper.makeEntity(song, context: context)
            }
            
            // Update
            for (oldPath, newPath) in pathsToUpdate {
                let request: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
                request.predicate = NSPredicate(format: "url == %@", oldPath)
                request.fetchLimit = 1
                
                if let song = try context.fetch(request).first {
                    song.url = newPath
                }
            }
            
            // Delete
            for element in elementsToDelete {
                guard let coreDataPath = element.pathCoreData else { continue }
                
                let request: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
                request.predicate = NSPredicate(format: "url == %@", coreDataPath)
                request.fetchLimit = 1
                
                if let song = try context.fetch(request).first {
                    context.delete(song)
                }
            }
            
            // Auto save/rollback
            try context.save()
        }
    }
}
