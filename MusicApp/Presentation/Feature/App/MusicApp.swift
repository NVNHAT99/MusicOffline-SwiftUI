//
//  MusicApp.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//  Refactored with AppEnvironment bootstrap by Claude
//

import SwiftUI

@main
struct MusicApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - App Environment
    @StateObject private var environment = AppEnvironment.bootstrap()

    init() {
        // Configure logging at app startup
        Logger.setup(level: .debug, colored: true, timestamp: true, shortenFileNames: true)
        Logger.info("🚀 MusicApp starting up with AppEnvironment")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment.diContainer)
                .environmentObject(environment.diContainer.appState)
                .environmentObject(environment.appRouter)
                .environmentObject(environment.diContainer.makePlayerManager())
        }
        .onChange(of: scenePhase) { newPhase in
            environment.handleScenePhaseChange(newPhase)
        }
    }
}
