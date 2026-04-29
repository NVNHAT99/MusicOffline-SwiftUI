//
//  SettingConstants.swift
//  MusicApp
//

import Foundation

enum SettingConstants {
    // TODO: Replace with real URLs before release
    static let privacyURL = URL(string: "https://example.com/privacy")!
    static let termsURL = URL(string: "https://example.com/terms")!

    // TODO: Replace with real App Store ID before release
    static let appStoreID = "0000000000"
    static var shareURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }
}
