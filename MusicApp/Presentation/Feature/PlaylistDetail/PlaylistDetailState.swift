//
//  PlaylistDetailState.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
//

import Foundation

struct PlaylistDetailState {
    var isLoading: Bool = true
    var songs: [SongModel] = []
    var toastViewMessage: String = String.empty
    var isShowToastView: Bool = false
    var sortOption: PlaylistSortOption = .nameAscending
    var isEditMode: Bool = false
    var selectedSongIDs: Set<UUID> = []

    // Player snapshot — drives per-row play/pause indicator
    var currentSongID: UUID? = nil
    var isPlaying: Bool = false
}
