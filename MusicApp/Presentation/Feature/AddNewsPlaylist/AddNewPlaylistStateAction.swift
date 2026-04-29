//
//  AddNewPlaylistStateAction.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Actions that can transform the AddNewPlaylist state
enum AddNewPlaylistStateAction {
    case setPlaylistName(String)
    case setHeightOfKeyboard(CGFloat)
    case setShowToast(Bool, message: String)
    case setCompletedAddPlaylist(Bool)
    case setNameError(String?)
}
