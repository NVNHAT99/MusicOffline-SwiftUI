//
//  SongMetadataRepositoryProtocol.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/8/25.
//

import Foundation

protocol SongMetadataRepositoryProtocol {
    func loadSong(from fileURL: String) async throws -> Song
    func loadSongs(from urls: [String]) async throws -> [Song]
}
