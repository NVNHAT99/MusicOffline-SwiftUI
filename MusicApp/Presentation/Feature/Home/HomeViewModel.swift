//
//  HomeViewModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/28/25.
//

import SwiftUI
import Combine

@MainActor
protocol HomeViewModelProtocol: ObservableObject {
    var state: HomeViewState { get set }
    func send(_ intent: HomeViewIntent)
}

final class HomeViewModel: HomeViewModelProtocol {

    private let fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol
    private let playerManager: any PlayerManagerProtocol
    @Published var state: HomeViewState
    private let reducer: any HomeStateReducerProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol,
        playerManager: any PlayerManagerProtocol,
        state: HomeViewState = .init(),
        reducer: any HomeStateReducerProtocol = HomeStateReducerImpl()
    ) {
        self.state = state
        self.playerManager = playerManager
        self.fetchPlaylistUseCase = fetchPlaylistUseCase
        self.reducer = reducer

        Logger.debug("HomeViewModel initialized")

        playerManager.refreshHomePubliser
            .receive(on: DispatchQueue.main)
            .sink { [weak self]  _ in
                guard let self = self else {
                    return
                }

                self.fetchSongs()
            }.store(in: &cancellables)
    }

    func send(_ intent: HomeViewIntent) {
        Logger.debug("HomeViewModel.send() - Intent: \(intent)")

        switch intent {
        case .fetchData:
            Logger.debug("Fetching home data")
            self.fetchSongs()
        case .play(let recentSongItem):
            Logger.info("Playing song: \(recentSongItem.song.title)")
            Task {
                if let playlistId = UUID(uuidString: recentSongItem.playlistId ?? "") {
                    await playerManager.play(playlistId, songPlay: recentSongItem.song)
                }
            }
        }
    }

    private func fetchSongs() {
        Task {
            Logger.debug("Fetching songs for home view")

            await MainActor.run {
                state = reducer.reduce(state, with: .setLoadingPlaylist(true))
            }

            do {
                Logger.debug("Fetching recent playlist")
                let playlistRecentID = RecentSongsManager.fetchRecentPlaylists()
                let recentPlaylist = try await fetchPlaylistUseCase.excute(with: playlistRecentID)
                Logger.debug("Recent playlist ID: \(playlistRecentID)")
                await MainActor.run {
                    // setPlaylists action auto-clears isLoadingPlaylist via the reducer.
                    state = reducer.reduce(state, with: .setPlaylists(recentPlaylist))
                }
                Logger.info("Loaded recent playlist successfully")
            } catch {
                Logger.error("Failed to fetch recent playlist: \(error)")
                await MainActor.run {
                    state = reducer.reduce(state, with: .setLoadingPlaylist(false))
                }
            }

            Logger.debug("Fetching recent songs")
            let recentSongs = RecentSongsManager.fetchRecentSongs()
            await MainActor.run {
                state = reducer.reduce(state, with: .setRecentSongs(recentSongs))
            }
            Logger.info("Loaded \(recentSongs.count) recent songs")
        }
    }
}
