import SwiftUI

// MARK: - AppFont
// Centralised typography system — use these instead of inline .system(size:)

enum AppFont {
    static func largeTitle() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 18, weight: .semibold) }
    static func body() -> Font { .system(size: 16, weight: .regular) }
    static func callout() -> Font { .system(size: 14, weight: .regular) }
    static func caption() -> Font { .system(size: 12, weight: .regular) }
    static func tabLabel() -> Font { .system(size: 10, weight: .regular) }

    // MARK: - Player specific
    static func songTitle() -> Font { .system(size: 18, weight: .semibold) }
    static func artistName() -> Font { .system(size: 14, weight: .regular) }
    static func miniSongTitle() -> Font { .system(size: 16, weight: .medium) }
    static func timeLabel() -> Font { .system(size: 12, weight: .regular) }

    // MARK: - Section headers
    static func sectionHeader() -> Font { .system(size: 24, weight: .semibold, design: .rounded) }
}
