//
//  SettingViewIntent.swift
//  MusicApp
//
//  Created by Nhat on 9/25/23.
//

import Foundation

enum SettingViewIntent {
    case deleteAllSongs
    case toggleServer
    case completedUploadSongs
    // About
    case rateApp
    case shareApp
    case cancelShareSheet
    case openPrivacy
    case openTerms
    // General
    case showLanguagePicker
    // Delete confirmation
    case confirmDeleteAllSongs
    case cancelDeleteAllSongs
}
