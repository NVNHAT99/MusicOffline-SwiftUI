//
//  LibaryViewHandler.swift
//  MusicApp
//
//  Created by Nhat on 6/15/23.
//

import Foundation
import SwiftUI
import CoreData

@MainActor
final class LibaryViewViewModel: ObservableObject {
    // MARK: - PROPERTIES
    
    @Published private(set) var state: LibaryViewState
    private let fetchPlaylistaUseCase: FetchPlaylistUseCaseProtocol
    private let deletePlaylistUseCase: DeletetPlaylistUseCaseProtocol
    
    init(state: LibaryViewState = LibaryViewState(isLoading: false,
                                                  playlist: []),
         fetchPlaylistaUseCase: FetchPlaylistUseCaseProtocol = FetchPlaylistUseCase(),
         deletePlaylistUseCase: DeletetPlaylistUseCaseProtocol = DeletetPlaylistUseCase()) {
        self.state = state
        self.fetchPlaylistaUseCase = fetchPlaylistaUseCase
        self.deletePlaylistUseCase = deletePlaylistUseCase
    }
    
    func send(intent: LibaryViewIntent) {
        switch intent {
        case .loadPlaylist:
            loadPlaylists()
        case .deletePlaylist(let playlist):
            deletePlaylist(playlist: playlist)
        }
    }
    
    
    private func deletePlaylist(playlist: Playlist) {
        Task {
            try await deletePlaylistUseCase.execute(by: playlist.id)
            self.state.playlist = self.state.playlist.filter({ $0 != playlist})
        }
    }
    
    private func loadPlaylists(isFromDeleted: Bool = false) {
        Task {
            await MainActor.run {
                self.state.isLoading = true
            }
            let playlist = try await fetchPlaylistaUseCase.executeGetAll()
            await MainActor.run {
                var newSate = self.state
                newSate.isLoading = false
                newSate.playlist = playlist
                self.state = newSate
            }
        }
    }
    
    func isCompletedAddPlaylist() -> Binding<Bool> {
        return Binding<Bool>(
            get: { false },
            set: { _ in self.send(intent: .loadPlaylist) }
        )
    }
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state.isShowToastView = newValue
        }
    }
    
    func isLastItem(item: Playlist) -> Bool {
        return self.state.playlist.last == item
    }
}
