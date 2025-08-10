//
//  Album.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/7/25.
//


public struct Album: Identifiable, Equatable {
    public let id: String       // album name (unique)
    public let title: String
    public let songs: [Song]
    
    public var songCount: Int { songs.count }
}
