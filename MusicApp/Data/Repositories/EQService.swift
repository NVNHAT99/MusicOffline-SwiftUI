import AVFoundation

private enum Keys {
    static let preset = "eqPreset"
    static let gains  = "eqGains"
}

final class EQService: EQServiceProtocol {

    static let shared = EQService()

    let eqNode: AVAudioUnitEQ
    private(set) var currentPreset: EQPreset = .flat
    private(set) var currentGains: [Float] = [0, 0, 0]

    private static let frequencies: [Float] = [60, 1000, 14000]

    private init() {
        eqNode = AVAudioUnitEQ(numberOfBands: 3)
        eqNode.globalGain = 1

        for (i, freq) in Self.frequencies.enumerated() {
            let band = eqNode.bands[i]
            band.filterType = .parametric
            band.frequency  = freq
            band.bandwidth  = 1.0
            band.bypass     = false
            band.gain       = 0
        }

        restorePersistedState()
    }

    func applyPreset(_ preset: EQPreset) {
        let gains = preset == .custom ? currentGains : preset.gains
        for (i, g) in gains.enumerated() {
            eqNode.bands[i].gain = g
        }
        currentPreset = preset
        currentGains  = gains
        persist()
    }

    func setBandGain(index: Int, dB: Float) {
        guard eqNode.bands.indices.contains(index) else { return }
        eqNode.bands[index].gain = dB
        currentGains[index] = dB
        currentPreset = .custom
        persist()
    }

    func restorePersistedState() {
        if let raw = UserDefaults.standard.string(forKey: Keys.preset),
           let preset = EQPreset(rawValue: raw) {
            currentPreset = preset
        }
        if let saved = UserDefaults.standard.array(forKey: Keys.gains) as? [Float],
           saved.count == 3 {
            currentGains = saved
        } else {
            currentGains = currentPreset.gains
        }
        for (i, g) in currentGains.enumerated() {
            eqNode.bands[i].gain = g
        }
    }

    private func persist() {
        UserDefaults.standard.set(currentPreset.rawValue, forKey: Keys.preset)
        UserDefaults.standard.set(currentGains, forKey: Keys.gains)
    }
}
