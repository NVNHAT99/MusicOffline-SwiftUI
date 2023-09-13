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
            ContentView(viewModel: ContentViewHandler())
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            default:
                break
            }
        }
    }
}


// MARK: - TODO: xoa playlist, editPlaylist, tao man hinh mini notification
