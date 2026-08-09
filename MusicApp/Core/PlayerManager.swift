//
//  PlayerManager.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/27/25.
//

import Foundation
import Combine

// Types extracted to PlayerManagerTypes.swift

@MainActor
final class PlayerManager: PlayerManagerProtocol {

    static let shared = PlayerManager(
        engine: AVAudioPlayerEngineService.shared,
        timerService: GCDTimerService(),
        progressTimerService: ProgressTimerService(),
        fetchPlaylistUseCase: FetchPlaylistUseCase(),
        fetchSongUseCase: FetchSongUseCase()
    )

    // MARK: - Dependencies
    private let engine: AudioEngineProtocol
    private let timerService: TimerServiceProtocol
    private let progressTimerService: ProgressTimerServiceProtocol
    private let fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol
    private let fetchSongUseCase: FetchSongUseCaseProtocol
    
    // MARK: - Published state
    @Published private(set) var state: PlayerManagerState = .init()
    var statePublisher: Published<PlayerManagerState>.Publisher {
        $state
    }
    
    private let refreshHomeSubject = PassthroughSubject<Void, Never>()
    var refreshHomePubliser: AnyPublisher<Void, Never> {
        refreshHomeSubject.eraseToAnyPublisher()
    }

    private let missingFileSubject = PassthroughSubject<String, Never>()
    /// Publishes song title when file is missing/unreadable
    var missingFilePublisher: AnyPublisher<String, Never> {
        missingFileSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private state
    private var cancellables = Set<AnyCancellable>()
    private var shuffledOrder: [Int] = []
    private var playlist: [SongModel] = []
    private var currentPlaylistID: UUID?
    // Guards against infinite next() recursion when every file is missing
    // (e.g. after iCloud offload). Reset on any successful load.
    private var consecutiveLoadFailures: Int = 0
    // End-of-song can be signalled by both the progress timer reaching duration
    // and the engine's .finished callback; this dedupes so the song only advances
    // once per completion.
    private var isHandlingFinish = false
    // MARK: - Init
    private init(engine: AudioEngineProtocol,
                 timerService: TimerServiceProtocol,
                 progressTimerService: ProgressTimerServiceProtocol,
                 fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol,
                 fetchSongUseCase: FetchSongUseCaseProtocol) {
        self.engine = engine
        self.timerService = timerService
        self.fetchPlaylistUseCase = fetchPlaylistUseCase
        self.fetchSongUseCase = fetchSongUseCase
        self.progressTimerService = progressTimerService
        subscribeToEngineEvents()
        subscribeToPlaylistEvents()

        Logger.info("PlayerManager initialized")
        loadPersistedSettings()
        initData()
    }
    
    private func loadPersistedSettings() {
        state.shuffleEnabled = UserDefaults.standard.bool(forKey: "shuffleEnabled")
        let rawRepeat = UserDefaults.standard.integer(forKey: "repeatMode")
        state.repeatMode = RepeatMode(rawValue: rawRepeat) ?? .none
    }

    private func initData() {
        Logger.debug("[Player] initData start — isPlaying=\(state.isPlaying)")
        if let playlistID = UUID(uuidString: RecentSongsManager.fetchCurrentPlaylist() ?? "") {
            Task {
                await reloadPlaylist(id: playlistID)
                if let recentSong = RecentSongsManager.fetchRecentSongs().first, self.playlist.contains(recentSong.song) {
                    self.state.currentSong = recentSong.song

                } else {
                    self.state.currentSong = self.playlist.first
                }

                Logger.debug("[Player] initData restored currentSong='\(self.state.currentSong?.title ?? "nil")' isPlaying=\(self.state.isPlaying)")
                if let currentSong = self.state.currentSong {
                    loadSong(song: currentSong)
                }
            }
        }
    }

    // MARK: - Subscribe
    private func subscribeToEngineEvents() {
        engine.eventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .finished(let success):
                    if success {
                        Task { await self.handleSongFinished() }
                    }
                case .pausedBySystem:
                    // Headphones unplugged or an interruption stopped audio.
                    // Reflect it in state so the mini player / lock screen /
                    // Control Center show "paused" instead of a stale play state.
                    self.state.isPlaying = false
                    self.progressTimerService.stop()
                case .resumedBySystem:
                    // Interruption ended and audio auto-resumed — realign state.
                    self.state.isPlaying = true
                    self.progressTimerService.resume()
                }
            }
            .store(in: &cancellables)
        
