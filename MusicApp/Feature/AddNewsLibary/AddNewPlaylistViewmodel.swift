//
//  AddNewlibaryViewmodel.swift
//  MusicApp
//
//  Created by Nhat on 10/7/23.
//

import Foundation
import CoreData
import SwiftUI

final class AddNewPlaylistViewmodel: ObservableObject {
    // MARK: - properties
    @Published private(set) var state: AddNewPlaylistState
    init(state: AddNewPlaylistState = .init()) {
        self.state = state
    }
    
    func send(intent: AddNewPlaylistIntent) {
        switch intent {
        case .addNewLibary(let onDismis):
            addNewPlaylist(onDismis: onDismis)
        }
    }
    
    private func addNewPlaylist(onDismis: () -> Void) {
        let context = PersistenceController.shared.viewContext
        let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", state.name)
        do {
            let count = try context.count(for: fetchRequest)
            if count > 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    var stateCopy = self.state
                    stateCopy.isShowToastView = true
                    stateCopy.toastViewMessage = "Add new playlist failed.Please change the name of playlist"
                }
              return
            }
          } catch {
            print(error)
          }
        let newPlaylist = Playlist(context: context)
        newPlaylist.name = state.name
        newPlaylist.id = UUID()
        PersistenceController.shared.saveContext()
        onDismis()
    }
    
    func bindingName() -> Binding<String> {
        return .init { [weak self] in
            guard let self = self else { return String.empty}
            return self.state.name
        } set: { [weak self] newValue in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.state.name = newValue
            }
        }
    }
    
    func bindingHeightOfKeyBoard() -> Binding<CGFloat> {
        return .init { [weak self] in
            guard let self = self else { return 0}
            return self.state.heightOfKeyboard
        } set: { [weak self] newValue in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.state.heightOfKeyboard = newValue
            }
        }
    }
}
