//
//  DeleteSongUseCase.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/27/25.
//

import Foundation

protocol DeleteSongUseCaseProtocol {
    func executeList(_ pathFileElemets: [PathFileElement]) async throws
    func executeDeleteAll() async throws
    func execute(width path: String) async throws -> UUID
}

final class DeleteSongUseCase: DeleteSongUseCaseProtocol {
    let repository: SongRepositoryProtocol
    let documentFileService: DocumentFileServiceProtocol
    init(repository: SongRepositoryProtocol = SongRepository(),
         documentFileService: DocumentFileServiceProtocol = DocumentFileService()) {
        self.repository = repository
        self.documentFileService = documentFileService
    }

    func executeList(_ pathFileElemets: [PathFileElement]) async throws {
        try await repository.deleteSongs(with: pathFileElemets)
        for element in pathFileElemets {
            if let path = element.pathLocalFile {
                Self.removeFile(at: path)
            }
        }
    }

    func executeDeleteAll() async throws {
        try await repository.deleteAllSongs()
    }

    func execute(width path: String) async throws -> UUID {
        // Remove the DB row first; only orphan-delete the file once the row is
        // gone. C3 guarantees one path maps to one row, so no surviving row
        // references this file after the delete succeeds.
        let id = try await repository.deleteSong(withURL: path)
        Self.removeFile(at: path)
        return id
    }

    private static func removeFile(at path: String) {
        let fileURL: URL = path.hasPrefix("file://")
            ? (URL(string: path) ?? URL(fileURLWithPath: path))
            : URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            Logger.error("Failed to delete audio file at \(fileURL.lastPathComponent): \(error)")
        }
    }
}
