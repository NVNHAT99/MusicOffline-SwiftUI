import Foundation

final class AudioEditorStateReducer {
    func reduce(_ state: AudioEditorState, with action: AudioEditorStateAction) -> AudioEditorState {
        var s = state
        switch action {
        case .setDuration(let v):
            s.duration = v
            if s.trimEnd <= 0 { s.trimEnd = v }
        case .setWaveform(let w):
            s.waveform = w
        case .setWaveformLoading(let v):
            s.isLoadingWaveform = v
        case .setTrimStart(let v):
            // Keep at least 1s between handles.
            s.trimStart = min(max(0, v), max(0, s.trimEnd - 1))
        case .setTrimEnd(let v):
            s.trimEnd = max(s.trimStart + 1, min(s.duration, v))
        case .setFadeIn(let v):
            s.fadeIn = max(0, min(v, min(10, max(0, s.trimEnd - s.trimStart))))
        case .setFadeOut(let v):
            s.fadeOut = max(0, min(v, min(10, max(0, s.trimEnd - s.trimStart))))
        case .setNormalize(let v):
            s.normalize = v
        case .setNormalizeGain(let v):
            s.normalizeGain = v
        case .setExporting(let v):
            s.isExporting = v
        case .setExportProgress(let v):
            s.exportProgress = v
        case .setExportedURL(let v):
            s.exportedURL = v
        case .setErrorMessage(let v):
            s.errorMessage = v
        }
        return s
    }
}
