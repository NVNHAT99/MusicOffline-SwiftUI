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
    /// High-frequency playback position, published separately from `state` so a
    /// 1s tick only re-renders the progress bar/label — not the whole player +
    /// lyrics List that observe `state`.
    var currentTime: Double { get set }
    var activeLyricIndex: Int? { get }
    var isDragging: Bool { get set }
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
    // High-frequency values kept out of `state` so the per-second tick only
    // invalidates the progress slider/label, not the entire player + lyrics List.
    @Published var currentTime: Double = 0
    @Published var activeLyricIndex: Int? = nil
    @Published var isDragging: Bool = false

    // MARK: - Dependencies
    private let playerManager: any PlayerManagerProtocol
    private let reducer: any NowPlayingStateReducerProtocol
    private let fetchLyricsUseCase: FetchLyricsUseCaseProtocol
    private let attachLyricsUseCase: AttachLyricsToSongUseCaseProtocol
    private let removeLyricsUseCase: RemoveLyricsUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var lastLyricsSongStem: String? = nil

    // MARK: - Init
    init(
        playerManager: any PlayerManagerProtocol = PlayerManager.shared,
        reducer: any NowPlayingStateReducerProtocol = NowPlayingStateReducerImpl(),
        fetchLyricsUseCase: FetchLyricsUseCaseProtocol = FetchLyricsUseCase(repository: LyricsRepository()),
        attachLyricsUseCase: AttachLyricsToSongUseCaseProtocol = AttachLyricsToSongUseCase(),
        removeLyricsUseCase: RemoveLyricsUseCaseProtocol = RemoveLyricsUseCase()
    ) {
        self.playerManager = playerManager
        self.reducer = reducer
        self.fetchLyricsUseCase = fetchLyricsUseCase
        self.attachLyricsUseCase = attachLyricsUseCase
        self.removeLyricsUseCase = removeLyricsUseCase
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
        // High-frequency position lives outside `state` — update it (and the
        // derived active lyric) without reassigning `state` on every tick.
        if !isDragging {
            currentTime = playerState.currentTimePlay
            recomputeActiveLyric()
        }

        // Only reassign `state` (which the whole player + lyrics List observe)
        // when something structural actually changed, not on a pure time tick.
        let structuralChanged =
            state.currentSong != playerState.currentSong ||
            state.isPlaying != playerState.isPlaying ||
            state.shuffleEnabled != playerState.shuffleEnabled ||
            state.repeatMode != playerState.repeatMode ||
            state.duration != (playerState.currentSong?.duration ?? 0)

        if structuralChanged {
            state = reducer.reduce(state, with: .updateFromPlayerState(playerState))
        }

        let newStem = Self.lyricsStem(from: playerState.currentSong?.urlStr)
        if newStem != lastLyricsSongStem {
            lastLyricsSongStem = newStem
            let stem = newStem ?? ""
            let lines = stem.isEmpty ? [] : fetchLyricsUseCase.execute(stem: stem)
            state = reducer.reduce(state, with: .setLyrics(lines))
            recomputeActiveLyric()
        }
    }

    private func recomputeActiveLyric() {
        guard !state.lyrics.isEmpty else {
            if activeLyricIndex != nil { activeLyricIndex = nil }
            return
        }
        let newIndex = NowPlayingStateReducerImpl.activeLyricIndex(for: currentTime, in: state.lyrics)
        if newIndex != activeLyricIndex {
            activeLyricIndex = newIndex
        }
    }

    /// Robust stem extraction handling:
    ///   - plain path  ("/var/.../My Song.mp3")
    ///   - file:// URL ("file:///var/.../My%20Song.mp3" — percent-decoded)
    ///   - bare filename ("My Song.mp3")
    nonisolated static func lyricsStem(from urlStr: String?) -> String? {
        guard let raw = urlStr, !raw.isEmpty else { return nil }
        let url: URL
        if raw.hasPrefix("file://"), let parsed = URL(string: raw) {
            url = parsed
        } else {
            url = URL(fileURLWithPath: raw)
        }
        let stem = url.deletingPathExtension().lastPathComponent
        return stem.isEmpty ? nil : stem
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
            isDragging = true
            currentTime = double
            recomputeActiveLyric()
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

        case .attachLyricsFile(let url):
            handleAttachLyricsFile(url)

        case .pasteLyrics(let content):
            handlePasteLyrics(content)

        case .removeLyrics:
            handleRemoveLyrics()

        case .presentLyricsMenu(let show):
            state = reducer.reduce(state, with: .setShowLyricsMenu(show))

        case .presentPasteLyricsSheet(let show):
            state = reducer.reduce(state, with: .setShowPasteLyricsSheet(show))

        case .presentLyricsPicker(let show):
            state = reducer.reduce(state, with: .setShowLyricsPicker(show))

        case .setLyricsErrorMessage(let msg):
            state = reducer.reduce(state, with: .setLyricsErrorMessage(msg))
        }
    }

    // MARK: - Lyrics attach / paste / remove

    /// Stem of the currently-playing song, derived once via the same logic used for auto-load.
    private var currentSongStem: String? {
        Self.lyricsStem(from: state.currentSong?.urlStr)
    }

    private func handleAttachLyricsFile(_ url: URL) {
        guard let stem = currentSongStem else {
            state = reducer.reduce(state, with: .setLyricsErrorMessage("No song is playing"))
            return
        }
        do {
            try attachLyricsUseCase.executeFromFile(url: url, stem: stem)
            reloadLyricsForCurrentSong(stem: stem)
        } catch {
            Logger.error("Attach lyrics failed: \(error)")
            state = reducer.reduce(state, with: .setLyricsErrorMessage(error.localizedDescription))
        }
    }

    private func handlePasteLyrics(_ content: String) {
        guard let stem = currentSongStem else {
            state = reducer.reduce(state, with: .setLyricsErrorMessage("No song is playing"))
            return
        }
        do {
            try attachLyricsUseCase.executeFromText(content: content, stem: stem)
            reloadLyricsForCurrentSong(stem: stem)
            state = reducer.reduce(state, with: .setShowPasteLyricsSheet(false))
        } catch {
            Logger.error("Paste lyrics failed: \(error)")
            state = reducer.reduce(state, with: .setLyricsErrorMessage(error.localizedDescription))
        }
    }

    private func handleRemoveLyrics() {
        guard let stem = currentSongStem else { return }
        removeLyricsUseCase.execute(stem: stem)
        state = reducer.reduce(state, with: .setLyrics([]))
    }

    private func reloadLyricsForCurrentSong(stem: String) {
        let lines = fetchLyricsUseCase.execute(stem: stem)
        state = reducer.reduce(state, with: .setLyrics(lines))
        // Auto-open the lyrics panel after a successful attach/paste so the user
        // sees feedback that lyrics actually loaded.
        if !lines.isEmpty {
            state = reducer.reduce(state, with: .setShowLyrics(true))
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
        isDragging = false
        currentTime = time
        recomputeActiveLyric()
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
        return currentTime.toTimeString()
    }
}
