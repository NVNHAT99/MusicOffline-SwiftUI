//
//  ATTrackingService.swift
//  MusicApp
//
//  App Tracking Transparency (ATT) consent, required by iOS 14.5+ before the
//  ad SDK may read the IDFA. AdMob still serves ads when denied — only
//  personalization (and eCPM) drops. The system prompt shows at most once per
//  install; on subsequent launches this is a no-op.
//

import Foundation
import AppTrackingTransparency

@MainActor
enum ATTrackingService {

    /// Request tracking authorization, awaiting the user's response.
    ///
    /// - The system shows its prompt only when status is `.notDetermined`; if
    ///   the user already answered, this returns immediately.
    /// - A short delay lets the launch UI settle first, so the prompt does not
    ///   compete with the launch screen (Apple requires an active, foreground
    ///   scene for the prompt to appear).
    /// - Returns after the user responds (or immediately if already decided),
    ///   so the caller can start the ad SDK afterward regardless of outcome.
    static func requestAuthorization() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            return
        }

        // Let the launch screen dismiss and the scene become active first.
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s

        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}
