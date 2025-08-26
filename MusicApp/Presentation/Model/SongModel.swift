//
//  SongModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/25/25.
//

import Foundation

public struct SongModel: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let album: String
    public let artist: String
    public let duration: Double
    public let urlStr: String
    
    var url: URL? {
        URL(string: urlStr)
    }
    
    var durationString: String {
        duration.toTimeString()
    }
}
