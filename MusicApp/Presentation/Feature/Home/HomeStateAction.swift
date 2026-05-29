//
//  HomeStateAction.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Actions that can transform the Home state
enum HomeStateAction {
    case setLoadingRecentSongs(Bool)
    case setLoadingPlaylist(Bool)
    case setPlaylists([Playlist])
    case setAlbums([Album])
    case setRecentSongs([RecentSongItem])
}
