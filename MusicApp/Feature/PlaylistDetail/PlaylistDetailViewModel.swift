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
    
    @Published private(set) var state: PlaylistDetailsState
    
    init(state: PlaylistDetailsState = PlaylistDetailsState()) {
        self.state = state
    }
    
    func send(intent: PlaylistDetailIntent) {
        switch intent {
        case .playSongAt(let urlStr):
            playSong(urlStr: urlStr)
        case .deleteSong(let index):
            deleteSongAt(index: index)
        case .updatePlaylist(let playlist):
            state.playlist = playlist
        case .handleAddNewSongs(let result):
            handleAddNewSongs(result: result)
        default:
            break
        }
    }
    
    private func handleAddNewSongs(result: Result<Bool, Error>) {
        var stateCopy = self.state
        switch result {
        case .success:
            stateCopy.isShowToastView = true
            stateCopy.toastViewMessage = "Add new Songs Successfuly."
        case .failure:
            stateCopy.isShowToastView = true
            stateCopy.toastViewMessage = "Add new Songs failed."
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            withAnimation {
                self.state = stateCopy
            }
        }
    }
    
    private func playSong(urlStr: String) {
        if let index = state.playlist?.songsArray.firstIndex(of: urlStr) {
            PlaylistManager.shared.updatePlaylist(playlist: state.playlist, currentIndex: index)
            PlaylistManager.shared.playSong(urlString: urlStr)
        }
    }
    
    private func deleteSongAt(index: Int) {
        guard let playlist = state.playlist, index < playlist.songsArray.count else {
            return
        }
        var updatedSongsArray = playlist.songsArray
        updatedSongsArray.remove(at: index)
        let context = PersistenceController.shared.viewContext
        context.performAndWait {
            playlist.songsArray = updatedSongsArray
            do {
                var stateCopy = self.state
                stateCopy.playlist = playlist
                stateCopy.isShowToastView = true
                stateCopy.toastViewMessage = "Deleted song successfuly."
                DispatchQueue.main.async {
                    withAnimation { [weak self] in
                        guard let self = self else {
                            return
                        }
                        
                        self.state = stateCopy
                    }
                }
                try context.save()
            } catch let error as NSError {
                var stateCopy = self.state
                stateCopy.isShowToastView = true
                stateCopy.toastViewMessage = "Deleted song failed."
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    withAnimation {
                        self.state = stateCopy
                    }
                }
                print("Could not save. \(error), \(error.userInfo)")
                
            }
        }
    }
    
    func playlistBinding() -> Binding<Playlist?> {
        return Binding<Playlist?>(
            get: {
                self.state.playlist
            },
            set: { newPlaylist in
                self.state.playlist = newPlaylist
            }
        )
    }
    
    var songsForUI: [SongIdentifiable] {
        return state.playlist?.songsArray.enumerated().map { index, song in
                SongIdentifiable(songUrlStr: song, index: index)
        } ?? []
    }
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state.isShowToastView = newValue
        }

    }
}

struct SongIdentifiable: Identifiable {
    let id = UUID()
    let songUrlStr: String
    let index: Int
}
