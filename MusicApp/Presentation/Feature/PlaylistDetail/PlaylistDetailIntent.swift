//
//  PlaylistDetailIntent.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
//

import Foundation
enum PlaylistDetailIntent {
    case playSongAt(song: SongModel)
    case deleteSong(index: Int)
    case loadPlaylist
}
