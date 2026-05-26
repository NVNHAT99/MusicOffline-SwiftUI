import Foundation

/// Stores .lrc lyric files in Documents/Lyrics/ keyed by song filename stem.
/// Lookup uses a fallback chain so user-friendly mismatches still resolve:
///   exact → case-insensitive → normalized (diacritics + space/underscore/dash collapsed).
/// Ambiguous normalized matches (2+ files map to same key) return nil + log warning
/// so the user can attach manually via the NowPlaying menu instead of loading the wrong file.
final class LyricsRepository: LyricsRepositoryProtocol {

    private static let lyricsDir: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Lyrics", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Maps normalized stem → list of on-disk stems sharing that key.
    /// Single-entry list = unambiguous hit. Multi-entry = ambiguous (return nil).
    private var normalizedIndex: [String: [String]] = [:]
    private let indexQueue = DispatchQueue(label: "lyrics.repository.index")

    init() {
        rebuildIndex()
    }

    func save(stem: String, content: String) throws {
        let url = fileURL(for: stem)
        guard let data = content.data(using: .utf8) else {
            throw LyricsRepositoryError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
        indexQueue.sync { addToIndex(stem: stem) }
    }

    func load(stem: String) -> String? {
        // 1. Exact match
        if let data = try? Data(contentsOf: fileURL(for: stem)) {
            return decode(data)
        }
        // 2. Case-insensitive + normalized fallback via index
        guard let resolved = resolveOnDiskStem(forLookup: stem) else { return nil }
        guard let data = try? Data(contentsOf: fileURL(for: resolved)) else { return nil }
        Logger.debug("[Lyrics] resolved '\(stem)' → '\(resolved)' via normalized match")
        return decode(data)
    }

    func delete(stem: String) {
        try? FileManager.default.removeItem(at: fileURL(for: stem))
        indexQueue.sync { removeFromIndex(stem: stem) }
    }

    // MARK: - Index

    private func rebuildIndex() {
        indexQueue.sync {
            normalizedIndex.removeAll()
            let fm = FileManager.default
            guard let entries = try? fm.contentsOfDirectory(at: Self.lyricsDir, includingPropertiesForKeys: nil) else { return }
            for url in entries where url.pathExtension.lowercased() == "lrc" {
                addToIndex(stem: url.deletingPathExtension().lastPathComponent)
            }
        }
    }

    private func addToIndex(stem: String) {
        let key = Self.normalize(stem)
        var list = normalizedIndex[key] ?? []
        if !list.contains(stem) { list.append(stem) }
        normalizedIndex[key] = list
    }

    private func removeFromIndex(stem: String) {
        let key = Self.normalize(stem)
        guard var list = normalizedIndex[key] else { return }
        list.removeAll { $0 == stem }
        if list.isEmpty { normalizedIndex.removeValue(forKey: key) }
        else { normalizedIndex[key] = list }
    }

    private func resolveOnDiskStem(forLookup stem: String) -> String? {
        let key = Self.normalize(stem)
        return indexQueue.sync {
            let list = normalizedIndex[key] ?? []
            if list.count == 1 { return list[0] }
            if list.count > 1 {
                Logger.debug("[Lyrics] ambiguous match for '\(stem)' (norm=\(key)) → \(list); returning nil. User should attach manually.")
                return nil
            }
            return nil
        }
    }

    // MARK: - Normalize

    /// Lowercase + strip diacritics + collapse [\s_-]+ → "".
    /// Empty input → "" (will not match anything because index never stores empty stems).
    static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        var out = ""
        out.reserveCapacity(folded.count)
        for ch in folded.unicodeScalars {
            if ch == " " || ch == "_" || ch == "-" || ch == "\u{00A0}" { continue }
            out.unicodeScalars.append(ch)
        }
        return out
    }

    // MARK: - Helpers

    private func fileURL(for stem: String) -> URL {
        Self.lyricsDir.appendingPathComponent("\(stem).lrc")
    }

    private func decode(_ data: Data) -> String? {
        String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16)
    }
}

enum LyricsRepositoryError: Error {
    case encodingFailed
}
