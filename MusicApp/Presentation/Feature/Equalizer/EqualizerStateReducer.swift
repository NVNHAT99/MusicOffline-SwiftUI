import Foundation

final class EqualizerStateReducer {

    func reduce(_ state: EqualizerState, with action: EqualizerStateAction) -> EqualizerState {
        var s = state
        switch action {
        case .setTab(let tab):
            s.tab = tab
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
        case .setUserPresets(let list):
            s.userPresets = list
        case .setBypassed(let on):
            s.isBypassed = on
        case .setShowSaveSheet(let show):
            s.showSavePresetSheet = show
        case .setErrorMessage(let msg):
            s.errorMessage = msg
        case .setSpeed(let v):
            s.speed = v
        case .setPitch(let v):
            s.pitchSemitones = v
        case .setReverbPreset(let p):
            s.reverbPreset = p
        case .setReverbWetDryMix(let m):
            s.reverbWetDryMix = m
        case .setReverbBypassed(let b):
            s.reverbBypassed = b
        }
        return s
    }
}
