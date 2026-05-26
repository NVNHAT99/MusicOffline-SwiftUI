import AVFoundation

protocol ScanWaveformUseCaseProtocol {
    /// Returns peak amplitudes per bucket, normalized to [0…1].
    func execute(url: URL, buckets: Int) async throws -> [Float]
}

/// Streams audio file frames in chunks, computes per-bucket peak, returns a
/// compact array suitable for rendering a waveform view (~200–300 points).
/// Runs on a background queue; output is fine to render on main.
final class ScanWaveformUseCase: ScanWaveformUseCaseProtocol {

    func execute(url: URL, buckets: Int) async throws -> [Float] {
        try await Task.detached(priority: .userInitiated) {
            try Self.scan(url: url, buckets: buckets)
        }.value
    }

    private static func scan(url: URL, buckets: Int) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let totalFrames = file.length
        guard totalFrames > 0, buckets > 0 else { return [] }

        let framesPerBucket = max(1, Int(totalFrames) / buckets)
        let format = file.processingFormat
        let chunkCapacity = AVAudioFrameCount(min(framesPerBucket, 8192))
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkCapacity) else { return [] }

        var peaks: [Float] = []
        peaks.reserveCapacity(buckets)
        var framesRead: Int = 0
        var bucketMax: Float = 0
        var globalMax: Float = 0.0001

        while file.framePosition < totalFrames {
            try file.read(into: buf, frameCount: chunkCapacity)
            let frames = Int(buf.frameLength)
            guard frames > 0, let channelData = buf.floatChannelData else { break }

            // Mono fold by averaging channels into a per-frame magnitude.
            let channelCount = Int(format.channelCount)
            for i in 0..<frames {
                var sum: Float = 0
                for c in 0..<channelCount {
                    sum += abs(channelData[c][i])
                }
                let avg = sum / Float(channelCount)
                if avg > bucketMax { bucketMax = avg }

                framesRead += 1
                if framesRead >= framesPerBucket {
                    peaks.append(bucketMax)
                    if bucketMax > globalMax { globalMax = bucketMax }
                    bucketMax = 0
                    framesRead = 0
                    if peaks.count >= buckets { break }
                }
            }
            if peaks.count >= buckets { break }
        }
        // Flush last partial bucket if room remains.
        if peaks.count < buckets && framesRead > 0 {
            peaks.append(bucketMax)
            if bucketMax > globalMax { globalMax = bucketMax }
        }
        // Normalize to [0..1] using observed global max — keeps relative dynamics.
        return peaks.map { $0 / globalMax }
    }
}
