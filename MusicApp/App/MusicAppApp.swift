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
