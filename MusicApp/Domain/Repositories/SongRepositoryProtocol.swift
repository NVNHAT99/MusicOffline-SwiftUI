//
//  SongRepositoryProtocol.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation
import CoreData

protocol SongRepositoryProtocol {
    func addSong(_ song: Song) async throws
    func addSongs(_ songs: [Song]) async throws
    func fetchSongs(_ songIdArray: [UUID]) async throws -> [Song]
    func fetchAllSongs() async throws -> [Song]
    func updateSong(from oldPath: String, to newPath: String) async throws
    func updateSongs(from dictionaryFileURLs: [String : String]) async throws
    func deleteSong(withURL url: String) async throws -> UUID
    func deleteSongs(with elements: [PathFileElement]) async throws
    func deleteAllSongs() async throws
    
    func performBatchOperation(
            songsToAdd: [Song],
            pathsToUpdate: [String: String],
            elementsToDelete: [PathFileElement]
        ) async throws
}
