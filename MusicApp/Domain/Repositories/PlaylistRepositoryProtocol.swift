//
//  PlaylistRepositoryProtocol.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation

protocol PlaylistRepositoryProtocol {
    func fetchPlaylist(with name: String) async throws -> Playlist?
    func fetchPlaylist(with id: UUID) async throws -> Playlist?
    func fetchPlaylist(with idArray: [UUID]) async throws -> [Playlist]
    func fetchAllPlayList() async throws -> [Playlist]
    func addPlaylist(with playlist: Playlist) async throws
    func updatePlaylist(by playlistID: UUID, with songIds: [UUID]) async throws
    func deletePlaylist(with playListId: UUID) async throws
    func deleteListPlaylist(with playlistIDs: [UUID]) async throws
    func removeDeleteSong(from songId: UUID) async throws
}
