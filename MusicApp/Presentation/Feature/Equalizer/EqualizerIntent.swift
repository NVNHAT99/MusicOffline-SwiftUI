import Foundation

enum EqualizerIntent {
    case selectPreset(EQPreset)
    case setBandGain(index: Int, dB: Float)
}
