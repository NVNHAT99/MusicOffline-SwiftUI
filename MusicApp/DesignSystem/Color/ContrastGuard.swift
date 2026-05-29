import SwiftUI
import UIKit

// MARK: - ContrastGuard
// WCAG-based legibility helper. Given a surface color it returns text that meets
// AA contrast and a scrim opacity that grows as the surface gets lighter, so a
// bright extracted artwork color never leaves white controls invisible.

enum ContrastGuard {

    /// WCAG relative luminance of an sRGB color (0 = black, 1 = white).
    static func relativeLuminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func linear(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// WCAG contrast ratio between two luminances (1...21).
    static func contrastRatio(_ l1: Double, _ l2: Double) -> Double {
        let lighter = max(l1, l2), darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Legible foreground for a surface of the given luminance: pure white on
    /// dark surfaces, pure black on light surfaces (whichever wins AA contrast).
    /// Pure black/white maximize the available contrast — the worst-case
    /// crossover (surface luminance ~0.18) still clears AA at ~4.58:1.
    static func legibleTextColor(forSurfaceLuminance lum: Double) -> Color {
        let whiteContrast = contrastRatio(1.0, lum)
        let blackContrast = contrastRatio(0.0, lum)
        return whiteContrast >= blackContrast ? .white : .black
    }

    /// Scrim opacity to lay over a surface so white text reaches AA. Light
    /// surfaces need a heavier dark scrim; dark surfaces need little or none.
    static func scrimOpacity(forSurfaceLuminance lum: Double) -> Double {
        // Map luminance 0.4...0.85 → opacity 0.15...0.55, clamped.
        let t = (lum - 0.4) / (0.85 - 0.4)
        return min(0.55, max(0.15, 0.15 + t * 0.4))
    }
}
