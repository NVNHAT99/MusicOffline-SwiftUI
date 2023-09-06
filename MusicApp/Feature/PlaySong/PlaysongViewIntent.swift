//
//  PlaysongViewIntent.swift
//  MusicApp
//
//  Created by Nhat on 9/4/23.
//

import Foundation

enum PlaysongViewIntent {
    case play
    case pause
    case nextSong
    case previusSong
    case stateRepeat(state: StateRepeat)
    case timeTurnOff(time: Double)
}

enum StateRepeat: String {
    case nomal = "nomal"
    case repeatOne = "repeatOne"
    case repeatPlayistOne = "repeatPlayistOne"
}
