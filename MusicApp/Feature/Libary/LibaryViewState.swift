//
//  LibaryViewState.swift
//  MusicApp
//
//  Created by Nhat on 6/16/23.
//

import Foundation

struct LibaryViewState {
    var isLoading: Bool
    var isPresnted: Bool
    var playlist: [Playlist]
    var isShowToastView: Bool = false
    var toastViewMessage: String = String.empty
}
