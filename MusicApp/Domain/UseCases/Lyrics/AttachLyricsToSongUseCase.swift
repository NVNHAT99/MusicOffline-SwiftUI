import Foundation

/// Attaches lyric content (raw .lrc text) to a song by its filename stem.
/// Used by the NowPlaying Attach/Paste Lyrics flows where we want lyrics
/// to bind to the *exact* on-disk stem of the currently-playing track,
/// bypassing any normalized-match ambiguity.
protocol AttachLyricsToSongUseCaseProtocol {
    func executeFromFile(url: URL, stem: String) throws
    func executeFromText(content: String, stem: String) throws
}

final class AttachLyricsToSongUseCase: AttachLyricsToSongUseCaseProtocol {

    private let repository: LyricsRepositoryProtocol

    init(repository: LyricsRepositoryProtocol = LyricsRepository()) {
        self.repository = repository
    }

    func executeFromFile(url: URL, stem: String) throws {
        let content = try Self.readText(from: url)
        try repository.save(stem: stem, content: content)
    }

    func executeFromText(content: String, stem: String) throws {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AttachLyricsError.emptyContent
        }
        try repository.save(stem: stem, content: trimmed)
    }

    private static func readText(from url: URL) throws -> String {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
            throw AttachLyricsError.unreadableFile
        }
        return text
    }
}

enum AttachLyricsError: LocalizedError {
    case emptyContent
    case unreadableFile

    var errorDescription: String? {
        switch self {
        case .emptyContent:   return "Lyrics content is empty"
        case .unreadableFile: return "Could not read the selected lyrics file"
        }
    }
}
