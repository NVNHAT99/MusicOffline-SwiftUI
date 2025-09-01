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

final class PlaylistEventCenter {
    static let shared = PlaylistEventCenter()
    let subject = PassthroughSubject<PlaylistEvent, Never>()
    private init() {}
}
