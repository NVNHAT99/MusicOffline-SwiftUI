//
//  SongArtworkThumbnail.swift
//  MusicApp
//
//  Small rounded album-art thumbnail for song rows. Pulls embedded artwork from
//  the audio file via ImageCacheManager (which extracts + caches it), and falls
//  back to the brand music-note cover when a track has no artwork.
//

import SwiftUI

struct SongArtworkThumbnail: View {

    let song: SongModel
    var size: CGFloat = 50

    @State private var uiImage: UIImage?
    private let cache = ImageCacheFactory.shared

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Brand fallback cover (music note on gradient).
                Image("demoThumbnail2")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: DesignToken.Player.artworkCornerRadius, style: .continuous))
        .task(id: song.id) { await loadArtwork() }
    }

    private func loadArtwork() async {
        guard let urlStr = try? song.fileURLString(),
              let data = await cache.get(for: urlStr),
              let image = UIImage(data: data) else {
            uiImage = nil
            return
        }
        uiImage = image
    }
}
