import Foundation

enum EqualizerStateAction {
    case setPreset(EQPreset)
    case setGains([Float])
    case setBandGain(index: Int, dB: Float)
}
