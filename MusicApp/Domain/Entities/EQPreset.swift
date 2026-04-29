import Foundation

enum EQPreset: String, CaseIterable, Codable {
    case flat, bassBoost, pop, rock, classical, jazz, custom

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

    // Gains for [bass 60Hz, mid 1kHz, treble 14kHz] in dB
    var gains: [Float] {
        switch self {
        case .flat:      return [0, 0, 0]
        case .bassBoost: return [6, 0, 0]
        case .pop:       return [2, 4, 2]
        case .rock:      return [5, -2, 4]
        case .classical: return [3, 0, 3]
        case .jazz:      return [3, 2, 3]
        case .custom:    return [0, 0, 0]
        }
    }
}
