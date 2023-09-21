//
//  PlaylistDetailIntent.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
//

import Foundation
enum PlaylistDetailIntent {
    case playSong(index: Int)
    case deleteSong(index: Int)
    case updatePlaylist(Playlist?)
}
