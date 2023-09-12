//
//  DocumentFilePicker.swift
//  MusicApp
//
//  Created by Nhat on 7/13/23.
//

import Foundation
import MobileCoreServices
import SwiftUI
import AVFoundation

struct MP3File: Identifiable {
    let id = UUID()
    let fileName: String
    let fileURL: URL
    var isSelected: Bool
}

final class DocumentFileManager: NSObject {
    
    public static let shared: DocumentFileManager =  DocumentFileManager()
    
    private override init() {
        super.init()
    }
    private var onSelection: (([URL]) -> Void)?
    
    func pickFiles(completion: @escaping ([URL]) -> Void) {
        onSelection = completion
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeMP3 as String], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        Helper.shared.keyWindown?.rootViewController?.present(documentPicker, animated: true)
    }
    
    func loadMP3File() -> [MP3File] {
        // MARK: - TODO: need create code logic to read all mp3 file and return an array of string mp3 file URL
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var mp3Files: [MP3File] = []
        
        
        let allFileURLs = getAllFileURLs(in: documentURL)
        
        for fileURL in allFileURLs {
            if fileURL.pathExtension.lowercased() == "mp3" {
                let mp3File = MP3File(fileName: fileURL.lastPathComponent, fileURL: fileURL, isSelected: false)
                mp3Files.append(mp3File)
            }
        }
        
        return mp3Files
    }
    
    func getAllFileURLs(in directoryURL: URL) -> [URL] {
        var allFileURLs: [URL] = []
        
        // Enumerate contents of the directory
        if let enumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                do {
                    // Check if the file URL is a directory
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
                    if let isDirectory = resourceValues.isDirectory, isDirectory {
                        // If it's a directory, recursively get file URLs within the subdirectory
                        let subdirectoryFiles = getAllFileURLs(in: fileURL)
                        allFileURLs.append(contentsOf: subdirectoryFiles)
                    } else {
                        // If it's a file, add it to the array
                        if !allFileURLs.contains(fileURL) {
                            allFileURLs.append(fileURL)
                        }
                    }
                } catch {
                    // Handle the error as needed
                    print("Error accessing resource values for file at URL: \(fileURL), error: \(error)")
                }
            }
        }
        
        return allFileURLs
    }
    
    func loadMetadata(url: URL) async throws -> SongInfo? {
        let asset = AVAsset(url: url)
        var songName: String = url.lastPathComponent
        var albumName: String = String.empty
        var thumbnail: UIImage?
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
                case AVMetadataKey.commonKeyArtwork.rawValue:
                    if let data = value as? Data, let image = UIImage(data: data) {
                        thumbnail = image
                    }
                default:
                    break
                }
            }
        }
        
        return SongInfo(name: songName,
                        albumName: albumName,
                        image: String.empty,
                        singerName: String.empty,
                        thumbnail: thumbnail,
                        duration: duration)
    }
// MARK: - NOTE this is old version of function to load metaData from mp3 file
//    func loadMetadata2(url: URL) async -> SongInfo {
//        let asset = AVAsset(url: url)
//        var songName: String = String.empty
//        var albumName: String = String.empty
//        var thumbnail: UIImage?
//
//        asset.loadwithcomple
//        for format in asset.availableMetadataFormats {
//            for metadata in asset.metadata(forFormat: format) {
//                if let commonKey = metadata.commonKey?.rawValue, let value = metadata.value {
//                    switch commonKey {
//                    case AVMetadataKey.commonKeyTitle.rawValue:
//                        if let title = value as? String {
//                            songName = title
//                        }
//                    case AVMetadataKey.commonKeyAlbumName.rawValue:
//                        if let album = value as? String {
//                            albumName = album
//                        }
//                    case AVMetadataKey.commonKeyArtwork.rawValue:
//                        if let data = value as? Data, let image = UIImage(data: data) {
//                            thumbnail = image
//                        }
//                    default:
//                        break
//                    }
//                }
//            }
//        }
//
//        return SongInfo(name: songName,
//                        albumName: albumName,
//                        image: String.empty,
//                        singerName: String.empty,
//                        thumbnail: thumbnail)
//    }
}

extension DocumentFileManager: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onSelection?(urls)
        onSelection = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onSelection?([])
        onSelection = nil
    }
}
