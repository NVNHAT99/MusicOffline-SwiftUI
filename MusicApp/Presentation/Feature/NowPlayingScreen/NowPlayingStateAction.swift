//
//  NowPlayingStateAction.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Actions that can transform the NowPlaying state
enum NowPlayingStateAction {
    case setCurrentSong(SongModel?)
    case setIsPlaying(Bool)
    case setShuffleEnabled(Bool)
    case setRepeatMode(RepeatMode)
    case setCurrentTime(Double)
    case setDuration(Double)
    case setIsDragging(Bool)
    case setErrorMessage(String?)
    case updateFromPlayerState(PlayerManagerState)
    // Lyrics
    case setLyrics([LyricsLine])
    case setActiveLyricIndex(Int?)
    case setShowLyrics(Bool)
    case setShowLyricsMenu(Bool)
    case setShowPasteLyricsSheet(Bool)
    case setShowLyricsPicker(Bool)
    case setLyricsErrorMessage(String?)
}
