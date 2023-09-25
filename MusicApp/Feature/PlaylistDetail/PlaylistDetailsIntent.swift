//
//  PlaylistDetailIntent.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
//

import Foundation
enum PlaylistDetailIntent {
    case playSongAt(urlStr: String)
    case deleteSong(index: Int)
    case updatePlaylist(Playlist?)
}
