import AVFoundation

private enum Keys {
    static let speed         = "fxSpeed"
    static let pitch         = "fxPitchCents"
    static let reverbPreset  = "fxReverbPreset"
    static let reverbWetDry  = "fxReverbWetDry"
    static let reverbBypass  = "fxReverbBypass"
}

/// Owns the `AVAudioUnitTimePitch` and `AVAudioUnitReverb` nodes that sit
/// between the player and the EQ in the audio graph:
///     player → timePitch → reverb → eq → mainMixer
///
/// Both nodes are attached up-front and toggled via `.bypass` so we never have
/// to stop/start the engine at runtime (which would cause an audible pop).
/// TimePitch is bypassed iff speed == 1.0 AND pitch == 0 (it's a single node
/// carrying both parameters).
final class AudioEffectsService: AudioEffectsServiceProtocol {

    static let shared = AudioEffectsService()

    let timePitchNode = AVAudioUnitTimePitch()
    let reverbNode    = AVAudioUnitReverb()

    private(set) var speed: Float = 1.0
    private(set) var pitchSemitones: Float = 0.0
    private(set) var reverbPreset: ReverbPreset = .mediumHall
    private(set) var reverbWetDryMix: Float = 0.0
    private(set) var reverbBypassed: Bool = true

    private init() {
        restorePersistedState()
        applyAll()
    }

    func setSpeed(_ rate: Float) {
        speed = clamp(rate, min: 0.5, max: 2.0)
        timePitchNode.rate = speed
        refreshTimePitchBypass()
        UserDefaults.standard.set(speed, forKey: Keys.speed)
    }

    func setPitch(semitones: Float) {
        pitchSemitones = clamp(semitones, min: -12, max: 12)
        timePitchNode.pitch = pitchSemitones * 100  // cents
        refreshTimePitchBypass()
        UserDefaults.standard.set(pitchSemitones, forKey: Keys.pitch)
    }

    func setReverbPreset(_ preset: ReverbPreset) {
        reverbPreset = preset
        reverbNode.loadFactoryPreset(preset.avPreset)
        UserDefaults.standard.set(preset.rawValue, forKey: Keys.reverbPreset)
    }

    func setReverbWetDryMix(_ mix: Float) {
        reverbWetDryMix = clamp(mix, min: 0, max: 100)
        reverbNode.wetDryMix = reverbWetDryMix
        // Auto-enable / disable based on mix amount so users don't get silently
        // surprised by reverb when they crank the slider.
        let shouldBypass = reverbWetDryMix < 0.5
        if shouldBypass != reverbBypassed {
            setReverbBypass(shouldBypass)
        } else {
            UserDefaults.standard.set(reverbWetDryMix, forKey: Keys.reverbWetDry)
        }
    }

    func setReverbBypass(_ on: Bool) {
        reverbBypassed = on
        reverbNode.bypass = on
        UserDefaults.standard.set(on, forKey: Keys.reverbBypass)
        UserDefaults.standard.set(reverbWetDryMix, forKey: Keys.reverbWetDry)
    }

    func resetAll() {
        setSpeed(1.0)
        setPitch(semitones: 0)
        setReverbWetDryMix(0)
        setReverbBypass(true)
    }

    // MARK: - Private

    private func refreshTimePitchBypass() {
        let neutral = (abs(speed - 1.0) < 0.001) && (abs(pitchSemitones) < 0.001)
        timePitchNode.bypass = neutral
    }

    private func applyAll() {
        timePitchNode.rate  = speed
        timePitchNode.pitch = pitchSemitones * 100
        refreshTimePitchBypass()
        reverbNode.loadFactoryPreset(reverbPreset.avPreset)
        reverbNode.wetDryMix = reverbWetDryMix
        reverbNode.bypass    = reverbBypassed
    }

    private func restorePersistedState() {
        let d = UserDefaults.standard
        if d.object(forKey: Keys.speed) != nil { speed = d.float(forKey: Keys.speed) }
        if d.object(forKey: Keys.pitch) != nil { pitchSemitones = d.float(forKey: Keys.pitch) }
        if let raw = d.object(forKey: Keys.reverbPreset) as? Int,
           let preset = ReverbPreset(rawValue: raw) {
            reverbPreset = preset
        }
        if d.object(forKey: Keys.reverbWetDry) != nil { reverbWetDryMix = d.float(forKey: Keys.reverbWetDry) }
        if d.object(forKey: Keys.reverbBypass) != nil { reverbBypassed = d.bool(forKey: Keys.reverbBypass) }
    }

    private func clamp(_ v: Float, min lo: Float, max hi: Float) -> Float {
        return max(lo, min(hi, v))
    }
}
