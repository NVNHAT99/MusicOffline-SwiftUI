import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

protocol ExportEditedAudioUseCaseProtocol {
    /// Exports the trimmed + faded + normalized clip as M4A (AAC) into
    /// `Documents/Music/`. Reports fractional progress (0…1) on the main actor.
    /// Returns the destination URL once written.
    func execute(
        config: AudioEditConfig,
        normalizeGain: Float,
        onProgress: @escaping @MainActor (Float) -> Void
    ) async throws -> URL
}

enum ExportEditedAudioError: LocalizedError {
    case invalidRange
    case noAudioTrack
    case sessionCreationFailed
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidRange:          return "Trim range is invalid (start must be before end, ≥1s)"
        case .noAudioTrack:          return "Source file has no audio track"
        case .sessionCreationFailed: return "Could not create export session"
        case .exportFailed(let m):   return "Export failed: \(m)"
        }
    }
}

final class ExportEditedAudioUseCase: ExportEditedAudioUseCaseProtocol {

    private static let musicDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func execute(
        config: AudioEditConfig,
        normalizeGain: Float,
        onProgress: @escaping @MainActor (Float) -> Void
    ) async throws -> URL {
        guard config.trimDuration >= 1.0 else { throw ExportEditedAudioError.invalidRange }

        let asset = AVURLAsset(url: config.sourceURL)
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw ExportEditedAudioError.noAudioTrack
        }

        // 1. Composition holding the trimmed segment.
        let composition = AVMutableComposition()
        guard let compTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw ExportEditedAudioError.sessionCreationFailed
        }
        let timescale: CMTimeScale = 600
        let startCM = CMTime(seconds: config.trimStart, preferredTimescale: timescale)
        let endCM   = CMTime(seconds: config.trimEnd,   preferredTimescale: timescale)
        let range   = CMTimeRange(start: startCM, end: endCM)
        try compTrack.insertTimeRange(range, of: audioTrack, at: .zero)

        // 2. Audio mix — base volume + fade ramps. Timeline below is in the
        //    *composition* coordinate space (which starts at 0 after the trim).
        let mix = AVMutableAudioMix()
        let params = AVMutableAudioMixInputParameters(track: compTrack)
        let baseVolume: Float = config.normalize ? normalizeGain : 1.0
        params.setVolume(baseVolume, at: .zero)
        let total = config.trimDuration

        if config.fadeIn > 0 {
            let fadeInEnd = CMTime(seconds: min(config.fadeIn, total), preferredTimescale: timescale)
            params.setVolumeRamp(
                fromStartVolume: 0,
                toEndVolume: baseVolume,
                timeRange: CMTimeRange(start: .zero, end: fadeInEnd)
            )
        }
        if config.fadeOut > 0 {
            let fadeOutStart = CMTime(seconds: max(0, total - config.fadeOut), preferredTimescale: timescale)
            let fadeOutEnd   = CMTime(seconds: total, preferredTimescale: timescale)
            params.setVolumeRamp(
                fromStartVolume: baseVolume,
                toEndVolume: 0,
                timeRange: CMTimeRange(start: fadeOutStart, end: fadeOutEnd)
            )
        }
        mix.inputParameters = [params]

        // 3. Output URL — uniquified inside Documents/Music/.
        let destURL = Self.uniqueURL(forTitle: config.outputTitle, extension: "m4a")

        guard let session = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw ExportEditedAudioError.sessionCreationFailed
        }
        session.outputURL = destURL
        session.outputFileType = .m4a
        session.audioMix = mix

        // 4. Background task — survives short backgrounding during export.
        #if canImport(UIKit)
        let bgTaskId = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: "ExportEditedAudio")
        }
        defer {
            Task { @MainActor in
                UIApplication.shared.endBackgroundTask(bgTaskId)
            }
        }
        #endif

        // 5. Progress polling.
        let progressTask = Task { @MainActor [weak session] in
            while let s = session, s.status == .waiting || s.status == .exporting {
                onProgress(s.progress)
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }

        await session.export()
        progressTask.cancel()
        await MainActor.run { onProgress(1.0) }

        switch session.status {
        case .completed:
            return destURL
        case .failed, .cancelled:
            try? FileManager.default.removeItem(at: destURL)
            throw ExportEditedAudioError.exportFailed(session.error?.localizedDescription ?? "unknown")
        default:
            try? FileManager.default.removeItem(at: destURL)
            throw ExportEditedAudioError.exportFailed("unexpected state")
        }
    }

    // MARK: - Helpers

    private static func uniqueURL(forTitle title: String, extension ext: String) -> URL {
        let sanitized = sanitize(title)
        var candidate = musicDirectory.appendingPathComponent("\(sanitized).\(ext)")
        var n = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = musicDirectory.appendingPathComponent("\(sanitized) (\(n)).\(ext)")
            n += 1
        }
        return candidate
    }

    private static func sanitize(_ s: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?*\"<>|")
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.components(separatedBy: invalid).joined(separator: "_")
        return cleaned.isEmpty ? "EditedTrack" : cleaned
    }
}
