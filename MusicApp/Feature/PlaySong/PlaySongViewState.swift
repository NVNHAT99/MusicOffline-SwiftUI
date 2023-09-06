//
//  PlaySongViewState.swift
//  MusicApp
//
//  Created by Nhat on 9/4/23.
//

import Foundation

struct PlaySongState {
    var isPlaying: Bool
    var stateRepeat: StateRepeat
    var timeToTurnOff: Double?
    var currentTimePlaying: Double
    var song: SongInfo?
    var duration: Double
}
