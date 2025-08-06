//
//  SongEntity.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import CoreData

public struct Song {
    let id: UUID
    let title: String
    let album: String
    let artist: String
    let duration: Double
    // url is mean the path of file in your phone
    let urlStr: String
    
    
    var url: URL? {
        return URL(string: urlStr)
    }
}
