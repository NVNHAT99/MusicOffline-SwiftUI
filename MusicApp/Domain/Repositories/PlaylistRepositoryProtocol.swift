//
//  PlaylistRepositoryProtocol.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation

protocol PlaylistRepositoryProtocol {
    func fetchPlaylist(with name: String) async throws -> Playlist?
    func fetchAllPlayList() async throws -> [Playlist]
    func addPlaylist(with playlist: Playlist) async throws
    func deletePlaylist(with playListId: String) async throws
    func deleteListPlaylist(with playlistIDs: [String]) async throws
}
