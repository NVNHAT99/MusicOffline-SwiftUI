//
//  AddNewSongsHandler.swift
//  MusicApp
//
//  Created by Nhat on 9/21/23.
//

import Foundation

final class EditPlaylistViewModel: ObservableObject {
    
    // MARK: - PROPERTIES WRAPER
    @Published private(set) var state: EditPlaylistState
    private let updatePlaylistUseCase: UpdatePlaylistUseCaseProtocol
    private let fetchSongUseCase: FetchSongUseCaseProtocol
    private var currentSongs: [SelectedSong] = []
    private let playlistID: UUID
    init(currenSongIDs: [UUID],
         playlistID: UUID,
         updatePlaylistUseCase: UpdatePlaylistUseCaseProtocol = UpdatePlaylistUseCase(),
         fetchSongUseCase: FetchSongUseCaseProtocol = FetchSongUseCase()) {
        self.state = .init(songIDs: currenSongIDs)
        self.updatePlaylistUseCase = updatePlaylistUseCase
        self.fetchSongUseCase = fetchSongUseCase
        self.playlistID = playlistID
    }
    
    func send(intent: EditPlaylistIntent) {
        switch intent {
        case .loadListSong:
            loadListSong()
        case .toggleSelectedAt(let index):
            toggleSelected(at: index)
        case .savePlaylist:
            savePlaylist()
        }
    }
    
    private func loadListSong() {
        Task {
            await MainActor.run {
                self.state.isLoading = true
            }
            let songs = try await self.fetchSongUseCase.executeGetAll().map({ SongMapper.mapToSelectedSong($0, isSelected: self.state.songIDs.contains($0.id))})
            self.currentSongs = songs
            await MainActor.run {
                var newState = self.state
                newState.isLoading = false
                newState.allSongs = songs
                self.state = newState
            }
        }
    }
    
    private func savePlaylist() {
        Task {
            await MainActor.run {
                self.state.isEnableSaveButton = false
            }
            do {
                let selectedSongUUIDs = self.state.allSongs.filter { $0.isSelected }.map { $0.songUUID }
                try await updatePlaylistUseCase.execute(from: playlistID,
                                                        with: selectedSongUUIDs)
                await MainActor.run {
                    self.state.isSavePlaylistSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.state.isEnableSaveButton = true
                }
                print("save playlist loi")
            }
        }
    }
    
    
    private func toggleSelected(at indext: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.state.allSongs[indext].isSelected.toggle()
            if self.state.allSongs != currentSongs {
                self.state.isEnableSaveButton = true
            } else {
                self.state.isEnableSaveButton = false
            }
        }
    }
}

enum FakeError: Error {
    case fake
}
