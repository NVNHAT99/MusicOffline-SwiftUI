//
//  ArtworkColorThemeTests.swift
//  MusicAppTests
//
//  Covers the legibility guarantee of the artwork color engine: text chosen by
//  ContrastGuard / AppColorTheme.dynamic must meet WCAG AA against its surface,
//  regardless of how bright or dull the extracted artwork color is.
//

import XCTest
import SwiftUI
import UIKit
@testable import MusicApp

final class ArtworkColorThemeTests: XCTestCase {

    // MARK: - relativeLuminance

    func test_luminance_blackIsZero_whiteIsOne() {
        XCTAssertEqual(ContrastGuard.relativeLuminance(.black), 0, accuracy: 0.001)
        XCTAssertEqual(ContrastGuard.relativeLuminance(.white), 1, accuracy: 0.001)
    }

    // MARK: - legible text meets AA (4.5:1)

    /// For a spread of surface luminances the chosen text color must clear AA.
    func test_legibleText_meetsAA_acrossLuminanceRange() {
        for step in 0...20 {
            let lum = Double(step) / 20.0
            let text = ContrastGuard.legibleTextColor(forSurfaceLuminance: lum)
            let textLum = ContrastGuard.relativeLuminance(UIColor(text))
            let ratio = ContrastGuard.contrastRatio(textLum, lum)
            XCTAssertGreaterThanOrEqual(
                ratio, 4.5,
                "Surface luminance \(lum) got text contrast \(ratio), below AA"
            )
        }
    }

    func test_lightSurface_picksDarkText() {
        let text = ContrastGuard.legibleTextColor(forSurfaceLuminance: 0.9)
        XCTAssertEqual(ContrastGuard.relativeLuminance(UIColor(text)), 0, accuracy: 0.05)
    }

    func test_darkSurface_picksWhiteText() {
        let text = ContrastGuard.legibleTextColor(forSurfaceLuminance: 0.05)
        XCTAssertEqual(ContrastGuard.relativeLuminance(UIColor(text)), 1, accuracy: 0.05)
    }

    // MARK: - scrim grows with surface lightness

    func test_scrimOpacity_heavierForLightSurfaces() {
        let dark = ContrastGuard.scrimOpacity(forSurfaceLuminance: 0.1)
        let light = ContrastGuard.scrimOpacity(forSurfaceLuminance: 0.9)
        XCTAssertLessThan(dark, light)
        XCTAssertLessThanOrEqual(light, 0.55)
        XCTAssertGreaterThanOrEqual(dark, 0.15)
    }

    // MARK: - dynamic theme legibility

    func test_dynamicTheme_onSurfaceMeetsAA_forBrightPalette() {
        let bright = ExtractedPalette(
            dominant: Color(white: 0.95),
            secondary: Color(white: 0.6),
            dominantLuminance: 0.9
        )
        let theme = AppColorTheme.dynamic(from: bright)
        let onLum = ContrastGuard.relativeLuminance(UIColor(theme.onSurface))
        let ratio = ContrastGuard.contrastRatio(onLum, bright.dominantLuminance)
        XCTAssertGreaterThanOrEqual(ratio, 4.5)
    }

    func test_dynamicTheme_alwaysHasGradientStops() {
        let theme = AppColorTheme.dynamic(from: .fallback)
        XCTAssertGreaterThanOrEqual(theme.gradientStops.count, 2)
    }
}
