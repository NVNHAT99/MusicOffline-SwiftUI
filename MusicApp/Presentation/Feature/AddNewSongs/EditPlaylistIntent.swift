//
//  AddNewSongsIntent.swift
//  MusicApp
//
//  Created by Nhat on 9/21/23.
//

import Foundation

enum EditPlaylistIntent {
    case loadListSong
    case toggleSelectedAt(index: Int)
    case savePlaylist
}
