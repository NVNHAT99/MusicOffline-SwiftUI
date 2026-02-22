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
        }

        return newState
    }
}
