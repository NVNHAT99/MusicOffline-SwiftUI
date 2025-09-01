//
//  SelectedSongItemView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/26/25.
//

import SwiftUI

struct SelectedSongItemView: View {
    let songData: SelectedSong
    
    var body: some View {
        HStack {
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
            
            Text(songData.song.title)
                .foregroundStyle(.white)
            Spacer()
            if songData.isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 8)
                
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 8)
        .padding(.trailing, 8)
        .background(Color.headerBackground)
        .cornerRadius(16, corners: .allCorners)
    }
}

#Preview {
    SelectedSongItemView(songData: .init(song: .init(id: UUID(),
                                                     title: "",
                                                     album: "",
                                                     artist: "",
                                                     duration: 12.0,
                                                     urlStr: nil),
                                         isSelected: true))
}
