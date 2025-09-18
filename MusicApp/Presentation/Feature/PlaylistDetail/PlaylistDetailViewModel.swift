//
//  PlaylistDetailsHandler.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
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
    // MARK: - PROPERTIES
    private let fetchSongUseCase: FetchSongUseCaseProtocol
    private let fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol
    @Published private(set) var state: PlaylistDetailState
    private var playlist: Playlist?
    
    init(playlist: Playlist?,
         state: PlaylistDetailState = .init(),
         fetchSongUseCase: FetchSongUseCaseProtocol = FetchSongUseCase(),
         fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol = FetchPlaylistUseCase()) {
        self.playlist = playlist
        self.state = state
        self.fetchSongUseCase = fetchSongUseCase
        self.fetchPlaylistUseCase = fetchPlaylistUseCase
        Logger.debug("PlaylistDetailViewModel initialized for playlist: \(playlist?.name ?? "Unknown")")
    }
    
    func send(_ intent: PlaylistDetailIntent) {
        Logger.debug("PlaylistDetailViewModel.send() - Intent: \(intent)")

        switch intent {
        case .playSongAt(let song):
            Logger.info("Playing song: \(song.title)")
            playSong(at: song)
        case .deleteSong(let index):
            Logger.info("Deleting song at index: \(index)")
            deleteSongAt(index: index)
        case .loadPlaylist:
            Logger.debug("Loading playlist data")
            self.loadPlaylist()
        default:
            Logger.warning("Unhandled intent: \(intent)")
            break
        }
    }
    
    private func loadPlaylist() {
        Task {
            Logger.debug("Loading playlist data")

            await MainActor.run {
                self.state.isLoading = true
            }

            do {
                let playlist = try await fetchPlaylistUseCase.execute(with: self.playlist?.id.uuidString ?? String.empty)
                let songs = try await fetchSongUseCase.execute(playlist.songIDs).map({ SongMapper.mapToSongModel($0) })
                self.playlist = playlist
                await MainActor.run {
                    var newState = state
                    newState.isLoading = false
                    newState.songs = songs
                    self.state = newState
                }
                Logger.info("Loaded playlist with \(songs.count) songs")
            } catch {
                Logger.error("Failed to load playlist: \(error)")
                await MainActor.run {
                    var newState = state
                    newState.isLoading = false
                    self.state = newState
                }
            }
        }
    }
    
    private func playSong(at song: SongModel) {
        guard let playlistId = self.playlist?.id else {
            Logger.warning("Cannot play song - no playlist ID available")
            return
        }

        Logger.debug("Playing song: \(song.title) from playlist: \(playlistId)")

        Task {
            await PlayerManager.shared.play(playlistId, songs: state.songs, songPlay: song)
        }
    }
    
    private func deleteSongAt(index: Int) {
//        guard let playlist = state.playlist, index < playlist.songsArray.count else {
//            return
//        }
//        var updatedSongsArray = playlist.songsArray
//        updatedSongsArray.remove(at: index)
//        let context = PersistenceController.shared.viewContext
//        context.performAndWait {
//            playlist.songsArray = updatedSongsArray
//            do {
//                var stateCopy = self.state
//                stateCopy.playlist = playlist
//                stateCopy.isShowToastView = true
//                stateCopy.toastViewMessage = "Deleted song successfuly."
//                DispatchQueue.main.async {
//                    withAnimation { [weak self] in
//                        guard let self = self else {
//                            return
//                        }
//                        
//                        self.state = stateCopy
//                    }
//                }
//                try context.save()
//            } catch let error as NSError {
//                var stateCopy = self.state
//                stateCopy.isShowToastView = true
//                stateCopy.toastViewMessage = "Deleted song failed."
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else {
//                        return
//                    }
//                    
//                    withAnimation {
//                        self.state = stateCopy
//                    }
//                }
//                print("Could not save. \(error), \(error.userInfo)")
//                
//            }
//        }
    }
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state.isShowToastView = newValue
        }

    }
    
    func getTitle() -> String {
        return self.playlist?.name ?? String.empty
    }
    
    func getSongIds() -> [UUID] {
        return playlist?.songIDs ?? []
    }
    
    func getPlaylistId() -> UUID {
        return playlist?.id ?? UUID()
    }
    
    var bindEditCompleted: Binding<Bool> {
        .init(get: {
            return false
        }, set: { newValue in
            if newValue {
                self.loadPlaylist()
            }
        })
    }
}
