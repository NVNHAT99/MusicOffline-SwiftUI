//
//  AddNewSongState.swift
//  MusicApp
//
//  Created by Nhat on 9/21/23.
//

import Foundation

struct AddNewSongState {
    var arrayMP3File: [MP3File] = []
    var selectedCount: Int = 0
    var isLoaded: Bool = false
    var playlist: Playlist?
}
