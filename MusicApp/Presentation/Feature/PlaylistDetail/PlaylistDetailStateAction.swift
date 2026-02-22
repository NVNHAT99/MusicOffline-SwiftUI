//
//  PlaylistDetailStateAction.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Actions that can transform the PlaylistDetail state
enum PlaylistDetailStateAction {
    case setLoading(Bool)
    case setSongs([SongModel])
    case setShowToast(Bool, message: String)
}
