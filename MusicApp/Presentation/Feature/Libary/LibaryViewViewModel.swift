//
//  LibaryViewHandler.swift
//  MusicApp
//
//  Created by Nhat on 6/15/23.
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
protocol LibaryViewViewModelProtocol: ObservableObject {
    var state: LibaryViewState { get }
    func send(intent: LibaryViewIntent)
    func isCompletedAddPlaylist() -> Binding<Bool>
    func isShowToastView() -> Binding<Bool>
    func isLastItem(item: Playlist) -> Bool
    func isLastSmartPlaylist(item: SmartPlaylist) -> Bool
}

final class LibaryViewViewModel: LibaryViewViewModelProtocol {
    // MARK: - PROPERTIES

    @Published private(set) var state: LibaryViewState
    private let reducer: any LibaryStateReducerProtocol
    private let fetchPlaylistaUseCase: FetchPlaylistUseCaseProtocol
    private let deletePlaylistUseCase: DeletetPlaylistUseCaseProtocol
    private let saveSmartPlaylistUseCase: SaveSmartPlaylistUseCaseProtocol?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        state: LibaryViewState = LibaryViewState(isLoading: false, playlist: []),
        reducer: any LibaryStateReducerProtocol = LibaryStateReducerImpl(),
        fetchPlaylistaUseCase: FetchPlaylistUseCaseProtocol = FetchPlaylistUseCase(),
        deletePlaylistUseCase: DeletetPlaylistUseCaseProtocol = DeletetPlaylistUseCase(),
        saveSmartPlaylistUseCase: SaveSmartPlaylistUseCaseProtocol? = nil
    ) {
        self.state = state
        self.reducer = reducer
        self.fetchPlaylistaUseCase = fetchPlaylistaUseCase
        self.deletePlaylistUseCase = deletePlaylistUseCase
        self.saveSmartPlaylistUseCase = saveSmartPlaylistUseCase
        Logger.debug("LibaryViewViewModel initialized")
        subscribeToPlaylistEvents()
    }

    private func subscribeToPlaylistEvents() {
        PlaylistEventCenter.shared.subject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .added, .deleted:
                    self?.loadPlaylists()
                case .updated:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Intent Handler
    func send(intent: LibaryViewIntent) {
        Logger.debug("LibaryViewViewModel.send() - Intent: \(intent)")

        switch intent {
        case .loadPlaylist:
            Logger.debug("Loading playlists...")
            loadPlaylists()
        case .deletePlaylist(let playlist):
            Logger.info("Deleting playlist: \(playlist.name)")
            deletePlaylist(playlist: playlist)
        case .loadSmartPlaylists:
            loadSmartPlaylists()
        case .deleteSmartPlaylist(let pl):
            deleteSmartPlaylist(pl)
        }
    }

    // MARK: - Private Methods
    private func deletePlaylist(playlist: Playlist) {
        Task {
            do {
                Logger.debug("Executing delete playlist operation for ID: \(playlist.id)")
                try await deletePlaylistUseCase.execute(by: playlist.id)
                await MainActor.run {
                    state = reducer.reduce(state, with: .removePlaylist(playlist))
                }
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
                state = reducer.reduce(state, with: .setLoading(true))
            }

            do {
                let playlists = try await fetchPlaylistaUseCase.executeGetAll(sortBy: .nameAscending)
                await MainActor.run {
                    state = reducer.reduce(state, with: .setPlaylists(playlists))
                }
                Logger.info("Loaded \(playlists.count) playlists successfully")
            } catch {
                await MainActor.run {
                    state = reducer.reduce(state, with: .setLoading(false))
                }
                Logger.error("Failed to load playlists: \(error)")
            }
        }
    }

    // MARK: - Bindings
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
            self.state = self.reducer.reduce(self.state, with: .setShowToast(newValue, message: self.state.toastViewMessage))
        }
    }

    func isLastItem(item: Playlist) -> Bool {
        return self.state.playlist.last == item
    }

    func isLastSmartPlaylist(item: SmartPlaylist) -> Bool {
        return self.state.smartPlaylists.last?.id == item.id
    }

    // MARK: - Smart Playlist
    private func loadSmartPlaylists() {
        guard let useCase = saveSmartPlaylistUseCase else { return }
        let playlists = (try? useCase.fetchAll()) ?? []
        state = reducer.reduce(state, with: .setSmartPlaylists(playlists))
    }

    private func deleteSmartPlaylist(_ playlist: SmartPlaylist) {
        try? saveSmartPlaylistUseCase?.delete(id: playlist.id)
        state = reducer.reduce(state, with: .removeSmartPlaylist(playlist))
    }
}
