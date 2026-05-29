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
        HStack {
            Image(systemName: isCurrent && isPlaying ? "speaker.wave.2.fill" : "music.note")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(highlight)

            Text(song.title)
                .lineLimit(2)
                .foregroundStyle(highlight)
                .font(AppFont.callout().weight(isCurrent ? .semibold : .regular))

            Spacer().frame(width: 8)

            Text(song.durationString)
                .foregroundStyle(Color.secondaryText)
                .font(AppFont.callout())

            Spacer().frame(width: 16)
            Spacer()

            Button {
                onTapPlayAction?()
            } label: {
                Image(systemName: isCurrent && isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(highlight)
            }
            .buttonStyle(.pressScale)
        }
        .padding(.horizontal, DesignToken.Spacing.md)
        .padding(.vertical, DesignToken.Spacing.sm)
        .background(isCurrent ? Color.accentPrimary.opacity(0.12) : Color.backgroundColor)
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
