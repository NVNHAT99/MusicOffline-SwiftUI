//
//  LibaryViewState.swift
//  MusicApp
//
//  Created by Nhat on 6/16/23.
//

import Foundation

struct LibaryViewState {
    var isLoading: Bool = false
    var playlist: [Playlist]
    var isShowToastView: Bool = false
    var toastViewMessage: String = String.empty
    var isShowAddPlaylist: Bool = false
}
