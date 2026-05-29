//
//  AppState.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation
import Combine

/// Protocol defining app state management
public protocol AppStateProtocol: ObservableObject {
    var isOnboardingCompleted: Bool { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var isChecking: Bool { get } // For splash screen

    func markOnboardingCompleted()
    func setAuthenticated(_ isAuthenticated: Bool)
    func setLoading(_ isLoading: Bool)
}

/// Global app state manager following EasyFax pattern
/// Manages app-level state such as authentication, onboarding, and loading states
@MainActor
public final class AppState: AppStateProtocol {
    // MARK: - Singleton
    public static let shared: AppState = AppState()

    // MARK: - Published Properties
    @Published public var isOnboardingCompleted: Bool = false
    @Published public var isAuthenticated: Bool = true // Music app doesn't require auth
    @Published public var isLoading: Bool = false
    @Published public var isChecking: Bool = true // Splash screen check

    // MARK: - Private Properties
    private let userDefaults: UserDefaults

    // MARK: - Initialization
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Load persisted state
        self.isOnboardingCompleted = userDefaults.bool(forKey: "isOnboardingCompleted")
        self.isAuthenticated = userDefaults.bool(forKey: "isAuthenticated")

        // Simulate checking - in real app, check auth, onboarding, etc.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            self.isChecking = false
        }
    }

    // MARK: - Public Methods
    public func markOnboardingCompleted() {
        userDefaults.set(true, forKey: "isOnboardingCompleted")
        self.isOnboardingCompleted = true
        // Logger.info("Onboarding marked as completed")
    }

    public func setAuthenticated(_ isAuthenticated: Bool) {
        userDefaults.set(isAuthenticated, forKey: "isAuthenticated")
        self.isAuthenticated = isAuthenticated
        // Logger.info("Authentication state changed: \(isAuthenticated)")
    }

    public func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}
