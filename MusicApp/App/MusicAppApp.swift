//
//  MusicAppApp.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI
import UIKit
@main
struct MusicAppApp: App {
    @Environment(\.scenePhase) var scenePhase
    @State var appState: AppState = AppState()
    init() {
        PlaylistManager.provide(PlayViewModel())
        PlaylistManager.shared.setUpSubscrib()
    }
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewViewModel())
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            default:
                break
            }
        }
    }
}


// MARK: - TODO: tao man hinh mini notification
// tao constant cho may cai string
// tao icon cho app
// try to refactor code by using @EnvironmentObject than using singleton
// handle logic khi mo app khac ma app minh tat nhac chua su ly
// co y tuong convert sang da module giong voi app zig thu research va lam theo tren mot nhanh moi
// tao custom font cho project va su dung
// cover the logic when add new playlist with the same name has been exist in the core data
// need to make all the .sink of publisher is using weak self
// replace  the change state in the viewModel to dispatchQueue.main.async, need to review code hader
