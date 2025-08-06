//
//  UpdateSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/5/25.
//

import Foundation

protocol UpdateSongUseCaseProtocol {
    func excute(from oldPath: String, to newPath: String) async throws
    func excuteWithList(with dictionaryPath: [String: String]) async throws
}

final class UpdateSongUseCase: UpdateSongUseCaseProtocol {
    
    private let songRepository: SongRepositoryProtocol
    
    init(songRepository: SongRepositoryProtocol = SongRepository()) {
        self.songRepository = songRepository
    }
    
    func excute(from oldPath: String, to newPath: String) async throws {
        try await songRepository.updateSong(from: oldPath, to: newPath)
    }
    
    func excuteWithList(with dictionaryPath: [String : String]) async throws {
        try await songRepository.updateSongs(from: dictionaryPath)
    }
}
