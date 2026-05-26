import AVFoundation

protocol ComputeNormalizationGainUseCaseProtocol {
    /// Returns the linear gain multiplier that would bring the source's peak
    /// to ~0.95 of full scale. Clamped to [0.5, 3.0] so we never blow up
    /// already-loud sources or apply runaway gain to near-silent ones.
    func execute(url: URL) async throws -> Float
}

final class ComputeNormalizationGainUseCase: ComputeNormalizationGainUseCaseProtocol {

    func execute(url: URL) async throws -> Float {
        try await Task.detached(priority: .userInitiated) {
            try Self.computePeakGain(url: url)
        }.value
    }

    private static func computePeakGain(url: URL) throws -> Float {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16_384) else { return 1.0 }
        var peak: Float = 0
        while file.framePosition < file.length {
            try file.read(into: buf, frameCount: 16_384)
            let frames = Int(buf.frameLength)
            guard frames > 0, let data = buf.floatChannelData else { break }
            for c in 0..<Int(format.channelCount) {
                for i in 0..<frames {
                    let v = abs(data[c][i])
                    if v > peak { peak = v }
                }
            }
        }
        guard peak > 0.0001 else { return 1.0 }
        return min(3.0, max(0.5, 0.95 / peak))
    }
}
