import Foundation

final class EqualizerStateReducer {

    func reduce(_ state: EqualizerState, with action: EqualizerStateAction) -> EqualizerState {
        var s = state
        switch action {
        case .setPreset(let preset):
            s.preset = preset
            if preset != .custom {
                s.gains = preset.gains
            }
        case .setGains(let gains):
            s.gains = gains
        case .setBandGain(let index, let dB):
            guard s.gains.indices.contains(index) else { break }
            s.gains[index] = dB
            s.preset = .custom
        }
        return s
    }
}
