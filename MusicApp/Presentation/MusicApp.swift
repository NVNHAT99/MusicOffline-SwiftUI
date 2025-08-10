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
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: mainTabarViewVM)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                print("😴 background task")
                WebServerGCDService.shared.stopWebUploader()
            case .inactive:
                print("😴 App inactive")
            case .active:
                print("🚀 App trở lại active")
            @unknown default:
                break
            }
        }
    }
}
