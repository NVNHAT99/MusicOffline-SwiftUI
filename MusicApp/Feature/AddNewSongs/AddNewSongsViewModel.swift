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
    
    init(state: AddNewSongState = .init()) {
        self.state = state
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
    
    func addToPlaylist(onCompleted: (Result<Bool, Error>) -> Void) {
        let context = PersistenceController.shared.viewContext
        context.performAndWait {
            var songArray: [String] =  self.state.playlist?.songsArray ?? []
            for item in state.arrayMP3File {
                if item.isSelected, !(songArray.contains(item.fileURL.absoluteString)) {
                    songArray.append(item.fileURL.absoluteString)
                }
            }

            do {
                DispatchQueue.main.async {
                    self.state.playlist?.songsArray = songArray
                }
                try context.save()
                onCompleted(.success(true))
            } catch {
                onCompleted(.failure(error))
            }
        }
    }
    
    func toggleSelected(at indext: Int) {
        DispatchQueue.main.async {
            self.state.arrayMP3File[indext].isSelected.toggle()
            if self.state.arrayMP3File[indext].isSelected {
                self.state.selectedCount += 1
            } else {
                self.state.selectedCount -= 1
            }
        }
    }
}
