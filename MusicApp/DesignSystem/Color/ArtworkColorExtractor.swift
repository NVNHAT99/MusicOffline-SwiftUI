import SwiftUI
import UIKit
import CoreImage

// MARK: - ArtworkColorExtractor
// Computes a dominant color from artwork via CoreImage's CIAreaAverage on a
// downscaled image. Designed to run inside a detached task — it takes a CGImage
// (immutable, thread-safe) rather than a shared mutable UIImage.

enum ArtworkColorExtractor {

    // Single shared context — creating a CIContext per call is expensive.
    private static let context = CIContext(options: [.workingColorSpace: NSNull()])

    /// Extract a palette from a CGImage. Returns `.fallback` if averaging fails.
    static func palette(from cgImage: CGImage) -> ExtractedPalette {
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ]), let output = filter.outputImage else {
            return .fallback
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let r = CGFloat(bitmap[0]) / 255
        let g = CGFloat(bitmap[1]) / 255
        let b = CGFloat(bitmap[2]) / 255

        let dominantUI = vibrant(r: r, g: g, b: b)
        let luminance = ContrastGuard.relativeLuminance(dominantUI)
        let secondaryUI = dominantUI.darkened(by: 0.45)

        return ExtractedPalette(
            dominant: Color(dominantUI),
            secondary: Color(secondaryUI),
            dominantLuminance: luminance
        )
    }

    /// Average colors are often muddy/desaturated. Nudge saturation up a little
    /// so the gradient reads as "colorful" rather than grey-ish.
    private static func vibrant(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        let base = UIColor(red: r, green: g, blue: b, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
        base.getHue(&h, saturation: &s, brightness: &br, alpha: &a)
        let boostedS = min(1.0, s * 1.35 + 0.05)
        return UIColor(hue: h, saturation: boostedS, brightness: br, alpha: 1)
    }
}

private extension UIColor {
    /// Multiply brightness toward black by `amount` (0...1).
    func darkened(by amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * (1 - amount), alpha: a)
    }
}
