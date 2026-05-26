import Foundation

enum EqualizerTab: Int, CaseIterable {
    case eq, effects

    var title: String {
        switch self {
        case .eq:      return "EQ"
        case .effects: return "Effects"
        }
    }
}

struct EqualizerState {
    var tab: EqualizerTab = .eq

    // EQ
    var preset: EQPreset = .flat
    var gains: [Float] = Array(repeating: 0, count: EQPreset.bandCount)
    var userPresets: [UserEQPreset] = []
    var isBypassed: Bool = false
    var showSavePresetSheet: Bool = false
    var errorMessage: String? = nil

    // Effects
    var speed: Float = 1.0
    var pitchSemitones: Float = 0.0
    var reverbPreset: ReverbPreset = .mediumHall
    var reverbWetDryMix: Float = 0.0
    var reverbBypassed: Bool = true

    /// Short labels under each slider. Match `EQPreset.bandFrequencies`.
    static let bandLabels: [String] = ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
}
