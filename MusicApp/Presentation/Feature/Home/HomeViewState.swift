//
//  HomeViewState.swift
//  MusicApp
//
//  Created by Nhat on 9/14/23.
//

import Foundation

struct HomeViewState {
    var isLoadingRecentSongs: Bool = false
    var isLoadingPlaylist: Bool = false
    var albums: [Album] = []
    var playlists: [Playlist] = []
    // TODO: RecentSongItem not defined - comment out for now
    // var recentSongs: [RecentSongItem] = []
}
