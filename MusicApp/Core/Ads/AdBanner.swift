//
//  AdBanner.swift
//  MusicApp
//
//  SwiftUI banner ad. Wraps GADBannerView via UIViewRepresentable and reserves
//  a fixed 50pt height so there is no layout shift before the ad loads.
//

import SwiftUI
import GoogleMobileAds

/// A standard 320x50 adaptive banner. Hidden until an ad loads to avoid an
/// empty grey box. Reserves 50pt of height regardless.
struct AdBanner: View {
    @ObservedObject private var appState = AppState.shared
    private let adUnitId: String

    init(adUnitId: String = AdMobConfig.bannerId) {
        self.adUnitId = adUnitId
    }

    var body: some View {
        // Premium users see no banner (and it reserves no height).
        if !appState.isPremium {
            BannerViewRepresentable(adUnitId: adUnitId)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - UIViewRepresentable bridge

private struct BannerViewRepresentable: UIViewRepresentable {
    let adUnitId: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitId
        banner.rootViewController = Self.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if uiView.rootViewController == nil {
            uiView.rootViewController = Self.rootViewController()
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: { $0.isKeyWindow })?.rootViewController
    }
}
