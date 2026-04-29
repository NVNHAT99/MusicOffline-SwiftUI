//
//  AddNewPlaylistState.swift
//  MusicApp
//
//  Created by Nhat on 10/7/23.
//

import Foundation

struct AddNewPlaylistState {
    var isShowToastView: Bool = false
    var toastViewMessage: String = String.empty
    var completedAddPlaylist: Bool = false
    var playlistName: String = String.empty
    var heightOfKeyboard: CGFloat = 0.0
    var nameError: String? = nil
}
