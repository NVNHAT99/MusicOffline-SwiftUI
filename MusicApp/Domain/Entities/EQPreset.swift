import Foundation

/// Built-in 10-band parametric EQ presets.
/// Gains are in dB, indexed by `EQPreset.bandFrequencies` order:
///   [31, 62, 125, 250, 500, 1k, 2k, 4k, 8k, 16k] Hz
enum EQPreset: String, CaseIterable, Codable {
    case flat, bassBoost, pop, rock, classical, jazz, custom

    /// ISO standard 10-band center frequencies (Hz).
    static let bandFrequencies: [Float] = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

    /// Number of bands — always 10 for v2.
    static let bandCount: Int = 10

    var displayName: String {
        switch self {
        case .flat:      return "Flat"
        case .bassBoost: return "Bass Boost"
        case .pop:       return "Pop"
        case .rock:      return "Rock"
        case .classical: return "Classical"
        case .jazz:      return "Jazz"
        case .custom:    return "Custom"
        }
    }

    /// Returns a 10-element gain vector in dB. Values tuned to feel familiar
    /// from common consumer EQ apps; safe range -12…+12.
    var gains: [Float] {
        switch self {
        case .flat:
            return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        case .bassBoost:
            return [6, 5, 4, 2, 0, 0, 0, 0, 0, 0]
        case .pop:
            return [-1, 0, 2, 4, 4, 2, 0, -1, -1, -1]
        case .rock:
            return [5, 4, 3, 1, -1, -1, 0, 2, 3, 4]
        case .classical:
            return [3, 3, 2, 0, 0, 0, -1, 2, 3, 3]
        case .jazz:
            return [2, 2, 1, 2, -1, -1, 0, 1, 2, 3]
        case .custom:
            return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        }
    }
}
