//
//  PlaylistDetailsHandler.swift
//  MusicApp
//

import Foundation
import CoreData
import SwiftUI

@MainActor
protocol PlaylistDetailViewModelProtocol: ObservableObject {
    var state: PlaylistDetailState { get }
    func send(_ intent: PlaylistDetailIntent)
    func isShowToastView() -> Binding<Bool>
    func getTitle() -> String
    func getSongIds() -> [UUID]
    func getPlaylistId() -> UUID
    var bindEditCompleted: Binding<Bool> { get }
}

final class PlaylistDetailViewModel: PlaylistDetailViewModelProtocol {
    // MARK: - Properties
    private let fetchSongUseCase: FetchSongUseCaseProtocol
    private let fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol
    private let updatePlaylistUseCase: UpdatePlaylistUseCaseProtocol
    private let reorderSongsUseCase: ReorderPlaylistSongsUseCaseProtocol
    @Published private(set) var state: PlaylistDetailState
    private let reducer: any PlaylistDetailStateReducerProtocol
    private var playlist: Playlist?

    // MARK: - Init
    init(
        playlist: Playlist?,
        state: PlaylistDetailState = .init(),
        reducer: any PlaylistDetailStateReducerProtocol = PlaylistDetailStateReducerImpl(),
        fetchSongUseCase: FetchSongUseCaseProtocol = FetchSongUseCase(),
        fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol = FetchPlaylistUseCase(),
        updatePlaylistUseCase: UpdatePlaylistUseCaseProtocol = UpdatePlaylistUseCase(),
        reorderSongsUseCase: ReorderPlaylistSongsUseCaseProtocol = ReorderPlaylistSongsUseCase()
    ) {
        self.playlist = playlist
        self.state = state
        self.reducer = reducer
        self.fetchSongUseCase = fetchSongUseCase
        self.fetchPlaylistUseCase = fetchPlaylistUseCase
        self.updatePlaylistUseCase = updatePlaylistUseCase
        self.reorderSongsUseCase = reorderSongsUseCase
        Logger.debug("PlaylistDetailViewModel initialized for playlist: \(playlist?.name ?? "Unknown")")
    }

    // MARK: - Intent Handler
    func send(_ intent: PlaylistDetailIntent) {
        Logger.debug("PlaylistDetailViewModel.send() - Intent: \(intent)")

        switch intent {
        case .playSongAt(let song):
            playSong(at: song)
        case .deleteSong(let index):
            deleteSongAt(index: index)
        case .loadPlaylist:
            loadPlaylist()
        case .reorderSongs(let from, let to):
            reorderSongs(from: from, to: to)
        case .toggleEditMode:
            state = reducer.reduce(state, with: .setEditMode(!state.isEditMode))
        case .toggleSongSelection(let id):
            state = reducer.reduce(state, with: .toggleSongSelection(id))
        case .bulkDelete:
            bulkDelete()
        case .setSortOption(let option):
            state = reducer.reduce(state, with: .setSortOption(option))
        }
    }

    // MARK: - Private Methods
    private func loadPlaylist() {
        Task {
            await MainActor.run {
                state = reducer.reduce(state, with: .setLoading(true))
            }

            do {
                let playlist = try await fetchPlaylistUseCase.execute(with: self.playlist?.id.uuidString ?? String.empty)
                // Preserve songIDs order from playlist entity
                let allSongs = try await fetchSongUseCase.execute(playlist.songIDs)
                let orderedSongs = playlist.songIDs.compactMap { id in
                    allSongs.first(where: { $0.id == id })
                }.map { SongMapper.mapToSongModel($0) }
                self.playlist = playlist
                await MainActor.run {
                    state = reducer.reduce(state, with: .setSongs(orderedSongs))
                }
                Logger.info("Loaded playlist with \(orderedSongs.count) songs")
            } catch {
                Logger.error("Failed to load playlist: \(error)")
                await MainActor.run {
                    state = reducer.reduce(state, with: .setLoading(false))
                }
            }
        }
    }

    private func playSong(at song: SongModel) {
        guard let playlistId = self.playlist?.id else { return }
        Task {
            await PlayerManager.shared.play(playlistId, songs: state.songs, songPlay: song)
        }
    }

    private func deleteSongAt(index: Int) {
        guard let playlistId = playlist?.id else { return }
        guard index >= 0, index < state.songs.count else { return }

        var updatedSongs = state.songs
        updatedSongs.remove(at: index)
        let updatedIDs = updatedSongs.map { $0.id }

        Task {
            do {
                try await updatePlaylistUseCase.execute(from: playlistId, with: updatedIDs)
                await MainActor.run {
                    state = reducer.reduce(state, with: .setSongs(updatedSongs))
                }
            } catch {
                Logger.error("Failed to delete song: \(error)")
                await MainActor.run {
                    state = reducer.reduce(state, with: .setShowToast(true, message: "Failed to remove song"))
                }
            }
        }
    }

    private func reorderSongs(from offsets: IndexSet, to destination: Int) {
        guard let playlistId = playlist?.id else { return }

        var reordered = state.songs
        reordered.move(fromOffsets: offsets, toOffset: destination)
        let orderedIDs = reordered.map { $0.id }

        // Optimistic update
        state = reducer.reduce(state, with: .setSongs(reordered))

        Task {
            do {
                try await reorderSongsUseCase.execute(playlistId: playlistId, orderedSongIDs: orderedIDs)
            } catch {
                Logger.error("Failed to reorder songs: \(error)")
                // Revert on failure
                await MainActor.run { self.loadPlaylist() }
            }
        }
    }

    private func bulkDelete() {
        guard let playlistId = playlist?.id, !state.selectedSongIDs.isEmpty else { return }

        let selectedIDs = state.selectedSongIDs
        let updatedSongs = state.songs.filter { !selectedIDs.contains($0.id) }
        let updatedIDs = updatedSongs.map { $0.id }

        Task {
            do {
                try await updatePlaylistUseCase.execute(from: playlistId, with: updatedIDs)
                await MainActor.run {
                    state = reducer.reduce(state, with: .setSongs(updatedSongs))
                    state = reducer.reduce(state, with: .clearSelection)
                    state = reducer.reduce(state, with: .setEditMode(false))
                }
            } catch {
                Logger.error("Failed to bulk delete: \(error)")
                await MainActor.run {
                    state = reducer.reduce(state, with: .setShowToast(true, message: "Failed to delete songs"))
                }
            }
        }
    }

    // MARK: - Bindings
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state = self.reducer.reduce(self.state, with: .setShowToast(newValue, message: self.state.toastViewMessage))
        }
    }

    func getTitle() -> String { playlist?.name ?? String.empty }
    func getSongIds() -> [UUID] { playlist?.songIDs ?? [] }
    func getPlaylistId() -> UUID { playlist?.id ?? UUID() }

    var bindEditCompleted: Binding<Bool> {
        .init(get: { false }, set: { [weak self] newValue in
            if newValue { self?.send(.loadPlaylist) }
        })
    }
}
