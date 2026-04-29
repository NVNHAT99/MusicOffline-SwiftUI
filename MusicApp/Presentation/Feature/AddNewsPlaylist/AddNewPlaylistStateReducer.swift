//
//  AddNewPlaylistStateReducer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Protocol for AddNewPlaylist state reducer
protocol AddNewPlaylistStateReducerProtocol {
    func reduce(_ state: AddNewPlaylistState, with action: AddNewPlaylistStateAction) -> AddNewPlaylistState
}

/// Implementation of AddNewPlaylist state reducer (pure function)
final class AddNewPlaylistStateReducerImpl: AddNewPlaylistStateReducerProtocol {

    func reduce(_ state: AddNewPlaylistState, with action: AddNewPlaylistStateAction) -> AddNewPlaylistState {
        var newState = state

        switch action {
        case .setPlaylistName(let name):
            newState.playlistName = name

        case .setHeightOfKeyboard(let height):
            newState.heightOfKeyboard = height

        case .setShowToast(let show, let message):
            newState.isShowToastView = show
            newState.toastViewMessage = message

        case .setCompletedAddPlaylist(let completed):
            newState.completedAddPlaylist = completed

        case .setNameError(let error):
            newState.nameError = error
        }

        return newState
    }
}
