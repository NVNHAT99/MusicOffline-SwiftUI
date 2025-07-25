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
        case .showAddNewPlaylist(let value):
            showAddNewPlaylistView(isShow: value)
        }
    }
    
    private func showAddNewPlaylistView(isShow: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            withAnimation {
                self.state.isShowAddPlaylist = isShow
            }
        }
    }
    
    private func addNewPlaylist(_ name: String) {
        // MARK: - TODO move this code to add new libary view, make that view with full MVI partern
        let context = PersistenceController.shared.viewContext
        let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        do {
            let count = try context.count(for: fetchRequest)
            if count > 0 {
              print("Playlist with name \(name) already exists")
              return
            }
          } catch {
            print(error)
          }
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
            loadPlaylists(isFromDeleted: true)
            PlaylistManager.shared.updateAffterDeletePlaylist(playlist: playlist)
        }
    }
    
    private func loadPlaylists(isFromDeleted: Bool = false) {
        state.isLoading = true
        let context = PersistenceController.shared.viewContext
        let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
        
        do {
            let playlists = try context.fetch(fetchRequest)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                withAnimation {
                    var stateCopy = self.state
                    stateCopy.playlist = playlists
                    if isFromDeleted {
                        stateCopy.isShowToastView = true
                        stateCopy.toastViewMessage = "Delete playlist successfully"
                    }
                    self.state = stateCopy
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                withAnimation {
                    var stateCopy = self.state
                    stateCopy.playlist = []
                    self.state = stateCopy
                }
            }
            print("Error fetching playlists: \(error)")
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
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state.isShowToastView = newValue
        }

    }
}
