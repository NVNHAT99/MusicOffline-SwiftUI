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
    let tabItems = [TabItem(image: "house", title: ""),
                    TabItem(image: "book", title: ""),
                    TabItem(image: "gearshape", title: ""),
    ]
    
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 150)),
                               GridItem(.adaptive(minimum: 150))]
    
    @Published private(set) var state: LibaryViewState
    
    init(state: LibaryViewState = LibaryViewState(isLoading: false,
                                                  isPresnted: false,
                                                  playlist: [])) {
        self.state = state
    }
    
    func send(intent: LibaryViewIntent) {
        switch intent {
        case .loadPlaylist:
            loadPlaylists()
        case .addNewPlayList(let name):
            addNewPlaylist(name)
        case .deletePlaylist(let playlist):
            deletePlaylist(playlist: playlist)
        case .updateIsPresented(let newValue):
            state.isPresnted = newValue
        }
    }
    
    private func addNewPlaylist(_ name: String) {
        let context = PersistenceController.shared.viewContext
        let newPlaylist = Playlist(context: context)
        newPlaylist.name = name
        newPlaylist.id = UUID()
        PersistenceController.shared.saveContext()
        loadPlaylists()
    }
    
    private func deletePlaylist(playlist: Playlist) {
        let context = PersistenceController.shared.viewContext
        context.performAndWait {
            context.delete(playlist)
            PersistenceController.shared.saveContext()
            loadPlaylists()
            PlaylistManager.shared.updateAffterDeletePlaylist(playlist: playlist)
        }
    }
    
    private func loadPlaylists() {
        state.isLoading = true
        let context = PersistenceController.shared.viewContext
        let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
        
        do {
            let playlists = try context.fetch(fetchRequest)
            state.playlist = playlists
        } catch {
            state.playlist = []
            state.isLoading = false
            print("Error fetching playlists: \(error)")
        }
        
    }
    // this code cant not using for sheet modfier
    // because that make change value for the state and that make the view rerender
    // this could be using for binding value for the other view
    func isPresented() -> Binding<Bool> {
        return Binding<Bool>(
            get: { self.state.isPresnted },
            set: { _ in
            }
        )
    }
}
