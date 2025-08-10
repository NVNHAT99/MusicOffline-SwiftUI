//
//  LibaryViewHandler.swift
//  MusicApp
//
//  Created by Nhat on 6/15/23.
//

import Foundation
import SwiftUI
import CoreData

final class LibaryViewViewModel: ObservableObject {
    // MARK: - PROPERTIES
    
    @Published private(set) var state: LibaryViewState
    private let fetchPlaylistaUseCase: FetchPlaylistUseCaseProtocol
    
    init(state: LibaryViewState = LibaryViewState(isLoading: false,
                                                  isPresnted: false,
                                                  playlist: []),
         fetchPlaylistaUseCase: FetchPlaylistUseCaseProtocol = FetchPlaylistUseCase()) {
        self.state = state
        self.fetchPlaylistaUseCase = fetchPlaylistaUseCase
    }
    
    func send(intent: LibaryViewIntent) {
        switch intent {
        case .loadPlaylist:
            loadPlaylists()
        case .deletePlaylist(let playlist):
            deletePlaylist(playlist: playlist)
        case .updateIsPresented(let newValue):
            state.isPresnted = newValue
        }
    }
    
    
    private func deletePlaylist(playlist: Playlist) {
//        let context = PersistenceController.shared.viewContext
//        context.performAndWait {
//            context.delete(playlist)
//            PersistenceController.shared.saveContext()
//            loadPlaylists(isFromDeleted: true)
//            PlaylistManager.shared.updateAffterDeletePlaylist(playlist: playlist)
//        }
    }
    
    private func loadPlaylists(isFromDeleted: Bool = false) {
        self.state.isLoading = true
        Task {
            let playlist = try await fetchPlaylistaUseCase.executeGetAll()
            
            await MainActor.run {
                var newSate = self.state
                newSate.isLoading = false
                newSate.playlist = playlist
                self.state = newSate
            }
        }
    }
    // this code cant not using for sheet modfier
    // because that make change value for the state and that make the view rerender
    // this could be using for binding value for the other view no presented
    func isPresented() -> Binding<Bool> {
        return Binding<Bool>(
            get: { self.state.isPresnted },
            set: { _ in
            }
        )
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
}
