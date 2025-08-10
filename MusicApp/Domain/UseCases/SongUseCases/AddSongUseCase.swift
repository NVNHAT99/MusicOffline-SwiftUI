//
//  AddSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol AddSongUseCaseProtocol {
    func execute(from url: String) async throws
    func executeList(from list: [String]) async throws
}

struct AddSongUseCase: AddSongUseCaseProtocol {
    
    private let repository: SongRepositoryProtocol
    private let songMetadataRepository: SongMetadataRepositoryProtocol
    init(repository: SongRepositoryProtocol = SongRepository(),
         songMetadataRepository: SongMetadataRepositoryProtocol = SongMetadataRepository()) {
        self.repository = repository
        self.songMetadataRepository = songMetadataRepository
    }
    
    func execute(from url: String) async throws {
        let song = try await songMetadataRepository.loadSong(from: url)
        try await repository.addSong(song)
    }
    
    func executeList(from list: [String]) async throws {
        let songs = try await songMetadataRepository.loadSongs(from: list)
        try await repository.addSongs(songs)
    }
}
