//
//  TabReloadManager.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/11/25.
//

import Foundation

class TabReloadManager: ObservableObject {
    @Published var resetTab: Set<MainTab> = []
}
