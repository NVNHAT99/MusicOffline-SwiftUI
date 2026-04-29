//
//  ImportSongState.swift
//  MusicApp
//

import Foundation

struct ImportSongState {
    var isImporting: Bool = false
    var progress: Int = 0
    var total: Int = 0
    var results: [ImportSongResult] = []
    var isShowResults: Bool = false
}
