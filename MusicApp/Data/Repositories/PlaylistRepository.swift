//
//  PlaylistRepository.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation
import CoreData

final class PlaylistRepository: PlaylistRepositoryProtocol {
    
    private let coreDataService: CoreDataProtocol
    
    init(coreDataService: CoreDataProtocol = CoreDataManager.shared) {
        self.coreDataService = coreDataService
    }
    
    func fetchAllPlayList() async throws -> [Playlist] {
        return try await coreDataService.performWithSerialQueue { context in
            let fetchReqeust: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            fetchReqeust.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let listPlaylist = try context.fetch(fetchReqeust)
                let result = listPlaylist.compactMap({ PlaylistEntityMapper.mapToPlayList($0) })
                return result
            } catch {
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
    
    func addPlaylist(with playlist: Playlist) async throws {
        try await coreDataService.performWithSerialQueue { context in
            let playlistEntity = PlaylistEntityMapper.makePlaylistEntity(playlist,
                                                                         context: context)
            do {
                try context.save()
                print("✓ Saved playlist: \(playlistEntity.name ?? "") with ID: \(playlistEntity.id?.uuidString ?? "")")
            } catch {
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
    
    func deletePlaylist(with playListId: String) async throws {
        try await coreDataService.performWithSerialQueue { context in
            guard let uuid = UUID(uuidString: playListId) else {
                throw CoreDataError.entityNotFound
            }
            
            let fetchPlaylistRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            fetchPlaylistRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            fetchPlaylistRequest.fetchLimit = 1
            
            do {
                if let playlistToDelete = try context.fetch(fetchPlaylistRequest).first {
                    context.delete(playlistToDelete)
                    try context.save()
                    print("✓ Deleted playlist: \(playlistToDelete.name ?? "") with ID: \(playlistToDelete.id?.uuidString ?? "")")
                } else {
                    throw CoreDataError.entityNotFound
                }
            } catch {
                context.rollback()
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
    
    func deleteListPlaylist(with playlistIDs: [String]) async throws {
        try await coreDataService.performWithSerialQueue { context in
            let uuidArray = playlistIDs.map(UUID.init)
            
            do {
                for uuid in uuidArray {
                    guard let uuid = uuid else { continue }
                    
                    let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg )
                    request.fetchLimit = 1
                    
                    if let playlistDelete = try context.fetch(request).first {
                        context.delete(playlistDelete)
                    }
                }
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
}
