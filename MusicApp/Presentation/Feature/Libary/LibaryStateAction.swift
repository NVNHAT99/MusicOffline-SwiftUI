//
//  LibaryStateAction.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Actions that can transform the Library state
enum LibaryStateAction {
    case setLoading(Bool)
    case setPlaylists([Playlist])
    case setShowToast(Bool, message: String)
    case setShowAddPlaylist(Bool)
    case removePlaylist(Playlist)
}
