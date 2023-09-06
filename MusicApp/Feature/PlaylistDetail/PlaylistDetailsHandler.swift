//
//  PlaylistDetailsHandler.swift
//  MusicApp
//
//  Created by Nhat on 8/8/23.
//

import Foundation
final class PlaylistDetailsHandler: ObservableObject {
    // MARK: - PROPERTIES
    
    @Published private(set) var state: PlaylistDetailsState
    
    init(state: PlaylistDetailsState = PlaylistDetailsState(isShowAddNewSong: false)) {
        self.state = state
    }
    
    func send(intent: PlaylistDetailIntent) {
        switch intent {
        case .showAddNewSong(let newValue):
            state.isShowAddNewSong = newValue
        default:
            break
        }
    }
}
