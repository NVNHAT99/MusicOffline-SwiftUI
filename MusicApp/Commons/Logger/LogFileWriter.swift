//
//  LogFileWriter.swift
//  MusicApp
//
//  Appends log lines to a rotating file in Documents so a debug build can
//  export them via the Settings "Share Log File" action. Debug-only: the
//  file sink is compiled out of release builds to avoid persisting anything.
//

import Foundation

#if DEBUG
/// Thread-safe file sink for the app's Logger. Writes plain-text lines (no
/// ANSI color codes) to Documents/app-debug.log, trimming the head when the
/// file grows past a cap so it never balloons on device.
final class LogFileWriter {
    static let shared = LogFileWriter()

    /// Where the exportable log lives. Documents so it's reachable by the
    /// Files app and shareable via UIActivityViewController.
    let fileURL: URL

    private let queue = DispatchQueue(label: "com.musicapp.logfile", qos: .utility)
    private let maxBytes = 2_000_000 // ~2 MB cap before trimming the oldest half.

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("app-debug.log")
    }

    func append(_ line: String) {
        queue.async { [weak self] in
            guard let self else { return }
            let entry = line + "\n"
            guard let data = entry.data(using: .utf8) else { return }

            if let handle = try? FileHandle(forWritingTo: self.fileURL) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            } else {
                try? data.write(to: self.fileURL, options: .atomic)
            }
            self.trimIfNeeded()
        }
    }

    /// Empty the log (used by Settings before starting a fresh capture).
    func clear() {
        queue.async { [weak self] in
            guard let self else { return }
            try? Data().write(to: self.fileURL, options: .atomic)
        }
    }

    private func trimIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attrs[.size] as? Int, size > maxBytes,
              let data = try? Data(contentsOf: fileURL) else { return }
        // Keep the most recent half so the newest events (the ones being
        // debugged) always survive the trim.
        let half = data.suffix(data.count / 2)
        try? half.write(to: fileURL, options: .atomic)
    }
}
#endif
