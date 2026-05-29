import SwiftUI

// MARK: - AppColorTheme
// A value-type theme carried via Environment. `.default` reproduces today's
// grey/white look exactly (regression-safe). Per-song themes are produced by the
// artwork color-extraction engine and injected onto a view subtree, so one song's
// color never leaks into unrelated screens.

struct AppColorTheme: Equatable {

    /// Base surface color behind content.
    let surface: Color
    /// Brand / interactive accent (active controls, highlights).
    let accent: Color
    /// Primary text/icon color guaranteed to read on `surface`.
    let onSurface: Color
    /// Secondary (de-emphasized) text/icon color.
    let onSurfaceSecondary: Color
    /// Gradient stops for `.dynamicBackground()`. When < 2 stops, the modifier
    /// falls back to a flat `surface` fill.
    let gradientStops: [Color]

    init(
        surface: Color,
        accent: Color,
        onSurface: Color = .white,
        onSurfaceSecondary: Color = Color.white.opacity(0.7),
        gradientStops: [Color] = []
    ) {
        self.surface = surface
        self.accent = accent
        self.onSurface = onSurface
        self.onSurfaceSecondary = onSurfaceSecondary
        self.gradientStops = gradientStops
    }

    /// Safe fallback matching the existing flat dark look. Accent = coral token.
    static let `default` = AppColorTheme(
        surface: Color.backgroundColor,
        accent: .accentPrimary,
        onSurface: .white,
        onSurfaceSecondary: Color.white.opacity(0.7),
        gradientStops: []
    )
}
