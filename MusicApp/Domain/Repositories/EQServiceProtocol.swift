import AVFoundation

protocol EQServiceProtocol: AnyObject {
    var eqNode: AVAudioUnitEQ { get }
    var currentPreset: EQPreset { get }
    var currentGains: [Float] { get }
    var isBypassed: Bool { get }

    func applyPreset(_ preset: EQPreset)
    func setBandGain(index: Int, dB: Float)
    func applyCustomGains(_ gains: [Float])
    func setBypass(_ on: Bool)
    func restorePersistedState()
}
