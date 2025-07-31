//
//  SongPrepository.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation
import CoreData

final class SongRepository: SongRepositoryProtocol {
    
    private let coreData: CoreDataProtocol
    
    init(coreData: CoreDataProtocol = CoreDataManager.shared) {
        self.coreData = coreData
    }
    
    func addSong(_ song: Song) async throws {
        guard !song.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreDataError.invalidTitle
        }
        
        let context = coreData.newBackgroundContext()
        return try await context.perform {
            let songEntity = SongMappers.mapToEntity(song: song, context: context)
            do {
                try context.save()
                print("✓ Saved song: \(songEntity.title ?? "") with ID: \(songEntity.id ?? "")")
            } catch {
                context.rollback()
                throw CoreDataError.saveFailed(error)
            }
        }
    }
    
    func addSongs(_ songs: [Song]) async throws {
        let context = coreData.newBackgroundContext()
        return try await context.perform {
            for song in songs {
                let _ = SongMappers.mapToEntity(song: song, context: context)
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
    
    func fetchAllSongs() async throws -> [SongEntity] {
        let context = coreData.newBackgroundContext()
        return try await context.perform {
            let fetchRequest: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)] // Sắp xếp theo title tăng dần
            
            do {
                let results = try context.fetch(fetchRequest)
                return results
            } catch {
                throw CoreDataError.fetchFailed(error)
            }
        }
    }
    
//    func updateSong(id: UUID, newTitle: String) async throws -> SongEntity {
//        
//    }
    
    func deleteSong(withId id: String) async throws {
        let context = coreData.newBackgroundContext()
        try await context.perform {
            let fetchRequest: NSFetchRequest<SongEntity> = SongEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            do {
                if let songToDelete = try context.fetch(fetchRequest).first {
                    context.delete(songToDelete)
                    try context.save()
                    print("✓ Deleted song with ID: \(id)")
                } else {
                    throw CoreDataError.entityNotFound
                }
            } catch {
                context.rollback()
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
    
    func deleteAllSongs() async throws {
        let context = coreData.newBackgroundContext()
        try await context.perform {
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
