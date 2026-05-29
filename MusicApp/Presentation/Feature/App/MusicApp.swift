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
        // Configure logging at app startup. In release the Logger clamps this
        // to .warning so verbose/path/PII lines never reach the device console.
        #if DEBUG
        Logger.setup(level: .debug, colored: true, timestamp: true, shortenFileNames: true)
        #else
        Logger.setup(level: .warning, colored: false, timestamp: true, shortenFileNames: true)
        #endif
        Logger.info("🚀 MusicApp starting up with AppEnvironment")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment.diContainer)
                .environmentObject(environment.diContainer.appState)
                .environmentObject(environment.appRouter)
                .environmentObject(environment.diContainer.makePlayerManager())
                .onOpenURL { url in
                    Logger.debug("Received external URL")
                    ExternalFileImportCoordinator.shared.handle(openURL: url)
                }
        }
        .onChange(of: scenePhase) { newPhase in
            environment.handleScenePhaseChange(newPhase)
            if newPhase == .active {
                // Pick up files dropped via Finder / Files.app while we were gone.
                Task { @MainActor in
                    ExternalFileImportCoordinator.shared.scanDocumentsRootAndImport()
                }
            }
        }
    }
}
