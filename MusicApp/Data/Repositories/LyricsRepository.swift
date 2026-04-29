import Foundation

final class LyricsRepository: LyricsRepositoryProtocol {

    private static let lyricsDir: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Lyrics", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func save(stem: String, content: String) throws {
        let url = fileURL(for: stem)
        // Try UTF-8 first; content arriving as String is already decoded
        guard let data = content.data(using: .utf8) else {
            throw LyricsRepositoryError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
    }

    func load(stem: String) -> String? {
        let url = fileURL(for: stem)
        guard let data = try? Data(contentsOf: url) else { return nil }
        // Attempt UTF-8, fall back to UTF-16
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16)
    }

    func delete(stem: String) {
        try? FileManager.default.removeItem(at: fileURL(for: stem))
    }

    private func fileURL(for stem: String) -> URL {
        Self.lyricsDir.appendingPathComponent("\(stem).lrc")
    }
}

enum LyricsRepositoryError: Error {
    case encodingFailed
}
