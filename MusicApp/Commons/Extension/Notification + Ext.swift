//
//  Notification + Ext.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/17/25.
//

import Foundation

extension Notification.Name {
    static let openPlaylistDetail = Notification.Name("openPlaylistDetail")
    /// Posted with `object: MainTab` to request a tab switch from anywhere in the app.
    static let switchMainTab = Notification.Name("switchMainTab")
}
