//
//  SongRepositoryProtocol.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol SongRepositoryProtocol {
    func addSong(_ song: Song) async throws
    func addSongs(_ songs: [Song]) async throws
    func fetchAllSongs() async throws -> [Song]
//    func updateSong(id: UUID, newTitle: String) async throws -> SongEntity
    func deleteSong(withId id: String) async throws
    func deleteAllSongs() async throws
}
