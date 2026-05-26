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

    var body: some View {
        HStack {
            Image(systemName: isCurrent && isPlaying ? "speaker.wave.2.fill" : "music.note")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(isCurrent ? Color.cyan : .white)

            Text(song.title)
                .lineLimit(2)
                .foregroundStyle(isCurrent ? Color.cyan : .white)
                .font(.system(size: 14, weight: isCurrent ? .semibold : .regular))

            Spacer().frame(width: 8)

            Text(song.durationString)
                .foregroundStyle(.white.opacity(0.7))
                .font(.system(size: 14))

            Spacer().frame(width: 16)
            Spacer()

            Button {
                onTapPlayAction?()
            } label: {
                Image(systemName: isCurrent && isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(isCurrent ? Color.cyan : .white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.backgroundColor)
        .cornerRadius(16, corners: .allCorners)
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
