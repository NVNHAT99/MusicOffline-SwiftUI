import AVFoundation

/// Codable mirror of `AVAudioUnitReverbPreset` so we can persist user selection.
enum ReverbPreset: Int, CaseIterable, Codable {
    case smallRoom    = 0
    case mediumRoom   = 1
    case largeRoom    = 2
    case mediumHall   = 3
    case largeHall    = 4
    case plate        = 5
    case mediumChamber = 6
    case largeChamber  = 7
    case cathedral    = 8
    case largeRoom2   = 9
    case mediumHall2  = 10
    case mediumHall3  = 11
    case largeHall2   = 12

    var displayName: String {
        switch self {
        case .smallRoom:     return "Small Room"
        case .mediumRoom:    return "Medium Room"
        case .largeRoom:     return "Large Room"
        case .mediumHall:    return "Medium Hall"
        case .largeHall:     return "Large Hall"
        case .plate:         return "Plate"
        case .mediumChamber: return "Medium Chamber"
        case .largeChamber:  return "Large Chamber"
        case .cathedral:     return "Cathedral"
        case .largeRoom2:    return "Large Room 2"
        case .mediumHall2:   return "Medium Hall 2"
        case .mediumHall3:   return "Medium Hall 3"
        case .largeHall2:    return "Large Hall 2"
        }
    }

    var avPreset: AVAudioUnitReverbPreset {
        AVAudioUnitReverbPreset(rawValue: rawValue) ?? .mediumHall
    }
}
