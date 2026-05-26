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
    case setEditMode(Bool)
    case toggleSongSelection(UUID)
    case clearSelection
    case setSortOption(PlaylistSortOption)
    case setPlayerSnapshot(currentSongID: UUID?, isPlaying: Bool)
}
