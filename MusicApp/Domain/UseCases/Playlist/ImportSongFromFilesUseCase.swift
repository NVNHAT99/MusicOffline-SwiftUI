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

    init(addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase()) {
        self.addSongUseCase = addSongUseCase
    }

    func execute(urls: [URL], progressHandler: @escaping (Int, Int) -> Void) async -> [ImportSongResult] {
        let musicDir = Self.musicDirectory()
        var results: [ImportSongResult] = []

        for (index, url) in urls.enumerated() {
            let fileName = url.lastPathComponent
            let ext = url.pathExtension.lowercased()

            guard Self.supportedExtensions.contains(ext) else {
                results.append(ImportSongResult(fileName: fileName, success: false, error: .unsupportedFormat(ext)))
                progressHandler(index + 1, urls.count)
                continue
            }

            do {
                let destURL = try Self.copyFile(from: url, to: musicDir)
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

    private static func musicDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let musicDir = docs.appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: musicDir, withIntermediateDirectories: true)
        return musicDir
    }

    private static func copyFile(from sourceURL: URL, to directory: URL) throws -> URL {
        // Access security-scoped resource from Files app picker
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        let destURL = directory.appendingPathComponent(sourceURL.lastPathComponent)

        // Skip copy if identical file already exists (same name = treated as duplicate)
        if FileManager.default.fileExists(atPath: destURL.path) {
            return destURL
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            throw ImportSongError.fileCopyFailed(sourceURL.lastPathComponent, error)
        }

        return destURL
    }
}
