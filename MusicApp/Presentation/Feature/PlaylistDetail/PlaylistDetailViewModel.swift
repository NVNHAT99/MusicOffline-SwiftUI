//
//  PlaylistDetailsHandler.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
//

import Foundation
import CoreData
import SwiftUI

final class PlaylistDetailViewModel: ObservableObject {
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
    }
    
    func send(_ intent: PlaylistDetailIntent) {
        switch intent {
        case .playSongAt(let song):
            playSong(at: song)
        case .deleteSong(let index):
            deleteSongAt(index: index)
        case .loadPlaylist:
            self.loadPlaylist()
        default:
            break
        }
    }
    
    private func loadPlaylist() {
        Task {
            await MainActor.run {
                self.state.isLoading = true
            }
            let playlist = try await fetchPlaylistUseCase.execute(with: self.playlist?.id.uuidString ?? String.empty)
            let songs = try await fetchSongUseCase.execute(playlist.songIDs).map({ SongMapper.mapToSongModel($0) })
            self.playlist = playlist
            await MainActor.run {
                var newState = state
                newState.isLoading = false
                newState.songs = songs
                self.state = newState
            }
        }
    }
    
    private func playSong(at song: SongModel) {
        guard let playlistId = self.playlist?.id else {
            return
        }
        
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
