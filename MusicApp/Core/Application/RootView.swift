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

    @State private var importToast: String? = nil
    @State private var toastTask: Task<Void, Never>? = nil
    @State private var showFilesImport: Bool = false

    // MARK: - Body
    public var body: some View {
        Group {
            if !appState.isOnboardingCompleted {
                MainTabView()
            } else {
                MainTabView()
            }
        }
        .overlay {
            if appState.isChecking {
                splashView
                    .ignoresSafeArea()
            }
        }
        .overlay(alignment: .top) {
            if let toast = importToast {
                Text(toast)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: importToast)
        .sheet(isPresented: $showFilesImport) {
            ImportSongView(viewModel: ImportSongViewModel())
                .background(Color.backgroundColor.ignoresSafeArea())
        }
        .onReceive(NotificationCenter.default.publisher(for: .openImportFromFiles)) { _ in
            // The Import Hub dismisses itself before posting; presenting from the
            // root (a different presenter) avoids a sheet-over-sheet conflict.
            showFilesImport = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .externalImportFinished)) { notif in
            guard let summary = notif.object as? ExternalImportSummary else { return }
            let msg: String
            if summary.failed == 0 {
                msg = summary.succeeded == 1
                    ? "Imported 1 song"
                    : "Imported \(summary.succeeded) songs"
            } else {
                msg = "Imported \(summary.succeeded), \(summary.failed) failed"
            }
            showToast(msg)
        }
    }

    private func showToast(_ message: String) {
        importToast = message
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { importToast = nil }
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
