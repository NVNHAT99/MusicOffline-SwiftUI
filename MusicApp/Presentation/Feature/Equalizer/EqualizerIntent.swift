import Foundation

enum EqualizerIntent {
    case selectTab(EqualizerTab)

    // EQ
    case selectPreset(EQPreset)
    case selectUserPreset(UserEQPreset)
    case setBandGain(index: Int, dB: Float)
    case resetGains
    case toggleBypass
    case presentSaveSheet(Bool)
    case saveCurrentAsPreset(name: String)
    case deleteUserPreset(id: UUID)
    case dismissError

    // Effects
    case setSpeed(Float)
    case setPitch(Float)
    case selectReverbPreset(ReverbPreset)
    case setReverbWetDryMix(Float)
    case resetEffects
}
