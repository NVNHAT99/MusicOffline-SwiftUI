//
//  HomeTabView.swift
//  MusicApp
//
//  Created by Nhat on 5/18/23.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    @State var isPresented: Bool = false
    
    var body: some View {
        VStack {
            VStack {
                 Text("Albums")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 16) {
                        ForEach(0..<10, id: \.self) { _ in
                            HomeCardView()
                                .frame(width: 160)
                        }
                    }
                   
                }
                .scrollIndicators(.hidden)
            } // VStack - album section
            
            VStack {
                 Text("My Playlist")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 16) {
                        ForEach(0..<10, id: \.self) { _ in
                            HomeCardView()
                                .frame(width: 160)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
            } // VStack - playlist section
            
            // recent play
            
            VStack {
                 Text("Recently Played")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView(.vertical) {
                    LazyVStack {
                        ForEach(0..<10, id: \.self) { _ in
                            SongItemView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                        }
                    }

                }
                
            } // VStack - playlist section
            .padding(.trailing, 16)
            
            // recent play
            Spacer()
        }
        .padding(.leading, 16)
    }
}

struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .background(Color.backgroundColor)
    }
}
