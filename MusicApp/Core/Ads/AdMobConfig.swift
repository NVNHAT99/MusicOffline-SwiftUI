//
//  AdMobConfig.swift
//  MusicApp
//
//  AdMob identifiers. Test IDs are used in DEBUG to comply with AdMob policy;
//  production IDs are used in Release builds.
//

import Foundation

enum AdMobConfig {

    // MARK: - App ID (also set in Info.plist as GADApplicationIdentifier)
    static let appId = "ca-app-pub-9481704307510282~6397847108"

    // MARK: - Ad Unit IDs

    /// Home banner. DEBUG → Google test banner.
    static var bannerId: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716" // Google test banner
        #else
        return "ca-app-pub-9481704307510282/9740866756"
        #endif
    }

    /// Interstitial (app-open). DEBUG → Google test interstitial.
    static var interstitialId: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910" // Google test interstitial
        #else
        return "ca-app-pub-9481704307510282/6913090370"
        #endif
    }
}
