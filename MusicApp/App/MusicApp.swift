//
//  MusicApp.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI

@main
struct MusicApp: App {
    @StateObject var mainTabarViewVM: MainTabViewVM = MainTabViewVM()
    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: mainTabarViewVM)
        }
    }
}
