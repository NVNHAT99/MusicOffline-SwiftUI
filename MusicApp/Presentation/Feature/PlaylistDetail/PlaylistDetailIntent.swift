//
//  PlaylistDetailIntent.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
//

import Foundation

enum PlaylistDetailIntent {
    case playSongAt(song: SongModel)
    case tapSongRowButton(song: SongModel)   // smart: pause if currently playing, else play
    case deleteSong(index: Int)
    case loadPlaylist
    case reorderSongs(from: IndexSet, to: Int)
    case toggleEditMode
    case toggleSongSelection(id: UUID)
    case bulkDelete
    case setSortOption(PlaylistSortOption)
}
