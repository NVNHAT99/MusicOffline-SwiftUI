//
//  PlayerManager.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/27/25.
//

import Foundation
import Combine

enum RepeatMode {
    case none
    case one
    case all
}

protocol PlayerManagerProtocol: ObservableObject {
    
    var state: PlayerManagerState { get }
    var statePublisher: Published<PlayerManagerState>.Publisher { get }
    var refreshHomePubliser: AnyPublisher<Void, Never> { get }
    // Controls
    func setCurrentPlaylist(id: UUID) async
    func play(_ playlistId: UUID, songs: [SongModel], songPlay: SongModel) async
    func play(_ playlistId: UUID, songPlay: SongModel) async
    func play(song: SongModel) async
    func play() async
    func pause() async
    func stop() async
    func next() async
    func previous() async
    func toggleShuffle() async
    func setRepeatMode(_ mode: RepeatMode) async
    func scheduleStop(after seconds: TimeInterval) async
    func cancelScheduleStop() async
    func seek(to duration: Double)
}

struct PlayerManagerState {
    var currentSong: SongModel?
    var isPlaying: Bool = false
    var repeatMode: RepeatMode = .none
    var shuffleEnabled: Bool = false
    var currentTimePlay: TimeInterval = 0
}

final class PlayerManager: PlayerManagerProtocol {
    
    static let shared = PlayerManager(
        engine: AVAudioPlayerEngineService.shared,
        timerService: GCDTimerService(),
        progressTimerService: ProgressTimerService(),
        fetchPlaylistUseCase: FetchPlaylistUseCase(),
        fetchSongUseCase: FetchSongUseCase()
    )

    // MARK: - Dependencies
    private let engine: AVAudioPlayerEngineService
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
    
    // MARK: - Private state
    private var cancellables = Set<AnyCancellable>()
    private var shuffledOrder: [Int] = []
    private var playlist: [SongModel] = []
    private var currentPlaylistID: UUID?
    // MARK: - Init
    private init(engine: AVAudioPlayerEngineService,
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
        
        initData()
    }
    
    private func initData() {
        if let playlistID = UUID(uuidString: RecentSongsManager.fetchCurrentPlaylist() ?? "") {
            Task {
                await reloadPlaylist(id: playlistID)
                if let recentSong = RecentSongsManager.fetchRecentSongs().first, self.playlist.contains(recentSong.song) {
                    self.state.currentSong = recentSong.song
                    
                } else {
                    self.state.currentSong = self.playlist.first
                }
                
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
                }
            }
            .store(in: &cancellables)
        
        progressTimerService.tickPublisher
            .sink { [weak self] time in
                self?.state.currentTimePlay = time
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
        updateState { state in
            state.currentSong = song
            state.isPlaying = true
        }
        loadAndPlay(song: song)
    }

    func play() async {
        if state.currentSong == nil {
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
        progressTimerService.start(interval: 1.0, from: duration)
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
        do {
            let url = URL(fileURLWithPath: song.urlStr ?? "")
            print("🎵 Loading from: \(url.absoluteString)")
            try engine.load(url: url)
            // lưu bài hát hiện tại vào user default
            RecentSongsManager.add(song, in: self.currentPlaylistID?.uuidString)
            RecentSongsManager.saveCurrentPlaylist(id: self.currentPlaylistID?.uuidString ?? "")
            RecentSongsManager.addRecentPlaylist(id: self.currentPlaylistID?.uuidString ?? String.empty)
            refreshHomeSubject.send()
            engine.play()
            self.state.isPlaying = true
            progressTimerService.start(interval: 1, from: 0)
        } catch {
            print("⚠️ Error loading song: \(error)")
        }
    }
    
    private func loadSong(song: SongModel) {
        do {
            let url = URL(fileURLWithPath: song.urlStr ?? "")
            try engine.load(url: url)
            self.state.isPlaying = false
            self.progressTimerService.stop()
        } catch {
            print("⚠️ Error loading song: \(error)")
        }
    }

    private func handleSongFinished() async {
        print("bài hát đã hết")
        progressTimerService.stop()
        self.state.isPlaying = false
        
        switch state.repeatMode {
        case .one:
            if let s = state.currentSong {
                await play(song: s)
            }
        case .all, .none:
            await next()
        }
    }
    
    private func reloadPlaylist(id: UUID) async {
        do {
            let playlist = try await fetchPlaylistUseCase.execute(with: id.uuidString)
            let newSongs = try await fetchSongUseCase.execute(playlist.songIDs)
            self.playlist = newSongs.map({ SongMapper.mapToSongModel($0) })
            self.currentPlaylistID = id
        } catch {
            print("Error reloading playlist: \(error)")
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
    
    // Thread-safe state updates
    private func updateState(_ update: (inout PlayerManagerState) -> Void) {
        update(&self.state)
    }
}
