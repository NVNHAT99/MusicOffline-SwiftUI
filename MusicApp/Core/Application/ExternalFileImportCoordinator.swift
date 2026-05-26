import Foundation
import Combine

/// Funnels every "file arrived from outside" route — AirDrop, Open-in,
/// iTunes File Sharing — into the same `ImportSongFromFilesUseCase` so we get
/// consistent error handling, deduplication, and toast feedback.
///
/// Emits a single notification (`.externalImportFinished`) carrying an
/// `ExternalImportSummary` so any view can listen and surface UI.
@MainActor
final class ExternalFileImportCoordinator {

    static let shared = ExternalFileImportCoordinator()

    private let importUseCase: ImportSongFromFilesUseCaseProtocol
    private var inFlight = false

    init(importUseCase: ImportSongFromFilesUseCaseProtocol = ImportSongFromFilesUseCase()) {
        self.importUseCase = importUseCase
    }

    /// Called from `onOpenURL`. The URL is a single file iOS handed us.
    func handle(openURL url: URL) {
        importBatch(urls: [url])
    }

    /// Scans the Documents root for loose audio files dropped via Finder /
    /// Files.app and imports them, skipping anything we already own.
    func scanDocumentsRootAndImport() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        // Skip our own managed subfolders.
        let managed: Set<String> = ["Music", "Lyrics", "Inbox"]
        guard let entries = try? fm.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) else { return }
        let audioExts: Set<String> = ["mp3", "m4a", "wav", "flac", "aac", "ogg"]
        let candidates = entries.filter {
            !managed.contains($0.lastPathComponent) &&
            $0.hasDirectoryPath == false &&
            audioExts.contains($0.pathExtension.lowercased())
        }
        guard !candidates.isEmpty else { return }
        importBatch(urls: candidates)
    }

    // MARK: - Private

    private func importBatch(urls: [URL]) {
        guard !urls.isEmpty, !inFlight else { return }
        inFlight = true
        Task { [weak self] in
            guard let self else { return }
            let results = await importUseCase.execute(urls: urls) { _, _ in }
            let succeeded = results.filter { $0.success }.count
            let failed = results.count - succeeded
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .externalImportFinished,
                    object: ExternalImportSummary(succeeded: succeeded, failed: failed)
                )
                self.inFlight = false
            }
        }
    }
}

struct ExternalImportSummary {
    let succeeded: Int
    let failed: Int
}

extension Notification.Name {
    static let externalImportFinished = Notification.Name("externalImportFinished")
}
