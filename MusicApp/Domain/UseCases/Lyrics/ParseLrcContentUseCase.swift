import Foundation

/// Parses LRC file content into sorted LyricsLine array.
/// Handles: single/multi timestamps per line, metadata tags (skipped), blank lines, malformed lines.
final class ParseLrcContentUseCase {

    // Matches [mm:ss.xx] or [mm:ss:xx] — captures minutes, seconds, optional centiseconds
    private static let timestampRegex = try! NSRegularExpression(
        pattern: #"\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]"#
    )
    // Metadata tags to skip
    private static let metadataPrefixes = ["ar:", "ti:", "al:", "by:", "offset:", "length:", "re:", "ve:"]

    func execute(content: String) -> [LyricsLine] {
        var lines: [LyricsLine] = []

        for rawLine in content.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Skip metadata tags like [ar:Artist]
            if isMetadataLine(trimmed) { continue }

            let timestamps = extractTimestamps(from: trimmed)
            guard !timestamps.isEmpty else { continue }

            // Strip all timestamp brackets to get lyric text
            let text = Self.timestampRegex
                .stringByReplacingMatches(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed), withTemplate: "")
                .trimmingCharacters(in: .whitespaces)

            for ts in timestamps {
                lines.append(LyricsLine(timestamp: ts, text: text))
            }
        }

        return lines.sorted { $0.timestamp < $1.timestamp }
    }

    private func isMetadataLine(_ line: String) -> Bool {
        // e.g. [ar:SomeArtist] — check after first '['
        guard line.hasPrefix("[") else { return false }
        let inner = line.dropFirst()
        return Self.metadataPrefixes.contains(where: { inner.lowercased().hasPrefix($0) })
    }

    private func extractTimestamps(from line: String) -> [TimeInterval] {
        let nsLine = line as NSString
        let matches = Self.timestampRegex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        return matches.compactMap { match -> TimeInterval? in
            guard let minutesRange = Range(match.range(at: 1), in: line),
                  let secondsRange = Range(match.range(at: 2), in: line),
                  let minutes = Double(line[minutesRange]),
                  let seconds = Double(line[secondsRange]) else { return nil }

            var ms: Double = 0
            if match.range(at: 3).location != NSNotFound,
               let msRange = Range(match.range(at: 3), in: line),
               let msVal = Double(line[msRange]) {
                // normalize: 1→0.1, 12→0.12, 123→0.123
                ms = msVal / pow(10, Double(line[msRange].count))
            }
            return minutes * 60 + seconds + ms
        }
    }
}
