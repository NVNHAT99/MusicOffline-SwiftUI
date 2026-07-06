//
//  AdCounterService.swift
//  MusicApp
//
//  Counter-based interstitial frequency, persisted in UserDefaults.
//  Ported from EZTranslate (no premium gate — MusicOffline shows ads to all).
//

import Foundation

enum AdTrigger: String, CaseIterable {
    case appOpen // App returned to foreground → interstitial
}

@MainActor
final class AdCounterService {

    static let shared = AdCounterService()

    // Show an interstitial every N app-opens.
    private static let thresholds: [AdTrigger: Int] = [
        .appOpen: 4
    ]

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    private func key(_ trigger: AdTrigger) -> String { "ad.counter.\(trigger.rawValue)" }

    /// Increment the trigger's counter. Returns true when the threshold is
    /// reached (and resets the counter). Premium users never see ads.
    func recordEvent(_ trigger: AdTrigger) -> Bool {
        guard !AppState.shared.isPremium else { return false }

        let k = key(trigger)
        let threshold = Self.thresholds[trigger] ?? Int.max
        let newCount = userDefaults.integer(forKey: k) + 1

        if newCount >= threshold {
            userDefaults.set(0, forKey: k)
            return true
        }
        userDefaults.set(newCount, forKey: k)
        return false
    }
}
