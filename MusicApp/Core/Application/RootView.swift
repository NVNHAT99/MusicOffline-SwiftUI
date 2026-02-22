//
//  RootView.swift
//  MusicApp
//
//  Created by Claude
//  Following EasyFax RootView pattern
//

import SwiftUI

/// Root view following EasyFax pattern
/// Manages app-level flow (Splash, Onboarding, Main App)
public struct RootView: View {

    // MARK: - Properties
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var container: DIContainer
    @EnvironmentObject var appRouter: Router<AppRoute>

    // MARK: - Body
    public var body: some View {
        Group {
            if !appState.isOnboardingCompleted {
                // TODO: Show onboarding if not completed
                // For now, skip onboarding
                MainTabView()
            } else {
                // Show main app
                MainTabView()
            }
        }
        .overlay {
            // Show splash on top during initialization
            if appState.isChecking {
                splashView
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Splash View
    private var splashView: some View {
        VStack {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.white)

            Text("Music App")
                .font(.title)
                .foregroundColor(.white)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundColor)
    }
}
