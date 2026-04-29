import Foundation

struct EqualizerState {
    var preset: EQPreset = .flat
    var gains: [Float] = [0, 0, 0]

    static let bandNames = ["Bass", "Mid", "Treble"]
}
