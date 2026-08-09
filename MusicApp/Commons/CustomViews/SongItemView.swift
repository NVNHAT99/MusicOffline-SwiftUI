//
//  SongItemView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/21/25.
//

import SwiftUI

struct SongItemView: View {

    let song: SongModel
    /// True when this row's song matches the player's current song.
    var isCurrent: Bool = false
    /// True when the player is currently playing (only meaningful with `isCurrent`).
    var isPlaying: Bool = false
    let onTapPlayAction: OnTapAction?

    private var highlight: Color { isCurrent ? .accentPrimary : .primaryText }

    var body: some View {
        HStack(spacing: 12) {
            // Album artwork thumbnail (extracted from the file, brand fallback).
            SongArtworkThumbnail(song: song, size: 50)
                .overlay {
                    // Subtle now-playing badge over the artwork.
                    if isCurrent {
                        RoundedRectangle(cornerRadius: DesignToken.Player.artworkCornerRadius, style: .continuous)
                            .fill(Color.black.opacity(0.35))
                        Image(systemName: isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .lineLimit(1)
                    .foregroundStyle(highlight)
                    .font(AppFont.callout().weight(isCurrent ? .semibold : .medium))

                Text(song.artist.isEmpty ? song.durationString
                                        : "\(song.artist) · \(song.durationString)")
                    .lineLimit(1)
                    .foregroundStyle(Color.secondaryText)
                    .font(AppFont.caption())
            }

            Spacer(minLength: 8)

            Button {
                onTapPlayAction?()
            } label: {
                Image(systemName: isCurrent && isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(highlight)
            }
            .buttonStyle(.pressScale)
        }
        .padding(.horizontal, DesignToken.Spacing.md)
        .padding(.vertical, DesignToken.Spacing.sm)
        .background(isCurrent ? Color.accentPrimary.opacity(0.14) : Color.cardBackground)
        .cornerRadius(DesignToken.Radius.lg, corners: .allCorners)
    }
}

#Preview {
    SongItemView(song: .init(id: UUID(),
                             title: "shake it off",
                             album: "taylor",
                             artist: "taylor",
                             duration: 12.0,
                             urlStr: nil),
                 onTapPlayAction: nil)
        .frame(height: 64)
        .padding()
        
}
