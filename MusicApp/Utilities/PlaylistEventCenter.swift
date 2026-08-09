//
//  PlaylistEventCenter.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/26/25.
//

import Foundation
import Combine

enum PlaylistEvent {
    case added(UUID)
    case updated(UUID)
    case deleted(UUID)
}

// Smart playlists live in a separate store, so they need their own event stream
// to keep the Library screen in sync the same way regular playlists do.
enum SmartPlaylistEvent {
    case added(UUID)
    case updated(UUID)
    case deleted(UUID)
}

final class PlaylistEventCenter {
    static let shared = PlaylistEventCenter()
    let subject = PassthroughSubject<PlaylistEvent, Never>()
    let smartSubject = PassthroughSubject<SmartPlaylistEvent, Never>()
    private init() {}
}
