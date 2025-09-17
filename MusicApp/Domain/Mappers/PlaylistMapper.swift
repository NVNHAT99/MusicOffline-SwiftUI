//
//  PlaylistMapper.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation

struct PlaylistMapper {
    static func makePlaylist(width title: String, and songIDs: [UUID]) -> Playlist {
        return Playlist.init(id: UUID(), name: title, songIDs: songIDs)
    }
}
