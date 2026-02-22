//
//  LibaryStateReducer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Protocol for Library state reducer
protocol LibaryStateReducerProtocol {
    func reduce(_ state: LibaryViewState, with action: LibaryStateAction) -> LibaryViewState
}

/// Implementation of Library state reducer (pure function)
final class LibaryStateReducerImpl: LibaryStateReducerProtocol {

    func reduce(_ state: LibaryViewState, with action: LibaryStateAction) -> LibaryViewState {
        var newState = state

        switch action {
        case .setLoading(let loading):
            newState.isLoading = loading

        case .setPlaylists(let playlists):
            newState.playlist = playlists
            newState.isLoading = false

        case .setShowToast(let show, let message):
            newState.isShowToastView = show
            newState.toastViewMessage = message

        case .setShowAddPlaylist(let show):
            newState.isShowAddPlaylist = show

        case .removePlaylist(let playlist):
            newState.playlist.removeAll { $0.id == playlist.id }
        }

        return newState
    }
}
