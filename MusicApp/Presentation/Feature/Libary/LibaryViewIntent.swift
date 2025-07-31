//
//  LibaryViewIntent.swift
//  MusicApp
//
//  Created by Nhat on 6/15/23.
//

import Foundation

enum LibaryViewIntent {
    case loadPlaylist
    case addNewPlayList(String)
    case deletePlaylist(Playlist)
    case updateIsPresented(Bool)
    case showAddNewPlaylist(value: Bool)
}
