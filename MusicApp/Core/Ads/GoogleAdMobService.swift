//
//  GoogleAdMobService.swift
//  MusicApp
//
//  Interstitial ad service using Google Mobile Ads SDK.
//  Ported from EZTranslate with the cold-start preload race fix and
//  await-full-dismissal delegate. All GAD imports stay in this file.
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class GoogleAdMobService {

    static let shared = GoogleAdMobService()

    // MARK: - State

    private var interstitial: InterstitialAd?
    private var isShowingAd = false
    private var isPreloading = false

    // Minimum seconds between two consecutive interstitials (cooldown).
    private static let cooldownSeconds: TimeInterval = 30
    private var lastShownAt: Date?

    // Strong ref to the presentation delegate (GAD holds it weakly).
    private var presentationDelegate: InterstitialPresentationDelegate?

    private init() {}

    var isAvailable: Bool { interstitial != nil && !isShowingAd }

    // MARK: - Preload

    /// Preload an interstitial in the background. Idempotent.
    func preloadIfNeeded() async {
        guard interstitial == nil, !isPreloading, !isShowingAd else { return }
        isPreloading = true
        defer { isPreloading = false }
        do {
            interstitial = try await InterstitialAd.load(
                with: AdMobConfig.interstitialId,
                request: Request()
            )
        } catch {
            interstitial = nil
        }
    }

    // MARK: - Show

    /// Present the interstitial, awaiting FULL dismissal before returning.
    @discardableResult
    func showInterstitial() async -> Bool {
        guard !isShowingAd else { return false }

        if let last = lastShownAt, Date().timeIntervalSince(last) < Self.cooldownSeconds {
            return false
        }

        // Cold start: the ad may still be loading. Wait (bounded) for it.
        if interstitial == nil {
            await waitForInterstitial(timeout: 8.0)
        }

        guard let ad = interstitial, let rootVC = topViewController() else {
            return false
        }

        interstitial = nil
        isShowingAd = true
        lastShownAt = Date()

        let result = await withCheckedContinuation { continuation in
            let delegate = InterstitialPresentationDelegate { [weak self] in
                self?.isShowingAd = false
                self?.presentationDelegate = nil
                continuation.resume(returning: true)
            }
            self.presentationDelegate = delegate
            ad.fullScreenContentDelegate = delegate
            ad.present(from: rootVC)
        }

        Task { await preloadIfNeeded() }
        return result
    }

    // MARK: - Private helpers

    /// Poll until an interstitial is loaded or the timeout elapses. Re-kicks a
    /// load if none is running (covers an in-flight preload that fails).
    private func waitForInterstitial(timeout: TimeInterval) async {
        let deadline = Date().addingTimeInterval(timeout)
        while interstitial == nil, Date() < deadline {
            if !isPreloading { Task { await preloadIfNeeded() } }
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        return topmost(from: root)
    }

    private func topmost(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topmost(from: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topmost(from: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topmost(from: selected)
        }
        return vc
    }
}

// MARK: - InterstitialPresentationDelegate

/// Bridges GAD's full-screen callbacks to a single fire-once closure that runs
/// when the ad is dismissed OR fails to present.
@MainActor
private final class InterstitialPresentationDelegate: NSObject, FullScreenContentDelegate {

    private var onFinished: (() -> Void)?

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    private func finish() {
        let callback = onFinished
        onFinished = nil
        callback?()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finish()
    }
}
