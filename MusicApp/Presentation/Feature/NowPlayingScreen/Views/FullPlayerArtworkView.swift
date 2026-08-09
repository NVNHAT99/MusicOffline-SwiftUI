import SwiftUI

// MARK: - FullPlayerArtworkView
// The square artwork (or lyrics panel) at the top of the full player. Extracted
// from NowPlayingFullPlayerView to keep each view under the size limit.

struct FullPlayerArtworkView: View {
    let uiImage: UIImage?
    let showLyrics: Bool
    let lyrics: [LyricsLine]
    let activeLyricIndex: Int?
    let geometry: GeometryProxy

    var body: some View {
        // Use the smaller of (3/5 height, width - margin) so the artwork is
        // always a real square that fits both axes, never wider than the screen.
        let horizontalInset: CGFloat = 32
        let maxSquare = min(geometry.size.height * 3 / 5,
                            geometry.size.width - horizontalInset)
        let size = max(120, maxSquare)

        Group {
            if showLyrics {
                LyricsView(lines: lyrics, activeIndex: activeLyricIndex)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: DesignToken.Radius.sm))
            } else if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    // Fill the square and crop overflow — source images are often
                    // non-square (e.g. 16:9 thumbnails) and .scaledToFit leaves bars.
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: DesignToken.Radius.sm))
                    .shadow(color: .black.opacity(0.3), radius: DesignToken.Shadow.large, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: DesignToken.Radius.sm)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .shimmer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityHidden(true)
    }
}
