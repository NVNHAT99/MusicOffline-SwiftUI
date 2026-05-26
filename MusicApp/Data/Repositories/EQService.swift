import AVFoundation

private enum Keys {
    static let preset   = "eqPreset"
    static let gainsV2  = "eqGainsV2"      // length-10 gains (v2)
    static let gainsV1  = "eqGains"        // legacy length-3 gains (v1) — read-once-then-clear
    static let bypass   = "eqBypassed"
}

/// 10-band parametric EQ.
/// Graph: band 0 = .lowShelf @ 31 Hz, bands 1…8 = .parametric, band 9 = .highShelf @ 16 kHz.
/// All bandwidths default to 1.0 octave — wide enough to feel musical, narrow enough to shape.
final class EQService: EQServiceProtocol {

    static let shared = EQService()

    let eqNode: AVAudioUnitEQ
    private(set) var currentPreset: EQPreset = .flat
    private(set) var currentGains: [Float] = Array(repeating: 0, count: EQPreset.bandCount)
    private(set) var isBypassed: Bool = false

    private init() {
        eqNode = AVAudioUnitEQ(numberOfBands: EQPreset.bandCount)
        eqNode.globalGain = 1
        configureBands()
        migrateLegacyGainsIfNeeded()
        restorePersistedState()
    }

    private func configureBands() {
        for (i, freq) in EQPreset.bandFrequencies.enumerated() {
            let band = eqNode.bands[i]
            switch i {
            case 0:                        band.filterType = .lowShelf
            case EQPreset.bandCount - 1:   band.filterType = .highShelf
            default:                       band.filterType = .parametric
            }
            band.frequency = freq
            band.bandwidth = 1.0
            band.bypass    = false
            band.gain      = 0
        }
    }

    func applyPreset(_ preset: EQPreset) {
        let gains = preset == .custom ? currentGains : preset.gains
        applyGainsToHardware(gains)
        currentPreset = preset
        currentGains  = gains
        persist()
    }

    func setBandGain(index: Int, dB: Float) {
        guard eqNode.bands.indices.contains(index) else { return }
        eqNode.bands[index].gain = dB
        if currentGains.indices.contains(index) {
            currentGains[index] = dB
        }
        currentPreset = .custom
        persist()
    }

    /// Apply an arbitrary gain vector (e.g. when loading a UserEQPreset).
    /// Length must equal `EQPreset.bandCount`; mismatched input is ignored.
    func applyCustomGains(_ gains: [Float]) {
        guard gains.count == EQPreset.bandCount else { return }
        applyGainsToHardware(gains)
        currentGains = gains
        currentPreset = .custom
        persist()
    }

    func setBypass(_ on: Bool) {
        isBypassed = on
        eqNode.bypass = on
        UserDefaults.standard.set(on, forKey: Keys.bypass)
    }

    func restorePersistedState() {
        if let raw = UserDefaults.standard.string(forKey: Keys.preset),
           let preset = EQPreset(rawValue: raw) {
            currentPreset = preset
        }
        if let saved = UserDefaults.standard.array(forKey: Keys.gainsV2) as? [Float],
           saved.count == EQPreset.bandCount {
            currentGains = saved
        } else {
            currentGains = currentPreset.gains
        }
        isBypassed = UserDefaults.standard.bool(forKey: Keys.bypass)
        applyGainsToHardware(currentGains)
        eqNode.bypass = isBypassed
    }

    // MARK: - v1 → v2 migration

    /// Reads the legacy 3-band gain vector (if present) and projects it onto the 10-band layout:
    ///   bass(60Hz)  → 31, 62, 125 Hz
    ///   mid(1kHz)   → 250, 500, 1k, 2k Hz
    ///   treble(14k) → 4k, 8k, 16k Hz
    /// Linear assignment (no interpolation) is good enough — preserves the user's "shape" intent.
    /// Runs once; deletes the legacy key on success.
    private func migrateLegacyGainsIfNeeded() {
        // Already migrated?
        if UserDefaults.standard.array(forKey: Keys.gainsV2) != nil { return }
        guard let legacy = UserDefaults.standard.array(forKey: Keys.gainsV1) as? [Float],
              legacy.count == 3 else { return }
        let bass   = legacy[0]
        let mid    = legacy[1]
        let treble = legacy[2]
        let migrated: [Float] = [bass, bass, bass, mid, mid, mid, mid, treble, treble, treble]
        UserDefaults.standard.set(migrated, forKey: Keys.gainsV2)
        UserDefaults.standard.removeObject(forKey: Keys.gainsV1)
    }

    // MARK: - Private

    private func applyGainsToHardware(_ gains: [Float]) {
        for (i, g) in gains.enumerated() where eqNode.bands.indices.contains(i) {
            eqNode.bands[i].gain = g
        }
    }

    private func persist() {
        UserDefaults.standard.set(currentPreset.rawValue, forKey: Keys.preset)
        UserDefaults.standard.set(currentGains, forKey: Keys.gainsV2)
    }
}
