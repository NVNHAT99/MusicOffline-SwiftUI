//
//  HomeStateReducer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Protocol for Home state reducer
protocol HomeStateReducerProtocol {
    func reduce(_ state: HomeViewState, with action: HomeStateAction) -> HomeViewState
}

/// Implementation of Home state reducer (pure function)
final class HomeStateReducerImpl: HomeStateReducerProtocol {

    func reduce(_ state: HomeViewState, with action: HomeStateAction) -> HomeViewState {
        var newState = state

        switch action {
        case .setLoadingRecentSongs(let loading):
            newState.isLoadingRecentSongs = loading

        case .setLoadingPlaylist(let loading):
            newState.isLoadingPlaylist = loading

        case .setPlaylists(let playlists):
            newState.playlists = playlists
            newState.isLoadingPlaylist = false

        case .setAlbums(let albums):
            newState.albums = albums
        }

        return newState
    }
}
