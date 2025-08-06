//
//  AddSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol AddSongUseCaseProtocol {
    func execute(from url: String) async throws
    func excuteList(from list: [String]) async throws
}

struct AddSongUseCase: AddSongUseCaseProtocol {
    
    private let repository: SongRepositoryProtocol
    
    init(repository: SongRepositoryProtocol = SongRepository()) {
        self.repository = repository
    }
    
    func execute(from url: String) async throws {
        let song = try await SongMapper.makeSong(from: url)
        try await repository.addSong(song)
    }
    
    func excuteList(from list: [String]) async throws {
        let songs = try await SongMapper.loadSongs(from: list)
        try await repository.addSongs(songs)
    }
}
