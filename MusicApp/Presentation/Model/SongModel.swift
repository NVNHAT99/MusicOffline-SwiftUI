//
//  SongModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/25/25.
//

import Foundation

public struct SongModel: Identifiable, Equatable, Codable {
    public let id: UUID
    public let title: String
    public let album: String
    public let artist: String
    public let duration: Double
    public let urlStr: String?
    
    var durationString: String {
        duration.toTimeString()
    }
}

extension SongModel {
    func fileURLString() throws -> String {
        guard let urlStr else { throw URLError(.badURL) }
        return urlStr
    }

    /// Filesystem path that survives a changed app-container UUID. The stored
    /// `urlStr` is an absolute path captured in a prior launch; after reinstall/
    /// restore the container UUID changes and that path no longer resolves even
    /// though the file is still present. Re-anchor by filename to the current
    /// Documents directory (Music/ subfolder first, then root) when stale.
    func resolvedFilePath() -> String? {
        guard let urlStr, !urlStr.isEmpty else { return nil }

        let rawPath = urlStr.hasPrefix("file://")
            ? (URL(string: urlStr)?.path ?? urlStr)
            : urlStr

        if FileManager.default.fileExists(atPath: rawPath) {
            return rawPath
        }

        let filename = (rawPath as NSString).lastPathComponent
        guard !filename.isEmpty,
              let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }

        let candidates = [
            docs.appendingPathComponent("Music", isDirectory: true).appendingPathComponent(filename),
            docs.appendingPathComponent(filename)
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }?.path
    }
}
