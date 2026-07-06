//
//  AppDelegate.swift
//  MusicApp
//
//  Hosts app-lifecycle work that must run outside the SwiftUI scene:
//  Mobile Ads SDK start + the app-open interstitial.
//
//  Mirrors EZTranslate: in a SwiftUI App-lifecycle app, UIApplicationDelegate's
//  applicationDidBecomeActive is NOT called, so app-open counting is driven by
//  UIApplication.didBecomeActiveNotification instead.
//

import UIKit
import GoogleMobileAds

final class AppDelegate: NSObject, UIApplicationDelegate {

    /// Set when the process launches; consumed by the first real foreground to
    /// tell a cold start apart from a background resume.
    private var pendingColdStart = false

    /// True once the app has genuinely entered the background. Ignores transient
    /// didBecomeActive events (Control Center, system alerts) that are not real
    /// app-opens and must not advance the interstitial counter.
    private var didEnterBackground = false

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        pendingColdStart = true

        // Start the Mobile Ads SDK and warm the first interstitial.
        MobileAds.shared.start(completionHandler: nil)
        Task { @MainActor in await GoogleAdMobService.shared.preloadIfNeeded() }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        return true
    }

    @objc private func handleDidEnterBackground() {
        didEnterBackground = true
    }

    @objc private func handleDidBecomeActive() {
        // Only act on a real app-open: a cold start, or a resume after the app
        // genuinely went to the background. Ignore transient reactivations.
        let isColdStart = pendingColdStart
        pendingColdStart = false
        let isRealForeground = isColdStart || didEnterBackground
        didEnterBackground = false
        guard isRealForeground else { return }

        Task { @MainActor in
            await GoogleAdMobService.shared.preloadIfNeeded()
            if AdCounterService.shared.recordEvent(.appOpen) {
                await GoogleAdMobService.shared.showInterstitial()
            }
        }
    }
}
