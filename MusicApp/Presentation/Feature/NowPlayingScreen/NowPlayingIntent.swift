//
//  NowPlayingIntent.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/30/25.
//

import Foundation

enum NowPlayingIntent {
    case togglePlay
    case goNext
    case goPrevious
    case changeShuffMode
    case changeRepeatMode
    case seekTo(Double)
    // hour minus second
    case setSleepTime(Double, Double, Double)
    case cancelSleepTime
}
