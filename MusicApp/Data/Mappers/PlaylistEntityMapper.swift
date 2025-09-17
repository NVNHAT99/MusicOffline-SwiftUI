//
//  PlaylistEntityMapper.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation
import CoreData

struct PlaylistEntityMapper {
    static func mapToPlayList(_ entity: PlaylistEntity) -> Playlist {
        return Playlist(id: entity.id ?? UUID(),
                        name: entity.name ?? "",
                        songIDs: entity.songUUIDs)
    }
    
    static func makePlaylistEntity(_ playlist: Playlist,
                                   context: NSManagedObjectContext) -> PlaylistEntity {
        let playlistEntity = PlaylistEntity(context: context)
        playlistEntity.id = playlist.id
        playlistEntity.songUUIDs = playlist.songIDs
        playlistEntity.name = playlist.name
        return playlistEntity
    }
}
