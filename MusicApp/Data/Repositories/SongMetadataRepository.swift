//
//  SongMetadataRepository.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/8/25.
//

import AVFoundation
import UIKit

enum SongMetadataError: Error {
    case invalidURL
    case metadataLoadFailed
    case fileNotFound
}

final class SongMetadataRepository: SongMetadataRepositoryProtocol {
    func loadSong(from fileURL: String) async throws -> Song {
        let url = URL(fileURLWithPath: fileURL)
        let asset = AVAsset(url: url)
        
        // Kiểm tra file có tồn tại không
        guard try await asset.load(.isReadable) else {
            throw SongMetadataError.fileNotFound
        }
        
        var songName: String = url.lastPathComponent.replacingOccurrences(of: ".mp3", with: "")
        var albumName: String = "Unknown"
        var artistName: String = "Unknown Artist"
        
        let duration: Double = try await asset.load(.duration).seconds
        
        do {
            let metadata = try await asset.load(.metadata)
            
            for item in metadata {
                guard let commonKey = item.commonKey?.rawValue,
                      let value = try await item.load(.value) else { continue }
                
                switch commonKey {
                case AVMetadataKey.commonKeyTitle.rawValue:
                    if let title = value as? String, !title.isEmpty {
                        songName = title
                    }
                case AVMetadataKey.commonKeyAlbumName.rawValue:
                    if let album = value as? String, !album.isEmpty {
                        albumName = album
                    }
                case AVMetadataKey.commonKeyArtist.rawValue:
                    if let artist = value as? String, !artist.isEmpty {
                        artistName = artist
                    }
                default:
                    break
                }
            }
        } catch {
            // Log error nhưng vẫn trả về Song với thông tin cơ bản
            print("Failed to load metadata: \(error)")
        }
        
        return Song(
            id: UUID(),
            title: songName,
            album: albumName,
            artist: artistName,
            duration: duration,
            urlStr: fileURL
        )
    }
    
    func loadSongs(from urls: [String]) async throws -> [Song] {
        try await withThrowingTaskGroup(of: Song.self) { group in
            for url in urls {
                group.addTask {
                    try await self.loadSong(from: url)
                }
            }
            
            var results: [Song] = []
            for try await song in group {
                results.append(song)
            }
            return results
        }
    }
}
