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
    
    func fetchAllPlayList(sortBy: PlaylistSortOption = .nameAscending) async throws -> [Playlist] {
        return try await coreDataService.performWithSerialQueue { context in
            let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            switch sortBy {
            case .nameAscending:
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            case .dateCreated:
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            case .songCount:
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            }

            do {
                let listPlaylist = try context.fetch(fetchRequest)
                var result = listPlaylist.compactMap({ PlaylistEntityMapper.mapToPlayList($0) })
                if sortBy == .songCount {
                    result.sort { $0.songIDs.count > $1.songIDs.count }
                }
                return result
            } catch {
                throw CoreDataError.deleteFailed(error)
            }
        }
    }

    func updateSongOrder(playlistId: UUID, orderedSongIDs: [UUID]) async throws {
        try await coreDataService.performWithSerialQueue { context in
            let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", playlistId as CVarArg)
            fetchRequest.fetchLimit = 1

            do {
                if let playlist = try context.fetch(fetchRequest).first {
                    playlist.songUUIDs = orderedSongIDs
                }
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                throw CoreDataError.saveFailed(error)
            }
        }
    }
    
    func fetchPlaylist(with idArray: [UUID]) async throws -> [Playlist] {
        return try await coreDataService.performWithSerialQueue { context in
            let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", idArray)
            
            do {
                let resultList = try context.fetch(fetchRequest)
                let result = resultList.compactMap({ PlaylistEntityMapper.mapToPlayList($0) })
                return result
            } catch {
                throw CoreDataError.entityNotFound
            }
        }
    }
    
    func fetchPlaylist(with name: String) async throws -> Playlist? {
        return try await coreDataService.performWithSerialQueue { context in
            let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name =[cd] %@", name)
            fetchRequest.fetchLimit = 1
            
            do {
                guard let playlist = try context.fetch(fetchRequest).first else {
                    return nil
                }
                let result = PlaylistEntityMapper.mapToPlayList(playlist)
                return result
            } catch {
                throw CoreDataError.entityNotFound
            }
        }
    }
    
    func fetchPlaylist(with id: UUID) async throws -> Playlist? {
        return try await coreDataService.performWithSerialQueue { context in
            let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                guard let playlist = try context.fetch(fetchRequest).first else {
                    return nil
                }
                let result = PlaylistEntityMapper.mapToPlayList(playlist)
                return result
            } catch {
                throw CoreDataError.entityNotFound
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
    
    func deletePlaylist(with playListId: UUID) async throws {
        try await coreDataService.performWithSerialQueue { context in
            
            let fetchPlaylistRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            fetchPlaylistRequest.predicate = NSPredicate(format: "id == %@", playListId as CVarArg)
            fetchPlaylistRequest.fetchLimit = 1
            
            do {
                if let playlistToDelete = try context.fetch(fetchPlaylistRequest).first {
                    context.delete(playlistToDelete)
                    print("✓ Deleted playlist: \(playlistToDelete.name ?? "") with ID: \(playlistToDelete.id?.uuidString ?? "")")
                    try context.save()
                } else {
                    throw CoreDataError.entityNotFound
                }
            } catch {
                context.rollback()
                throw CoreDataError.deleteFailed(error)
            }
        }
    }
    
    func deleteListPlaylist(with playlistIDs: [UUID]) async throws {
        try await coreDataService.performWithSerialQueue { context in
            do {
                for uuid in playlistIDs {
                    
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
    
    func updatePlaylist(by playlistID: UUID, with songIds: [UUID]) async throws {
        try await coreDataService.performWithSerialQueue { context in
            
            let fetchPlaylistRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            fetchPlaylistRequest.predicate = NSPredicate(format: "id == %@", playlistID as CVarArg)
            fetchPlaylistRequest.fetchLimit = 1
            
            do {
                if let playlistUpdate = try context.fetch(fetchPlaylistRequest).first {
                    playlistUpdate.songUUIDs = songIds
                }
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                throw CoreDataError.saveFailed(error)
            }
        }
    }

    func removeDeleteSong(from songId: UUID) async throws {
        try await coreDataService.performWithSerialQueue { context in
            let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            request.predicate = NSPredicate(format: "ANY songIDs == %@", songId.uuidString)
            do {
                let arrayPlaylist = try context.fetch(request)
                for playlist in arrayPlaylist {
                    playlist.songUUIDs = playlist.songUUIDs.filter { $0 != songId }
                }
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                throw CoreDataError.saveFailed(error)
            }
        }
    }
}
