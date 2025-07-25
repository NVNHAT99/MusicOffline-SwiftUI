//
//  SongItemView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/21/25.
//

import SwiftUI

struct SongItemView: View {
    
    var body: some View {
        HStack {
            Image("demoSongImage")
                .resizable()
                .scaledToFit()
            Text("Taylor Swift - shake")
                .foregroundStyle(.white)
            Spacer()
            
            Text("3:20")
                .foregroundStyle(.white)
            Spacer()
                .frame(width: 16)
            Button {
                
            } label: {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .tint(.white)
            }

        }
        .padding(.trailing, 16)
        .background(Color.backgroundColor)
        .cornerRadius(16, corners: .allCorners)
        
    }
}

#Preview {
    SongItemView()
        .frame(height: 100)
        .padding()
        
}
