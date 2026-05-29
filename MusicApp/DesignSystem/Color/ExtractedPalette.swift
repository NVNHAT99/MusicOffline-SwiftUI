import SwiftUI

// MARK: - ExtractedPalette
// Result of analyzing an artwork image: a dominant color, a darker secondary
// (gradient end-stop), and luminance metadata so the theme can choose legible
// text and an appropriate scrim. Pure value type — safe to cache and to compare
// for SwiftUI animation diffing.

struct ExtractedPalette: Equatable {
    /// Primary tone of the artwork (already mildly saturated for vibrancy).
    let dominant: Color
    /// Darker derived tone used as the bottom gradient stop.
    let secondary: Color
    /// WCAG relative luminance of `dominant` (0 = black, 1 = white).
    let dominantLuminance: Double

    /// True when the dominant tone is light enough that white text would fail
    /// contrast — consumers then darken/scrim or switch to dark text.
    var isLight: Bool { dominantLuminance > 0.6 }

    /// Neutral fallback matching the existing flat look, used when extraction
    /// fails (no artwork / decode error).
    static let fallback = ExtractedPalette(
        dominant: Color.backgroundColor,
        secondary: .black,
        dominantLuminance: 0.05
    )
}
