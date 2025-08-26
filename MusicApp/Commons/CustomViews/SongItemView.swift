//
//  SongItemView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/21/25.
//

import SwiftUI

struct SongItemView: View {
    
    let song: SongModel
    let onTapPlayAction: OnTapAction?
    
    var body: some View {
        HStack {
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.white)
                
            Text(song.title)
                .lineLimit(2)
                .foregroundStyle(.white)
                .font(.system(size: 14))
            
            Spacer()
                .frame(width: 8)
            
            Text(song.durationString)
                .foregroundStyle(.white)
                .font(.system(size: 14))
            
            Spacer()
                .frame(width: 16)
            
            Spacer()
            
            Button {
                onTapPlayAction?()
            } label: {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .tint(.white)
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
                             urlStr: ""),
                 onTapPlayAction: nil)
        .frame(height: 64)
        .padding()
        
}
