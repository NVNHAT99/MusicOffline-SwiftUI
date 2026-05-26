//
//  NowPlayingState.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/28/25.
//

struct NowPlayingState {
    var currentSong: SongModel?
    var isPlaying: Bool = false
    var shuffleEnabled: Bool = false
    var repeatMode: RepeatMode = .none
    var currentTime: Double = 0
    var duration: Double = 100
    var isDraging: Bool = false
    var errorMessage: String? = nil

    // Lyrics
    var lyrics: [LyricsLine] = []
    var activeLyricIndex: Int? = nil
    var showLyrics: Bool = false
    var showLyricsMenu: Bool = false
    var showPasteLyricsSheet: Bool = false
    var showLyricsPicker: Bool = false
    var lyricsErrorMessage: String? = nil
}
