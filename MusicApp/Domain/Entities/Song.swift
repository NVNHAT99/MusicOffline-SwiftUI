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
    public let urlStr: String
    
    public var url: URL? {
        if urlStr.hasPrefix("file://") {
            return URL(string: urlStr) // absolute file URL
        } else {
            return URL(fileURLWithPath: urlStr) // plain path
        }
    }
    
    public var durationString: String {
        duration.toTimeString()
    }
}
