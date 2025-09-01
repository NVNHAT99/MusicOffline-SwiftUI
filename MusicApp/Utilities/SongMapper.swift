//
//  SongMapper.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/25/25.
//

import Foundation

struct SongMapper {
    static func mapToSelectedSong(_ song: Song, isSelected: Bool = false) -> SelectedSong {
        return .init(song: SongModel(
            id: song.id,
            title: song.title,
            album: song.album,
            artist: song.artist,
            duration: song.duration,
            urlStr: song.urlStr
        ),
        isSelected: isSelected)
    }
    
    static func mapToSongModel(_ song: Song) -> SongModel {
        return SongModel(
            id: song.id,
            title: song.title,
            album: song.album,
            artist: song.artist,
            duration: song.duration,
            urlStr: song.urlStr
        )
    }
    
    static func mapToSong(_ songModel: SongModel) -> Song {
        return Song(
            id: songModel.id,
            title: songModel.title,
            album: songModel.album,
            artist: songModel.artist,
            duration: songModel.duration,
            urlStr: songModel.urlStr ?? ""
        )
    }
}
