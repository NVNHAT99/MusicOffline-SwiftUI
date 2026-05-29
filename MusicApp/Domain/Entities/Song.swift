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
        let rawURL: URL? = urlStr.hasPrefix("file://")
            ? URL(string: urlStr)            // absolute file URL
            : URL(fileURLWithPath: urlStr)   // plain path

        guard let rawURL else { return nil }

        // The app's Data container UUID changes across reinstall/restore, so an
        // absolute path saved in a previous launch (…/Containers/Data/Application/
        // <old-uuid>/Documents/Music/song.mp3) no longer resolves even though the
        // file is still there under the current container. Re-anchor by filename
        // to the current Documents directory when the stored path is stale.
        if FileManager.default.fileExists(atPath: rawURL.path) {
            return rawURL
        }
        return Song.resolveInDocuments(filename: rawURL.lastPathComponent) ?? rawURL
    }

    /// Locate a file by name under the current Documents directory, preferring
    /// the managed `Music/` subfolder, then the Documents root.
    private static func resolveInDocuments(filename: String) -> URL? {
        guard !filename.isEmpty,
              let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }

        let candidates = [
            docs.appendingPathComponent("Music", isDirectory: true).appendingPathComponent(filename),
            docs.appendingPathComponent(filename)
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }
    
    public var durationString: String {
        duration.toTimeString()
    }
}
