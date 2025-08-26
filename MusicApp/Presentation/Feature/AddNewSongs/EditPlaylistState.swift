//
//  EditPlaylistState.swift
//  MusicApp
//
//  Created by Nhat on 9/21/23.
//

import Foundation

struct EditPlaylistState {
    var allSongs: [SelectedSong] = []
    var isEnableSaveButton: Bool = false
    var isLoading: Bool = false
    var songIDs: [UUID] = []
    var isSavePlaylistSuccess: Bool = false
}
