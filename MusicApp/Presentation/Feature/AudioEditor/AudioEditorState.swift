import Foundation

struct AudioEditorState {
    let sourceURL: URL
    let originalTitle: String
    var duration: Double = 0
    var waveform: [Float] = []
    var isLoadingWaveform: Bool = true

    // Trim
    var trimStart: Double = 0
    var trimEnd: Double = 0

    // Fade
    var fadeIn: Double = 0
    var fadeOut: Double = 0

    // Normalize
    var normalize: Bool = false
    var normalizeGain: Float = 1.0

    // Export
    var isExporting: Bool = false
    var exportProgress: Float = 0
    var exportedURL: URL? = nil
    var errorMessage: String? = nil
}
