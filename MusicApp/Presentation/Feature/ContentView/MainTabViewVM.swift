//
//  MainTabViewVM.swift
//  MusicApp
//
//  Created by Nhat on 5/25/23.
//

import Foundation
import Combine

final class MainTabViewVM: ObservableObject {
    let tabItems: [TabItem<MainTab>] = [TabItem(icon: "house", selectedIcon: "house.fill", title: "Home", color: .white, tag: .home),
                                        TabItem(icon: "books.vertical", selectedIcon: "books.vertical.fill", title: "Library", color: .white, tag: .playlist),
                                        TabItem(icon: "gearshape", selectedIcon: "gearshape.fill", title: "Setting", color: .white, tag: .settings)
    ]
    
    @Published var isShowNowPlaying: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let playerManager: any PlayerManagerProtocol
    
    init(playerManager: any PlayerManagerProtocol = PlayerManager.shared) {
        self.playerManager = playerManager
        
        self.playerManager.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                self.isShowNowPlaying = state.currentSong != nil
            }
            .store(in: &cancellables)
    }
}
