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
    private var cancellables = Set<AnyCancellable>()
    
    init(fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol,
         playerManager: any PlayerManagerProtocol,
         state: HomeViewState = .init()) {
        self.state = state
        self.playerManager = playerManager
        self.fetchPlaylistUseCase = fetchPlaylistUseCase
        
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
        switch intent {
        case .fetchData:
            self.fetchSongs()
        case .play(let recentSongItem):
            Task {
                if let playlistId = UUID(uuidString: recentSongItem.playlistId ?? "") {
                    await playerManager.play( playlistId, songPlay: recentSongItem.song)
                }
            }
        }
    }
    
    private func fetchSongs() {
        Task {
            
            await MainActor.run {
                var newState = self.state
                newState.isLoadingPlaylist = true
                newState.isLoadingRecentSongs = true
                self.state = newState
            }
            
            Task {
                let playlistRecentID = RecentSongsManager.fetchRecentPlaylists()
                let recentPlaylist = try await fetchPlaylistUseCase.excute(with: playlistRecentID)
                let mockData = try await fetchPlaylistUseCase.executeGetAll()
                print("da vao day: \(playlistRecentID)")
                print("da vao day: \(mockData)")
                await MainActor.run {
                    var newState = self.state
                    newState.isLoadingPlaylist = false
                    newState.playlists = recentPlaylist
                    self.state = newState
                }
            }
            
            Task {
                let recentSongs = RecentSongsManager.fetchRecentSongs()
                await MainActor.run {
                    var newState = self.state
                    newState.isLoadingRecentSongs = false
                    newState.recentSongs = recentSongs
                    self.state = newState
                }
            }
            
        }
    }
}
