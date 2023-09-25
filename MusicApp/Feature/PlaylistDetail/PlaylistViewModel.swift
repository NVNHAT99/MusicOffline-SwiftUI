//
//  PlaylistDetailsHandler.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
//

import Foundation
import CoreData
import SwiftUI

final class PlaylistViewModel: ObservableObject {
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
        default:
            break
        }
    }
    
    func playSong(urlStr: String) {
        if let index = state.playlist?.songsArray.firstIndex(of: urlStr) {
            PlaylistManager.shared.updatePlaylist(playlist: state.playlist, currentIndex: index)
            PlaylistManager.shared.playSong(urlString: urlStr)
        }
    }
    
    func deleteSongAt(index: Int) {
        guard let playlist = state.playlist, index < playlist.songsArray.count else {
            return
        }
        var updatedSongsArray = playlist.songsArray
        updatedSongsArray.remove(at: index)
        let context = PersistenceController.shared.viewContext
        context.performAndWait {
            playlist.songsArray = updatedSongsArray
            do {
                self.state.playlist = playlist
                try context.save()
            } catch let error as NSError {
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
}

struct SongIdentifiable: Identifiable {
    let id = UUID()
    let songUrlStr: String
    let index: Int
}
