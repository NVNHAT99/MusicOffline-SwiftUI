//
//  MainTab.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Main tab bar items for the app
enum MainTab: Int, CaseIterable, Hashable {
    case home
    case playlist
    case transfer
    case setting

    var identifier: String {
        switch self {
        case .home:
            return "home"
        case .playlist:
            return "playlist"
        case .transfer:
            return "transfer"
        case .setting:
            return "setting"
        }
    }
}
