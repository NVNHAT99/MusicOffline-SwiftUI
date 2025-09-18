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
protocol LibaryViewViewModelProtocol: ObservableObject {
    var state: LibaryViewState { get }
    func send(intent: LibaryViewIntent)
    func isCompletedAddPlaylist() -> Binding<Bool>
    func isShowToastView() -> Binding<Bool>
    func isLastItem(item: Playlist) -> Bool
}

final class LibaryViewViewModel: LibaryViewViewModelProtocol {
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
        Logger.debug("LibaryViewViewModel initialized")
    }
    
    func send(intent: LibaryViewIntent) {
        Logger.debug("LibaryViewViewModel.send() - Intent: \(intent)")

        switch intent {
        case .loadPlaylist:
            Logger.debug("Loading playlists...")
            loadPlaylists()
        case .deletePlaylist(let playlist):
            Logger.info("Deleting playlist: \(playlist.name)")
            deletePlaylist(playlist: playlist)
        }
    }
    
    
    private func deletePlaylist(playlist: Playlist) {
        Task {
            do {
                Logger.debug("Executing delete playlist operation for ID: \(playlist.id)")
                try await deletePlaylistUseCase.execute(by: playlist.id)
                self.state.playlist = self.state.playlist.filter({ $0 != playlist})
                Logger.info("Playlist deleted successfully: \(playlist.name)")
            } catch {
                Logger.error("Failed to delete playlist \(playlist.name): \(error)")
            }
        }
    }
    
    private func loadPlaylists(isFromDeleted: Bool = false) {
        Task {
            Logger.debug("Loading playlists...")
            await MainActor.run {
                self.state.isLoading = true
            }

            do {
                let playlists = try await fetchPlaylistaUseCase.executeGetAll()
                await MainActor.run {
                    var newState = self.state
                    newState.isLoading = false
                    newState.playlist = playlists
                    self.state = newState
                }
                Logger.info("Loaded \(playlists.count) playlists successfully")
            } catch {
                await MainActor.run {
                    var newState = self.state
                    newState.isLoading = false
                    self.state = newState
                }
                Logger.error("Failed to load playlists: \(error)")
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
