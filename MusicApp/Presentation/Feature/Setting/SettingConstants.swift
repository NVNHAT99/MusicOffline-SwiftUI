//
//  SettingConstants.swift
//  MusicApp
//

import Foundation

enum SettingConstants {
    // RELEASE GATE: placeholder values — must be replaced with the real
    // privacy/terms pages and App Store ID before App Store submission.
    static let privacyURL = URL(string: "https://example.com/privacy")!
    static let termsURL = URL(string: "https://example.com/terms")!

    static let appStoreID = "0000000000"
    static var shareURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }
}
