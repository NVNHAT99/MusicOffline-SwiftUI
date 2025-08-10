//
//  SongEntity.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//
import Foundation

public struct Song: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let album: String
    public let artist: String
    public let duration: Double
    // url is mean the path of file in your phone
    public let urlStr: String
    
    
    var url: URL? {
        return URL(string: urlStr)
    }
}
