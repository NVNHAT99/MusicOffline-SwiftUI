import SwiftUI

// MARK: - AppFont
// Centralised typography. Sizes scale with Dynamic Type via `relativeTo:` so the
// UI respects the user's text-size setting (accessibility + App Store review).
// `design: .rounded` is preserved for the app's friendly look.

enum AppFont {
    static func largeTitle() -> Font { .system(.largeTitle, design: .rounded).weight(.bold) }
    static func title() -> Font { .system(.title2, design: .rounded).weight(.semibold) }
    static func headline() -> Font { .system(.headline) }
    static func body() -> Font { .system(.body) }
    static func callout() -> Font { .system(.subheadline) }
    static func caption() -> Font { .system(.caption) }
    static func tabLabel() -> Font { .system(.caption2) }

    // MARK: - Player specific
    static func songTitle() -> Font { .system(.headline) }
    static func artistName() -> Font { .system(.subheadline) }
    static func miniSongTitle() -> Font { .system(.callout).weight(.medium) }
    static func timeLabel() -> Font { .system(.caption) }

    // MARK: - Section headers
    static func sectionHeader() -> Font { .system(.title2, design: .rounded).weight(.semibold) }
}
