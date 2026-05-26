import Foundation

/// All inputs needed to export an edited copy of a source audio file.
/// `trimStart` and `trimEnd` are absolute timestamps in seconds within the source.
struct AudioEditConfig: Equatable {
    let sourceURL: URL
    let trimStart: Double
    let trimEnd: Double
    let fadeIn: Double
    let fadeOut: Double
    let normalize: Bool
    let outputTitle: String

    var trimDuration: Double { max(0, trimEnd - trimStart) }
}
