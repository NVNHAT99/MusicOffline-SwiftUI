//
//  NowPlayingViewModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/28/25.
//

import Combine
import SwiftUI

@MainActor
protocol NowPlayingViewModelProtocol: ObservableObject {
    var state: NowPlayingState { get set }
    func send(_ intent: NowPlayingIntent)
    var playButtonIcon: String { get }
    var shuffleButtonColor: Color { get }
    var repeatButtonIcon: String { get }
    var repeatButtonColor: Color { get }
    var songTitle: String { get }
    var artistName: String { get }
    var currentTimeStr: String { get }
}


@MainActor
final class NowPlayingViewModel: NowPlayingViewModelProtocol {

    // MARK: - Published Properties
    @Published var state: NowPlayingState = .init()

    // MARK: - Dependencies
    private let playerManager: any PlayerManagerProtocol
    private let reducer: any NowPlayingStateReducerProtocol
    private let fetchLyricsUseCase: FetchLyricsUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var lastLyricsSongStem: String? = nil

    // MARK: - Init
    init(
        playerManager: any PlayerManagerProtocol = PlayerManager.shared,
        reducer: any NowPlayingStateReducerProtocol = NowPlayingStateReducerImpl(),
        fetchLyricsUseCase: FetchLyricsUseCaseProtocol = FetchLyricsUseCase(repository: LyricsRepository())
    ) {
        self.playerManager = playerManager
        self.reducer = reducer
        self.fetchLyricsUseCase = fetchLyricsUseCase
        self.state = .init()
        Logger.debug("NowPlayingViewModel initialized")
        setupBindings()
    }

    // MARK: - Setup
    private func setupBindings() {
        playerManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playerState in
                self?.updateFromPlayerState(playerState)
            }
            .store(in: &cancellables)

        playerManager.missingFilePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                guard let self else { return }
                state = reducer.reduce(state, with: .setErrorMessage("File not found: \(title)"))
                // Auto-clear after 3s
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    self.state = self.reducer.reduce(self.state, with: .setErrorMessage(nil))
                }
            }
            .store(in: &cancellables)

        updateFromPlayerState(playerManager.state)
    }

    private func updateFromPlayerState(_ playerState: PlayerManagerState) {
        state = reducer.reduce(state, with: .updateFromPlayerState(playerState))
        // Fetch lyrics when song changes
        let newStem: String? = playerState.currentSong.flatMap { song -> String? in
            guard let urlStr = song.urlStr, !urlStr.isEmpty else { return nil }
            let stem = URL(fileURLWithPath: urlStr).deletingPathExtension().lastPathComponent
            return stem.isEmpty ? nil : stem
        }
        if newStem != lastLyricsSongStem {
            lastLyricsSongStem = newStem
            let stem = newStem ?? ""
            let lines = stem.isEmpty ? [] : fetchLyricsUseCase.execute(stem: stem)
            state = reducer.reduce(state, with: .setLyrics(lines))
        }
    }

    func send(_ intent: NowPlayingIntent) {
        Logger.debug("NowPlayingViewModel.send() - Intent: \(intent)")

        switch intent {
        case .togglePlay:
            Logger.debug("Toggling play/pause")
            playPause()
        case .goNext:
            Logger.debug("Going to next song")
            next()
        case .goPrevious:
            Logger.debug("Going to previous song")
            previous()
        case .changeShuffMode:
            Logger.debug("Toggling shuffle mode")
            toggleShuffle()
        case .changeRepeatMode:
            Logger.debug("Changing repeat mode")
            toggleRepeat()
        case .seekTo(let double):
            Logger.debug("Seeking to time: \(double)")
            seek(to: double)
        case .seekDragging(let double):
            state = reducer.reduce(state, with: .setCurrentTime(double))
            state = reducer.reduce(state, with: .setIsDragging(true))
        case .setSleepTime(let hour, let minus, let second):
            let value = hour * 60 * 60 + minus * 60 + second
            Logger.info("Setting sleep timer for \(hour)h \(minus)m \(second)s")
            Task {
                await self.playerManager.scheduleStop(after: value)
            }
        case .cancelSleepTime:
            Logger.info("Canceling sleep timer")
            Task {
                await self.playerManager.cancelScheduleStop()
            }

        case .toggleLyrics:
            state = reducer.reduce(state, with: .setShowLyrics(!state.showLyrics))

        case .lyricsLoaded(let lines):
            state = reducer.reduce(state, with: .setLyrics(lines))
        }
    }

    // MARK: - Actions
    private func playPause() {
        Logger.debug("Play/Pause action - Current state: \(state.isPlaying)")
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
        state = reducer.reduce(state, with: .setIsDragging(false))
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
