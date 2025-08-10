//
//  SongEntityMapper.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/31/25.
//

import Foundation
import CoreData

struct SongEntityMapper {
    static func mapToSong(_ entity: SongEntity) -> Song {
        
        return Song(id: entity.id ?? UUID(),
                    title: entity.title ?? "",
                    album: entity.album ?? "",
                    artist: entity.artist ?? "",
                    duration: entity.duration,
                    urlStr: entity.url ?? "")
    }
    
    static func makeEntity(_ song: Song, context: NSManagedObjectContext) -> SongEntity {
        let entity = SongEntity(context: context)
        entity.id = song.id
        entity.title = song.title
        entity.album = song.album
        entity.artist = song.artist
        entity.duration = song.duration
        entity.url = song.urlStr
        return entity
    }
}
