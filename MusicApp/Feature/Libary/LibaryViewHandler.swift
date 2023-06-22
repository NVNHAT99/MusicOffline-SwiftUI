//
//  LibaryViewHandler.swift
//  MusicApp
//
//  Created by Nhat on 6/15/23.
//

import Foundation
import SwiftUI

final class LibaryViewHandler: ObservableObject {
    // MARK: - PROPERTIES
    let tabItems = [TabItem(image: "house", title: ""),
                    TabItem(image: "book", title: ""),
                    TabItem(image: "gearshape", title: ""),
    ]
    
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 150)),
                               GridItem(.adaptive(minimum: 150))]
    
    @Published private(set) var state: LibaryViewState
    
    init(state: LibaryViewState = LibaryViewState(isLoading: false, isPresnted: false)) {
        self.state = state
    }
    
    func send(intent: LibaryViewIntent) {
        switch intent {
        case .loadPlaylist:
            state.isLoading = true
        case .addNewPlayList:
            print("pending this feature")
        case .deletePlaylist:
            print("pending this feature")
        case .updateIsPresented(let newValue):
            state.isPresnted = newValue
        }
    }
    
}
