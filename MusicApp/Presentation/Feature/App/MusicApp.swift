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
            print("😴 background task")
            WebServerGCDService.shared.stopWebUploader()
            dependencies.handleAppDidEnterBackground()
        case .inactive:
            print("😴 App inactive")
        case .active:
            print("🚀 App trở lại active")
            dependencies.handleAppWillEnterForeground()
        @unknown default:
            break
        }
    }
}
