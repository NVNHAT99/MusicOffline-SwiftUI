//
//  HomeViewModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/28/25.
//

import SwiftUI

final class HomeViewModel: ObservableObject {
    private let fetchHomeDataUseCase: FetchHomeDataUseCaseProtocol
    @Published var state: HomeViewState
    
    
    init(fetchHomeDataUseCase: FetchHomeDataUseCaseProtocol = FetchHomeDataUseCase(),
         state: HomeViewState = .init()) {
        self.fetchHomeDataUseCase = fetchHomeDataUseCase
        self.state = state
    }
    
    func send(_ intent: HomeViewIntent) {
        switch intent {
        case .fetchSongs:
            self.fetchSongs()
        }
    }
    
    private func fetchSongs() {
        state.isLoading = true
        Task {
            do {
                let result = try await fetchHomeDataUseCase.execute()
                await MainActor.run {
                    var newState = self.state
                    newState.albums = result.albums
                    newState.playlists = result.playlists
                    newState.recentSongs = result.recentSongs
                    newState.isLoading = false
                    self.state = newState
                }
            } catch {
                print("da xuat hien error")
            }
        }
    }
}
