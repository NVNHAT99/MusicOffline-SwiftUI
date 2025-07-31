//
//  SongMappers.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/31/25.
//

import AVFoundation
import CommonCrypto
import CoreData

enum SongMapperError: Error {
    case invalidURL
}

struct SongMappers {
    static func makeSong(from fileURL: String) throws -> Song {
        guard let url = URL(string: fileURL) else {
            throw SongMapperError.invalidURL
        }
        let asset = AVAsset(url: url)
        let metadata = asset.commonMetadata
        
        let title = metadata.first(where: { $0.commonKey?.rawValue == "title" })?.stringValue ?? "Unknown Title"
        let artist = metadata.first(where: { $0.commonKey?.rawValue == "artist" })?.stringValue ?? "Unknown Artist"
        let album = metadata.first(where: { $0.commonKey?.rawValue == "albumName" })?.stringValue ?? "Unknown Artist"
        
        let duration = CMTimeGetSeconds(asset.duration)
        let id = fileURL.sha256()
        
        return Song(id: id,
                    title: title,
                    album: album,
                    artist: artist,
                    duration: duration,
                    urlStr: fileURL)
    }
    
    static func mapToEntity(song: Song, context: NSManagedObjectContext) -> SongEntity {
        let entity = SongEntity(context: context)
        entity.id = song.id
        entity.title = song.title.trimmingCharacters(in: .whitespacesAndNewlines)
        entity.album = song.album
        entity.artist = song.artist
        entity.duration = song.duration
        entity.url = song.urlStr
        return entity
    }
}
