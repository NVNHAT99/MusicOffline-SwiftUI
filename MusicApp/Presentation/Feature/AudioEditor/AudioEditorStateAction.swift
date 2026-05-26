import Foundation

enum AudioEditorStateAction {
    case setDuration(Double)
    case setWaveform([Float])
    case setWaveformLoading(Bool)
    case setTrimStart(Double)
    case setTrimEnd(Double)
    case setFadeIn(Double)
    case setFadeOut(Double)
    case setNormalize(Bool)
    case setNormalizeGain(Float)
    case setExporting(Bool)
    case setExportProgress(Float)
    case setExportedURL(URL?)
    case setErrorMessage(String?)
}
