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

struct SongMapper {
    static func makeSong(from fileURL: String) async throws -> Song {
        let url = URL(fileURLWithPath: fileURL)
        // TODO: have a bug in here
        // it's seem can't get infomation from mp3 file
        let asset = AVAsset(url: url)
        var songName: String = url.lastPathComponent.replacingOccurrences(of: ".mp3", with: "")
        var albumName: String = String.Unkown
        //var thumbnail: UIImage?
        var duration: Double = asset.duration.seconds
        let arrayMetaData = try await asset.load(.metadata)
        for metaData in arrayMetaData {
            if let commonKey = metaData.commonKey?.rawValue, let value = try await metaData.load(.value) {
                switch commonKey {
                case AVMetadataKey.commonKeyTitle.rawValue:
                    if let title = value as? String {
                        songName = title
                    }
                case AVMetadataKey.commonKeyAlbumName.rawValue:
                    if let album = value as? String {
                        albumName = album
                    }
//                case AVMetadataKey.commonKeyArtwork.rawValue:
//                    if let data = value as? Data, let image = UIImage(data: data) {
//                        thumbnail = image
//                    }
                default:
                    break
                }
            }
        }
        
        return Song(id: UUID(),
                    title: songName,
                    album: albumName,
                    artist: "artist",
                    duration: duration,
                    urlStr: fileURL)
    }
    
    static func loadSongs(from urls: [String]) async throws -> [Song] {
        try await withThrowingTaskGroup(of: Song.self) { group in
            for url in urls {
                group.addTask {
                    try await makeSong(from: url)
                }
            }
            
            var results: [Song] = []
            for try await song in group {
                results.append(song)
            }
            return results
        }
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
