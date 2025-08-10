//
//  DocumentFilePicker.swift
//  MusicApp
//
//  Created by Nhat on 7/13/23.
//

import AVFoundation
import UIKit

protocol DocumentFileServiceProtocol {
    func loadMetadata(from stringURL: String) async throws -> SongInfo?
    func removeAllFiles() async throws
    func removeFiles(_ pathFileElements: [PathFileElement]) async throws
}


final class DocumentFileService: DocumentFileServiceProtocol {
    
    func loadMetadata(from stringURL: String) async throws -> SongInfo? {
        guard let url = URL(string: stringURL) else {
            return SongInfo(
                name: .Unkown,
                albumName: .Unkown,
                image: .empty,
                singerName: .Unkown,
                thumbnail: nil,
                duration: 0
            )
        }
        
        let asset = AVAsset(url: url)
        var songName = url.lastPathComponent.replacingOccurrences(of: ".mp3", with: "")
        var albumName = String.Unkown
        var thumbnail: UIImage?
        let duration = try await asset.load(.duration)

        let metadata = try await asset.load(.metadata)
        
        for item in metadata {
            guard let key = item.commonKey?.rawValue,
                  let value = try? await item.load(.value) else { continue }
            
            switch key {
            case AVMetadataKey.commonKeyTitle.rawValue:
                if let title = value as? String {
                    songName = title
                }
            case AVMetadataKey.commonKeyAlbumName.rawValue:
                if let album = value as? String {
                    albumName = album
                }
            case AVMetadataKey.commonKeyArtwork.rawValue:
                if let data = value as? Data, let image = UIImage(data: data) {
                    thumbnail = image
                }
            default:
                break
            }
        }
        
        return SongInfo(
            name: songName,
            albumName: albumName,
            image: .empty,
            singerName: .Unkown,
            thumbnail: thumbnail,
            duration: duration.seconds
        )
    }
    
    func removeAllFiles() async throws {
        try await Task.detached {
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentURL, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        }.value
    }
    
    func removeFiles(_ pathFileElements: [PathFileElement]) async throws {
        try await Task.detached {
            for element in pathFileElements {
                guard let path = element.pathLocalFile else { continue }
                let fileURL = URL(fileURLWithPath: path)
                
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        }.value
    }
}
