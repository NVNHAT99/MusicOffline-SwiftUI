//
//  MusicAppApp.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI

@main
struct MusicAppApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        // MARK: - TODO: you must implement play lastest song user play when app is close in pause state
        // must save the play list, index of that playlist. state of repeat
        PlaylistManager.provide(PlayViewModel())
        PlaylistManager.shared.setUpSubscrib()
    }
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewHandler())
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                WebServerWrapper.shared.stopWebUploader()
            default:
                break
            }
        }
    }
}
