//
//  NowPlayingViewModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/28/25.
//

import Combine
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var state: NowPlayingState = .init()
    
    // MARK: - Dependencies
    private let playerManager: any PlayerManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(playerManager: any PlayerManagerProtocol = PlayerManager.shared) {
        self.playerManager = playerManager
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Observe PlayerManager state changes
        playerManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateFromPlayerState(state)
            }
            .store(in: &cancellables)
        
        // Initial update
        updateFromPlayerState(playerManager.state)
    }
    
    private func updateFromPlayerState(_ state: PlayerManagerState) {
        var newState: NowPlayingState = .init()
        newState.currentSong = state.currentSong
        newState.isPlaying = state.isPlaying
        newState.shuffleEnabled = state.shuffleEnabled
        newState.repeatMode = state.repeatMode
        if !self.state.isDraging {
            newState.currentTime = state.currentTimePlay
        }
        newState.duration = state.currentSong?.duration ?? 0
        self.state = newState
    }
    
    func send(_ intent: NowPlayingIntent) {
        switch intent {
        case .togglePlay:
            playPause()
        case .goNext:
            next()
        case .goPrevious:
            previous()
        case .changeShuffMode:
            toggleShuffle()
        case .changeRepeatMode:
            toggleRepeat()
        case .seekTo(let double):
            seek(to: double)
        case .setSleepTime(let hour, let minus, let second):
            let value = hour * 60 * 60 + minus * 60 + second
            Task {
                await self.playerManager.scheduleStop(after: value)
            }
        case .cancelSleepTime:
            Task {
                await self.playerManager.cancelScheduleStop()
            }
        }
    }
    // MARK: - Actions
    private func playPause() {
        Task {
            if state.isPlaying {
                await playerManager.pause()
            } else {
                await playerManager.play()
            }
        }
    }
    
    private func next() {
        Task {
            await playerManager.next()
        }
    }
    
    private func previous() {
        Task {
            await playerManager.previous()
        }
    }
    
    private func toggleShuffle() {
        Task {
            await playerManager.toggleShuffle()
        }
    }
    
    private func toggleRepeat() {
        Task {
            switch state.repeatMode {
            case .none:
                await playerManager.setRepeatMode(.one)
            case .one:
                await playerManager.setRepeatMode(.all)
            case .all:
                await playerManager.setRepeatMode(.none)
            }
        }
    }
    
    private func seek(to time: Double) {
        playerManager.seek(to: time)
    }
    
    // MARK: - Computed Properties
    var playButtonIcon: String {
        return state.isPlaying ? "pause.circle.fill" : "play.circle.fill"
    }
    
    var shuffleButtonColor: Color {
        return state.shuffleEnabled ? .white : .gray
    }
    
    var repeatButtonIcon: String {
        switch state.repeatMode {
        case .none:
            return "repeat"
        case .one:
            return "repeat.1"
        case .all:
            return "repeat"
        }
    }
    
    var repeatButtonColor: Color {
        return state.repeatMode != .none ? .white : .gray
    }
    
    var songTitle: String {
        return state.currentSong?.title ?? "Unknown"
    }
    
    var artistName: String {
        return state.currentSong?.artist ?? "Unknown Artist"
    }
    
    var currentTimeStr: String {
        return state.currentTime.toTimeString()
    }
}
