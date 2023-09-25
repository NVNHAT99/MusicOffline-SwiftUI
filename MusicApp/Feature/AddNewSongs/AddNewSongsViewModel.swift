//
//  AddNewSongsHandler.swift
//  MusicApp
//
//  Created by Nhat on 9/21/23.
//

import Foundation

final class AddNewSongsViewModel: ObservableObject {
    // MARK: - PROPERTIES WRAPER
    @Published private(set) var state: AddNewSongState
    
    let playlist: Playlist?
    
    init(state: AddNewSongState = .init(), playlist: Playlist?) {
        self.state = state
        self.playlist = playlist
    }
    
    func send(intent: AddNewSongsIntent) {
        switch intent {
        case .loadListSong:
            loadListSong()
        case .toggleSelectedAt(let index):
            toggleSelected(at: index)
        case .addToPlaylist(let onCompleted):
            addToPlaylist(onCompleted: onCompleted)
        default:
            break
        }
    }
    
    func loadListSong() {
        state.arrayMP3File = DocumentFileManager.shared.loadMP3File()
    }
    
    func addToPlaylist(onCompleted: () -> Void) {
        let context = PersistenceController.shared.viewContext
        context.performAndWait {
            var songArray: [String] = playlist?.songsArray ?? []
            for item in state.arrayMP3File {
                if item.isSelected, !(songArray.contains(item.fileURL.absoluteString)) {
                    songArray.append(item.fileURL.absoluteString)
                }
            }

            do {
                playlist?.songsArray = songArray
                try context.save()
                onCompleted()
            } catch {
                print(error)
            }
        }
    }
    
    func toggleSelected(at indext: Int) {
        state.arrayMP3File[indext].isSelected.toggle()
        if state.arrayMP3File[indext].isSelected {
            state.selectedCount += 1
        } else {
            state.selectedCount -= 1
        }
    }
}
