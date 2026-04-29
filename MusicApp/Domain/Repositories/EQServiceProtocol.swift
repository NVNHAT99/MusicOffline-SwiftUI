import AVFoundation

protocol EQServiceProtocol: AnyObject {
    var eqNode: AVAudioUnitEQ { get }
    var currentPreset: EQPreset { get }
    var currentGains: [Float] { get }

    func applyPreset(_ preset: EQPreset)
    func setBandGain(index: Int, dB: Float)
    func restorePersistedState()
}
