import UIKit

// MARK: - PaletteProvider
// Async facade that turns artwork into an ExtractedPalette, cached per song
// (keyed by the same URL string the image cache uses). Extraction runs off the
// main thread and never on a SwiftUI redraw path. A second request for the same
// key returns the cached palette without recomputing.

final class PaletteProvider {
    static let shared = PaletteProvider()

    private let cache = NSCache<NSString, CacheBox>()

    private init() {
        cache.countLimit = 60
    }

    /// Pixel size the artwork is downscaled to before averaging — small enough
    /// to be fast, large enough to be representative.
    private let sampleSize = CGSize(width: 50, height: 50)

    /// Return the palette for `key`, extracting from `image` on a miss.
    func palette(forKey key: String, image: UIImage) async -> ExtractedPalette {
        if let cached = cache.object(forKey: key as NSString) {
            return cached.palette
        }

        // Downscale on the calling actor (cheap), then hand an immutable CGImage
        // to a detached task so we never touch a shared mutable UIImage off-main.
        guard let cgImage = downscaledCGImage(from: image) else {
            return .fallback
        }

        let palette = await Task.detached(priority: .userInitiated) {
            ArtworkColorExtractor.palette(from: cgImage)
        }.value

        cache.setObject(CacheBox(palette: palette), forKey: key as NSString)
        return palette
    }

    private func downscaledCGImage(from image: UIImage) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: sampleSize)
        let small = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: sampleSize))
        }
        return small.cgImage
    }
}

// NSCache requires class values; box the value-type palette.
private final class CacheBox {
    let palette: ExtractedPalette
    init(palette: ExtractedPalette) { self.palette = palette }
}
