import SwiftUI

// MARK: - DesignToken
// Centralised design constants — spacing, radius, animation, shadow

enum DesignToken {

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }

    // MARK: - Animation Duration
    enum Animation {
        static let fast: Double = 0.15
        static let standard: Double = 0.3
        static let slow: Double = 0.5
    }

    // MARK: - Shadow Radius
    enum Shadow {
        static let small: CGFloat = 4
        static let medium: CGFloat = 10
        static let large: CGFloat = 20
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 54
    }

    // MARK: - Player
    enum Player {
        static let miniPlayerHeight: CGFloat = 80
        static let artworkCornerRadius: CGFloat = 8
        static let controlButtonSize: CGFloat = 28
        static let playButtonSize: CGFloat = 54
    }
}
