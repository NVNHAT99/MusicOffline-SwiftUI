//
//  AdBanner.swift
//  MusicApp
//
//  SwiftUI banner ad. Wraps GADBannerView via UIViewRepresentable and reserves
//  a fixed 50pt height so there is no layout shift before the ad loads.
//

import SwiftUI
import GoogleMobileAds

/// Banner sizes we use in the app.
enum AdBannerSize {
    case standard      // 320x50
    case mediumRect    // 300x250 (MREC — highest eCPM)

    var gadSize: AdSize {
        switch self {
        case .standard:   return AdSizeBanner
        case .mediumRect: return AdSizeMediumRectangle
        }
    }

    var height: CGFloat {
        switch self {
        case .standard:   return 50
        case .mediumRect: return 250
        }
    }
}

/// A banner ad. Defaults to MREC (300x250) for higher ad revenue. Hidden for
/// premium users (and then reserves no height). Reserves its height otherwise
/// to avoid layout shift before the ad loads.
struct AdBanner: View {
    @ObservedObject private var appState = AppState.shared
    private let adUnitId: String
    private let size: AdBannerSize

    init(adUnitId: String = AdMobConfig.bannerId, size: AdBannerSize = .mediumRect) {
        self.adUnitId = adUnitId
        self.size = size
    }

    var body: some View {
        // Premium users see no banner (and it reserves no height).
        if !appState.isPremium {
            BannerViewRepresentable(adUnitId: adUnitId, size: size)
                .frame(height: size.height)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - UIViewRepresentable bridge

private struct BannerViewRepresentable: UIViewRepresentable {
    let adUnitId: String
    let size: AdBannerSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: size.gadSize)
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
