import Foundation

enum EqualizerStateAction {
    case setTab(EqualizerTab)

    case setPreset(EQPreset)
    case setGains([Float])
    case setBandGain(index: Int, dB: Float)
    case setUserPresets([UserEQPreset])
    case setBypassed(Bool)
    case setShowSaveSheet(Bool)
    case setErrorMessage(String?)

    case setSpeed(Float)
    case setPitch(Float)
    case setReverbPreset(ReverbPreset)
    case setReverbWetDryMix(Float)
    case setReverbBypassed(Bool)
}
