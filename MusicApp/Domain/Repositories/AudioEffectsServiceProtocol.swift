import AVFoundation

protocol AudioEffectsServiceProtocol: AnyObject {
    var timePitchNode: AVAudioUnitTimePitch { get }
    var reverbNode: AVAudioUnitReverb { get }

    var speed: Float { get }            // 0.5 – 2.0, 1.0 = neutral
    var pitchSemitones: Float { get }   // -12…+12, 0 = neutral
    var reverbPreset: ReverbPreset { get }
    var reverbWetDryMix: Float { get }  // 0…100
    var reverbBypassed: Bool { get }

    func setSpeed(_ rate: Float)
    func setPitch(semitones: Float)
    func setReverbPreset(_ preset: ReverbPreset)
    func setReverbWetDryMix(_ mix: Float)
    func setReverbBypass(_ on: Bool)
    func resetAll()
}
