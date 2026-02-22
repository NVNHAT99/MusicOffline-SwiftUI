//
//  NowPlayingStateReducer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Protocol for NowPlaying state reducer
protocol NowPlayingStateReducerProtocol {
    func reduce(_ state: NowPlayingState, with action: NowPlayingStateAction) -> NowPlayingState
}

/// Implementation of NowPlaying state reducer (pure function)
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

        case .setDuration(let duration):
            newState.duration = duration

        case .setIsDragging(let dragging):
            newState.isDraging = dragging

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
}
