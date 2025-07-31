//
//  SongEntityMapper.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/31/25.
//

import Foundation

struct SongEntityMapper {
    static func mapToSong(_ entity: SongEntity) -> Song {
        return Song(id: entity.id ?? "",
                    title: entity.title ?? "",
                    album: entity.album ?? "",
                    artist: entity.artist ?? "",
                    duration: entity.duration,
                    urlStr: entity.title ?? "")
    }
}
