import SwiftUI

// MARK: - AppColor
// App color palette — semantic aliases on top of UIColor+Ext hex support

extension Color {
    // MARK: - Semantic player colors (extends UIColor+Ext base palette)
    // Card/surface brightened slightly so content lifts off the violet base.
    static let cardBackground: Color = Color.white.opacity(0.08)
    static let primaryText: Color = .white
    static let secondaryText: Color = Color.white.opacity(0.72)
    static let mutedText: Color = Color.white.opacity(0.45)
    // Brand accent: warm sunset orange from the end of the app-icon gradient.
    static let accentPrimary: Color = Color(hexString: "#FF7E00", alpha: 1.0)
    static let playerBackground: Color = Color.black.opacity(0.9)
    static let progressTrack: Color = Color.white.opacity(0.22)
    static let progressFill: Color = .white
    static let tabActive: Color = Color(hexString: "#FF7E00", alpha: 1.0)
    static let tabInactive: Color = Color.white.opacity(0.45)

    // MARK: - Theme fallback aliases
    // Semantic names resolved against AppColorTheme.default; used by views that
    // read a static color but want to stay consistent with the theme system.
    static let surfaceElevated: Color = Color.white.opacity(0.11)
    static let separator: Color = Color.white.opacity(0.14)

    // MARK: - Brand gradient (app-icon derived)
    // Electric violet → hot magenta → sunset orange. Use for primary CTAs,
    // highlights, and empty-state accents.
    static let brandGradientStops: [Color] = [
        Color(hexString: "#7C3AED", alpha: 1.0),
        Color(hexString: "#FF2A5F", alpha: 1.0),
        Color(hexString: "#FF7E00", alpha: 1.0)
    ]

    /// Diagonal brand gradient ready to drop into `.background()` / `.fill()`.
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: brandGradientStops,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
