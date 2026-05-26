//
//  PlaylistDetailStateReducer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Protocol for PlaylistDetail state reducer
protocol PlaylistDetailStateReducerProtocol {
    func reduce(_ state: PlaylistDetailState, with action: PlaylistDetailStateAction) -> PlaylistDetailState
}

/// Implementation of PlaylistDetail state reducer (pure function)
final class PlaylistDetailStateReducerImpl: PlaylistDetailStateReducerProtocol {

    func reduce(_ state: PlaylistDetailState, with action: PlaylistDetailStateAction) -> PlaylistDetailState {
        var newState = state

        switch action {
        case .setLoading(let loading):
            newState.isLoading = loading

        case .setSongs(let songs):
            newState.songs = songs
            newState.isLoading = false

        case .setShowToast(let show, let message):
            newState.isShowToastView = show
            newState.toastViewMessage = message

        case .setEditMode(let editing):
            newState.isEditMode = editing
            if !editing { newState.selectedSongIDs = [] }

        case .toggleSongSelection(let id):
            if newState.selectedSongIDs.contains(id) {
                newState.selectedSongIDs.remove(id)
            } else {
                newState.selectedSongIDs.insert(id)
            }

        case .clearSelection:
            newState.selectedSongIDs = []

        case .setSortOption(let option):
            newState.sortOption = option

        case .setPlayerSnapshot(let currentSongID, let isPlaying):
            newState.currentSongID = currentSongID
            newState.isPlaying = isPlaying
        }

        return newState
    }
}
