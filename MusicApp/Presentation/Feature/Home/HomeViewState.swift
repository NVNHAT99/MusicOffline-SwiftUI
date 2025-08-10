//
//  HomeViewState.swift
//  MusicApp
//
//  Created by Nhat on 9/14/23.
//

import Foundation

struct HomeViewState {
    var isLoading: Bool = false
    var albums: [Album] = []
    var playlists: [Playlist] = []
    var recentSongs: [Song] = []
}
