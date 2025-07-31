//
//  MainTabViewVM.swift
//  MusicApp
//
//  Created by Nhat on 5/25/23.
//

import Foundation

final class MainTabViewVM: ObservableObject {
    let tabItems: [TabItem<MainTab>] = [TabItem(icon: "house", selectedIcon: "house.fill", title: "Home", color: .blue, tag: .home),
                                        TabItem(icon: "books.vertical", selectedIcon: "books.vertical.fill", title: "Library", color: .green, tag: .playlist),
                                        TabItem(icon: "camera", selectedIcon: "camera.fill", title: "Camera", color: .orange, tag: .play),
                                        TabItem(icon: "heart", selectedIcon: "heart.fill", title: "Favorites", color: .red, tag: .loadSong),
                                        TabItem(icon: "person", selectedIcon: "person.fill", title: "Profile", color: .purple, tag: .settings)
    ]
}
