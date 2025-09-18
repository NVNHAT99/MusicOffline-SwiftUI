//
//  MusicApp.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI

@main
struct MusicApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Dependencies
    private let dependencies = AppDependencies.shared

    init() {
        // Configure logging at app startup
        Logger.setup(level: .debug, colored: true, timestamp: true, shortenFileNames: true)
        Logger.info("🚀 MusicApp starting up")
    }

    var body: some Scene {
        WindowGroup {
            SplashView(mainTabViewModel: dependencies.makeMainTabViewModel())
                .environment(\.appDependencies, dependencies)
                .environmentObject(dependencies.makePlayerManager())
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - Private Methods
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            Logger.info("😴 App entering background")
            WebServerGCDService.shared.stopWebUploader()
            dependencies.handleAppDidEnterBackground()
        case .inactive:
            Logger.info("😴 App inactive")
        case .active:
            Logger.info("🚀 App becoming active")
            dependencies.handleAppWillEnterForeground()
        @unknown default:
            Logger.warning("Unknown scene phase: \(phase)")
            break
        }
    }
}
