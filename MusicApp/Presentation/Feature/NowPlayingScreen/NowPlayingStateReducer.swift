//
//  NowPlayingStateReducer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

protocol NowPlayingStateReducerProtocol {
    func reduce(_ state: NowPlayingState, with action: NowPlayingStateAction) -> NowPlayingState
}

final class NowPlayingStateReducerImpl: NowPlayingStateReducerProtocol {

    func reduce(_ state: NowPlayingState, with action: NowPlayingStateAction) -> NowPlayingState {
        var newState = state

        switch action {
        case .setCurrentSong(let song):
            newState.currentSong = song

        case .setIsPlaying(let playing):
            newState.isPlaying = playing

        case .setShuffleEnabled(let enabled):
            newState.shuffleEnabled = enabled

        case .setRepeatMode(let mode):
            newState.repeatMode = mode

        case .setCurrentTime(let time):
            newState.currentTime = time
            // Recompute active lyric only when crossing a line boundary
            if !state.lyrics.isEmpty {
                let newIndex = Self.activeLyricIndex(for: time, in: state.lyrics)
                if newIndex != state.activeLyricIndex {
                    newState.activeLyricIndex = newIndex
                }
            }

        case .setDuration(let duration):
            newState.duration = duration

        case .setIsDragging(let dragging):
            newState.isDraging = dragging

        case .setErrorMessage(let message):
            newState.errorMessage = message

        case .setLyrics(let lines):
            newState.lyrics = lines
            newState.activeLyricIndex = Self.activeLyricIndex(for: newState.currentTime, in: lines)

        case .setActiveLyricIndex(let index):
            newState.activeLyricIndex = index

        case .setShowLyrics(let show):
            newState.showLyrics = show

        case .updateFromPlayerState(let playerState):
            newState.currentSong = playerState.currentSong
            newState.isPlaying = playerState.isPlaying
            newState.shuffleEnabled = playerState.shuffleEnabled
            newState.repeatMode = playerState.repeatMode
            if !state.isDraging {
                newState.currentTime = playerState.currentTimePlay
            }
            newState.duration = playerState.currentSong?.duration ?? 0
        }

        return newState
    }

    /// Binary search for the last lyric line whose timestamp ≤ currentTime.
    static func activeLyricIndex(for time: TimeInterval, in lines: [LyricsLine]) -> Int? {
        guard !lines.isEmpty else { return nil }
        var lo = 0
        var hi = lines.count - 1
        var result: Int? = nil
        while lo <= hi {
            let mid = (lo + hi) / 2
            if lines[mid].timestamp <= time {
                result = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return result
    }
}