        progressTimerService.tickPublisher
            .sink { [weak self] time in
                guard let self else { return }
                let duration = self.state.currentSong?.duration ?? 0

                // The progress timer is a free-running counter, decoupled from the
                // engine's real playback position. Bound it to the song length and
                // drive end-of-song here so completion no longer depends solely on
                // the engine's .finished callback (which can race and be missed,
                // leaving isPlaying stuck true and the timer running past duration).
                if duration > 0, time >= duration {
                    self.state.currentTimePlay = duration
                    Task { await self.handleSongFinished() }
                } else {
                    self.state.currentTimePlay = time
                }
            }
            .store(in: &cancellables)
    }

    private func subscribeToPlaylistEvents() {
        PlaylistEventCenter.shared.subject
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .updated(let id):
                    if id == self.currentPlaylistID {
                        Task {
                            await self.reloadPlaylist(id: id)
                        }
                    }
                case .deleted(let id):
                    if id == self.currentPlaylistID {
                        Task { await self.resetState() }
                    } else {
                        RecentSongsManager.removePlaylist(id: id.uuidString)
                    }
                    
                    refreshHomeSubject.send()
                case .added:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Controls
    func setCurrentPlaylist(id: UUID) async {
        self.currentPlaylistID = id
        await reloadPlaylist(id: id)
    }

    func play(song: SongModel) async {
        Logger.info("Playing song: \(song.title)")
        updateState { state in
            state.currentSong = song
            state.isPlaying = true
        }
        loadAndPlay(song: song)
    }

    func play() async {
        Logger.debug("[Player] play() called (was isPlaying=\(state.isPlaying))")
        guard let currentSong = state.currentSong else {
            Logger.warning("Cannot play - no current song")
            return
        }

        // If the engine has no file loaded (e.g. the song was restored from a
        // previous session but never loaded — common after a stale path was
        // re-resolved), resume would silently no-op while the timer still ran,
        // giving "progress moves but no sound". Do a full load in that case.
        if engine.currentURL == nil {
            loadAndPlay(song: currentSong)
            return
        }
        engine.play()
        progressTimerService.start(interval: 1.0, from: self.state.currentTimePlay)
        updateState { state in
            state.isPlaying = true
        }
    }
    
    func play(_ playlistId: UUID, songs: [SongModel], songPlay: SongModel) async {
        self.currentPlaylistID = playlistId
        self.playlist = songs
        updateState { state in
            state.currentSong = songPlay
        }
        loadAndPlay(song: songPlay)
    }
    
    func play(_ playlistId: UUID, songPlay: SongModel) async {
        do {
            self.currentPlaylistID = playlistId
            let playlist = try await fetchPlaylistUseCase.execute(with: playlistId.uuidString)
            self.playlist = try await fetchSongUseCase.execute(playlist.songIDs).map({SongMapper.mapToSongModel($0)})
            updateState { state in
                state.currentSong = songPlay
            }
            loadAndPlay(song: songPlay)
        } catch {
            print("cant play song from recent song")
        }
    }
    
    func pause() async {
        Logger.debug("[Player] pause() called (was isPlaying=\(state.isPlaying))")
        engine.pause()
        progressTimerService.pause()
        updateState { state in
            state.isPlaying = false
        }
    }

    func stop() async {
        timerService.cancel()
        engine.stop()
        updateState { state in
            state.isPlaying = false
        }
    }

    func next() async {
        guard !playlist.isEmpty else { return }
        
        switch state.repeatMode {
        case .one:
            if let s = state.currentSong {
                await play(song: s)
            }
        case .none:
            if let idx = await computeNextIndex() {
                let s = playlist[idx]
                await play(song: s)
            } else {
                if let song = playlist.first {
                    self.state.currentSong = song
                    self.state.currentTimePlay = 0
                    loadSong(song: song)
                }
            }
        case .all:
            if let idx = await computeNextIndex() {
                let s = playlist[idx]
                await play(song: s)
            }
        }
    }

    func previous() async {
        guard !playlist.isEmpty else { return }
        let prevIdx = ((currentIndex ?? 0) - 1 + playlist.count) % playlist.count
        let s = playlist[prevIdx]
        await play(song: s)
    }

    func toggleShuffle() async {
        updateState { state in
            state.shuffleEnabled.toggle()
        }
        UserDefaults.standard.set(state.shuffleEnabled, forKey: "shuffleEnabled")

        if state.shuffleEnabled {
            await regenerateShuffleOrder(anchoringAt: currentIndex)
        } else {
            shuffledOrder.removeAll()
        }
    }

    func setRepeatMode(_ mode: RepeatMode) async {
        updateState { state in
            state.repeatMode = mode
        }
        UserDefaults.standard.set(mode.rawValue, forKey: "repeatMode") // Int rawValue
    }

    func scheduleStop(after seconds: TimeInterval) async {
        if self.state.currentSong == nil {
            return
        }
        
        timerService.schedule(after: seconds) { [weak self] in
            Task {
                await self?.pause()
            }
        }
    }
    
    func cancelScheduleStop() async {
        if self.state.currentSong == nil {
            return
        }
        
        timerService.cancel()
    }
    
    func seek(to duration: Double) {
        engine.seek(to: duration)
        self.state.currentTimePlay = duration
        progressTimerService.seek(to: duration)
        // Resume timer if playing
        if state.isPlaying {
            progressTimerService.resume()
        }
    }

    // MARK: - Helpers
    private var currentIndex: Int? {
        guard let s = state.currentSong else { return nil }
        return playlist.firstIndex(of: s)
    }

    private func computeNextIndex() async -> Int? {
        guard !playlist.isEmpty else { return nil }

        if state.shuffleEnabled {
            return await computeNextShuffleIndex()
        } else {
            return computeNextLinearIndex()
        }
    }

    private func computeNextShuffleIndex() async -> Int? {
        guard let currentIndex = currentIndex else {
            if shuffledOrder.isEmpty {
                await regenerateShuffleOrder(anchoringAt: nil)
            }
            return shuffledOrder.first
        }

        guard let currentPos = shuffledOrder.firstIndex(of: currentIndex) else {
            await regenerateShuffleOrder(anchoringAt: currentIndex)
            return shuffledOrder.first
        }

        let nextPos = currentPos + 1
        if nextPos < shuffledOrder.count {
            return shuffledOrder[nextPos]
        } else if state.repeatMode == .all {
            await regenerateShuffleOrder(anchoringAt: nil)
            return shuffledOrder.first
        } else {
            return nil
        }
    }

    private func computeNextLinearIndex() -> Int? {
        let currentIndex = self.currentIndex ?? -1
        let nextIndex = currentIndex + 1

        if nextIndex < playlist.count {
            return nextIndex
        } else if state.repeatMode == .all {
            return 0
        } else {
            return nil
        }
    }

    private func regenerateShuffleOrder(anchoringAt anchor: Int?) async {
        var indices = Array(playlist.indices).shuffled()
        if let a = anchor, let pos = indices.firstIndex(of: a) {
            indices.swapAt(0, pos)
        }
        shuffledOrder = indices
    }

    private func loadAndPlay(song: SongModel) {
        guard let path = song.resolvedFilePath() else {
            Logger.error("Song file missing: \(song.urlStr ?? "")")
            handleLoadFailure(song: song)
            return
        }

        do {
            let url = URL(fileURLWithPath: path)
            try engine.load(url: url)
            consecutiveLoadFailures = 0
            isHandlingFinish = false
            RecentSongsManager.add(song, in: self.currentPlaylistID?.uuidString)
            RecentSongsManager.saveCurrentPlaylist(id: self.currentPlaylistID?.uuidString ?? "")
            RecentSongsManager.addRecentPlaylist(id: self.currentPlaylistID?.uuidString ?? String.empty)
            refreshHomeSubject.send()
            engine.play()
            self.state.isPlaying = true
            progressTimerService.start(interval: 1, from: 0)
        } catch {
            Logger.error("Error loading song: \(error)")
            handleLoadFailure(song: song)
        }
    }

    /// Skip to the next song after a load failure, but stop after a full pass
    /// over the playlist so an all-missing playlist (e.g. iCloud-offloaded
    /// library) can't recurse forever — especially under repeatMode == .all.
    private func handleLoadFailure(song: SongModel) {
        missingFileSubject.send(song.title)
        consecutiveLoadFailures += 1

        guard consecutiveLoadFailures < playlist.count else {
            consecutiveLoadFailures = 0
            progressTimerService.stop()
            self.state.isPlaying = false
            missingFileSubject.send("No playable songs")
            return
        }

        Task { await next() }
    }
    
    private func loadSong(song: SongModel) {
        Logger.debug("[Player] loadSong '\(song.title)' — will set isPlaying=false (was \(state.isPlaying))")
        guard let path = song.resolvedFilePath() else {
            Logger.error("Song file missing: \(song.urlStr ?? "")")
            return
        }
        do {
            try engine.load(url: URL(fileURLWithPath: path))
            self.state.isPlaying = false
            self.progressTimerService.stop()
        } catch {
            Logger.error("Error loading song: \(error)")
        }
    }

    private func handleSongFinished() async {
        guard !isHandlingFinish else { return }
        isHandlingFinish = true
        progressTimerService.stop()
        self.state.isPlaying = false

        switch state.repeatMode {
        case .one:
            if let s = state.currentSong {
                await play(song: s)
            }
        case .all:
            await next()
        case .none:
            let hasNext = computeNextLinearIndex() != nil
            if hasNext {
                await next()
            } else {
                // End of playlist — reset to beginning, stay paused
                self.state.currentTimePlay = 0
                progressTimerService.seek(to: 0)
                if let first = playlist.first {
                    self.state.currentSong = first
                    loadSong(song: first)
                }
            }
        }
    }
    
    private func reloadPlaylist(id: UUID) async {
        do {
            let playlist = try await fetchPlaylistUseCase.execute(with: id.uuidString)
            let newSongs = try await fetchSongUseCase.execute(playlist.songIDs)
            self.playlist = newSongs.map({ SongMapper.mapToSongModel($0) })
            self.currentPlaylistID = id
            // Regenerate shuffle order if shuffle is active (playlist may have changed)
            if state.shuffleEnabled {
                await regenerateShuffleOrder(anchoringAt: currentIndex)
            }
        } catch {
            Logger.error("Error reloading playlist: \(error)")
        }
    }
    
    private func resetState() async {
        if state.currentSong != nil {
            RecentSongsManager.removePlaylist(id: self.currentPlaylistID?.uuidString ?? String.empty)
        }
        state = PlayerManagerState()
        engine.stop()
        progressTimerService.stop()
        timerService.cancel()
    }
    
    // State writes are main-actor isolated (class is @MainActor).
    private func updateState(_ update: (inout PlayerManagerState) -> Void) {
        update(&self.state)
    }
}
