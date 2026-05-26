import Foundation

enum AudioEditorIntent {
    case onAppear
    case setTrimStart(Double)
    case setTrimEnd(Double)
    case setFadeIn(Double)
    case setFadeOut(Double)
    case setNormalize(Bool)
    case startExport
    case dismissError
}
