//
//  ImportSongFromFilesUseCase.swift
//  MusicApp
//

import Foundation

enum ImportSongError: Error, LocalizedError {
    case unsupportedFormat(String)
    case fileCopyFailed(String, Error)
    case metadataLoadFailed(String, Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let name): return "Unsupported format: \(name)"
        case .fileCopyFailed(let name, _): return "Failed to copy: \(name)"
        case .metadataLoadFailed(let name, _): return "Failed to read metadata: \(name)"
        }
    }
}

struct ImportSongResult {
    let fileName: String
    let success: Bool
    let error: ImportSongError?
}

protocol ImportSongFromFilesUseCaseProtocol {
    func execute(urls: [URL], progressHandler: @escaping (Int, Int) -> Void) async -> [ImportSongResult]
}

final class ImportSongFromFilesUseCase: ImportSongFromFilesUseCaseProtocol {

    private static let supportedExtensions: Set<String> = ["mp3", "m4a", "wav", "flac", "aac", "ogg"]

    private let addSongUseCase: AddSongUseCaseProtocol
    private let lyricsRepository: LyricsRepositoryProtocol

    init(
        addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase(),
        lyricsRepository: LyricsRepositoryProtocol = LyricsRepository()
    ) {
        self.addSongUseCase = addSongUseCase
        self.lyricsRepository = lyricsRepository
    }

    func execute(urls: [URL], progressHandler: @escaping (Int, Int) -> Void) async -> [ImportSongResult] {
        let musicDir = Self.musicDirectory()
        var results: [ImportSongResult] = []

        for (index, url) in urls.enumerated() {
            let fileName = url.lastPathComponent
            let ext = url.pathExtension.lowercased()

            // Route .lrc files to lyrics storage
            if ext == "lrc" {
                let stem = url.deletingPathExtension().lastPathComponent
                do {
                    let content = try await Self.readTextFile(from: url)
                    try lyricsRepository.save(stem: stem, content: content)
                    results.append(ImportSongResult(fileName: fileName, success: true, error: nil))
                } catch {
                    results.append(ImportSongResult(fileName: fileName, success: false, error: .fileCopyFailed(fileName, error)))
                }
                progressHandler(index + 1, urls.count)
                continue
            }

            guard Self.supportedExtensions.contains(ext) else {
                results.append(ImportSongResult(fileName: fileName, success: false, error: .unsupportedFormat(ext)))
                progressHandler(index + 1, urls.count)
                continue
            }

            do {
                let destURL = try await Self.copyFile(from: url, to: musicDir)
                try await addSongUseCase.execute(from: destURL.path)
                results.append(ImportSongResult(fileName: fileName, success: true, error: nil))
            } catch let err as ImportSongError {
                results.append(ImportSongResult(fileName: fileName, success: false, error: err))
            } catch {
                results.append(ImportSongResult(fileName: fileName, success: false, error: .fileCopyFailed(fileName, error)))
            }

            progressHandler(index + 1, urls.count)
        }

        return results
    }

    // MARK: - Private

    private static func readTextFile(from url: URL) async throws -> String {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        try await ensureLocallyAvailable(url: url)
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
            throw ImportSongError.fileCopyFailed(url.lastPathComponent, NSError(
                domain: "Import", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not decode .lrc file"]
            ))
        }
        return text
    }

    private static func musicDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let musicDir = docs.appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: musicDir, withIntermediateDirectories: true)
        return musicDir
    }

    private static func copyFile(from sourceURL: URL, to directory: URL) async throws -> URL {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        // Materialize iCloud placeholder if not yet downloaded locally
        try await Self.ensureLocallyAvailable(url: sourceURL)

        let destURL = directory.appendingPathComponent(sourceURL.lastPathComponent)

        if FileManager.default.fileExists(atPath: destURL.path) {
            return destURL
        }

        // Use NSFileCoordinator for iCloud-safe read
        var copyError: Error?
        var coordinatorError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: sourceURL, options: .withoutChanges, error: &coordinatorError) { localURL in
            do {
                try FileManager.default.copyItem(at: localURL, to: destURL)
            } catch {
                copyError = error
            }
        }

        if let err = coordinatorError ?? copyError {
            throw ImportSongError.fileCopyFailed(sourceURL.lastPathComponent, err)
        }

        return destURL
    }

    /// Triggers download of iCloud placeholder files and polls until current
    /// (up to ~30s). Uses async sleep so the cooperative thread pool is not
    /// starved, and honours task cancellation.
    private static func ensureLocallyAvailable(url: URL) async throws {
        let resourceValues = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        guard let status = resourceValues.ubiquitousItemDownloadingStatus,
              status != .current else { return }

        try FileManager.default.startDownloadingUbiquitousItem(at: url)
        for _ in 0..<30 {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let updated = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            if updated.ubiquitousItemDownloadingStatus == .current { return }
        }
        throw ImportSongError.fileCopyFailed(url.lastPathComponent, NSError(
            domain: "iCloud", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "iCloud download timed out"]
        ))
    }
}
