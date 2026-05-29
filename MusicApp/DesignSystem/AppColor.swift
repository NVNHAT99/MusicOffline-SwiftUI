import SwiftUI

// MARK: - AppColor
// App color palette — semantic aliases on top of UIColor+Ext hex support

extension Color {
    // MARK: - Semantic player colors (extends UIColor+Ext base palette)
    static let cardBackground: Color = Color.white.opacity(0.05)
    static let primaryText: Color = .white
    static let secondaryText: Color = Color.white.opacity(0.7)
    static let mutedText: Color = Color.white.opacity(0.4)
    static let accentPrimary: Color = Color(hexString: "#FF6B6B", alpha: 1.0)
    static let playerBackground: Color = Color.black.opacity(0.9)
    static let progressTrack: Color = Color(hexString: "#808080", alpha: 1.0)
    static let progressFill: Color = .white
    static let tabActive: Color = .white
    static let tabInactive: Color = .gray

    // MARK: - Theme fallback aliases
    // Semantic names resolved against AppColorTheme.default; used by views that
    // read a static color but want to stay consistent with the theme system.
    static let surfaceElevated: Color = Color.white.opacity(0.08)
    static let separator: Color = Color.white.opacity(0.12)
}
