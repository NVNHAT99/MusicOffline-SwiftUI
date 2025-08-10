//
//  FetchHomeDataUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//

import Foundation

protocol FetchHomeDataUseCaseProtocol {
    func execute() async throws -> HomeEntity
}

final class FetchHomeDataUseCase: FetchHomeDataUseCaseProtocol {
    
    private let fetchSongUseCase: FetchSongUseCaseProtocol
    private let fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol
    
    init(fetchSongUseCase: FetchSongUseCaseProtocol = FetchSongUseCase(),
         fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol = FetchPlaylistUseCase()) {
        self.fetchSongUseCase = fetchSongUseCase
        self.fetchPlaylistUseCase = fetchPlaylistUseCase
    }
    
    func execute() async throws -> HomeEntity {
        let listSong = try await fetchSongUseCase.executeGetAll()
        let dictionaryAlbums = Dictionary(grouping: listSong) { song in
            song.album
        }
        
        let albums = dictionaryAlbums.map { (albumTitle, songs) in
            Album(id: albumTitle, title: albumTitle, songs: songs)
        }
        let playlists = try await fetchPlaylistUseCase.executeGetAll()
        
        return .init(albums: albums, playlists: playlists, recentSongs: [])
    }
}
