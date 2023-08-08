//
//  LibaryViewHandler.swift
//  MusicApp
//
//  Created by Nhat on 6/15/23.
//

import Foundation
import SwiftUI
import CoreData

final class LibaryViewHandler: ObservableObject {
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
        case .deletePlaylist:
            print("pending this feature")
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
    
    func loadPlaylists() {
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
}
