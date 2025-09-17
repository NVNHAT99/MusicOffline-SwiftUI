//
//  PlayListEnity.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

public struct Playlist: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let songIDs: [UUID]
}
