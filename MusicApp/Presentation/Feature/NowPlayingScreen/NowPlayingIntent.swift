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
    case seekDragging(Double)   // visual-only update during drag, no engine call
    // hour minute second
    case setSleepTime(Double, Double, Double)
    case cancelSleepTime
    // Lyrics
    case toggleLyrics
    case lyricsLoaded([LyricsLine])
}
