import SwiftUI

// MARK: - AppColorTheme.dynamic
// Maps an ExtractedPalette into a legible AppColorTheme. The surface is always
// kept dark enough for white controls: gradient runs dominant → secondary →
// near-black, and the text color is contrast-checked rather than assumed white.

extension AppColorTheme {
    static func dynamic(from palette: ExtractedPalette) -> AppColorTheme {
        let onSurface = ContrastGuard.legibleTextColor(forSurfaceLuminance: palette.dominantLuminance)

        // Anchor the bottom of the gradient near-black so the lower controls and
        // text always sit on a dark base regardless of artwork brightness.
        let stops: [Color] = [
            palette.dominant,
            palette.secondary,
            Color.backgroundColor
        ]

        return AppColorTheme(
            surface: palette.secondary,
            accent: palette.dominant,
            onSurface: onSurface,
            onSurfaceSecondary: onSurface.opacity(0.7),
            gradientStops: stops
        )
    }
}
