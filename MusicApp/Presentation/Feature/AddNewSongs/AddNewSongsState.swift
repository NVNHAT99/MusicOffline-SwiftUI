//
//  AddNewSongState.swift
//  MusicApp
//
//  Created by Nhat on 9/21/23.
//

import Foundation

struct AddNewSongState {
    var arrayMP3File: [String] = []
    var selectedCount: Int = 0
    var isLoaded: Bool = false
    var playlist: Playlist?
}
