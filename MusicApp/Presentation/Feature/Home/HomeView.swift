//
//  HomeTabView.swift
//  MusicApp
//
//  Created by Nhat on 5/18/23.
//

import SwiftUI

enum HomeSkeletonType {
    case others
    case reccent
}
struct HomeView: View {
    // MARK: - Properties
    @StateObject var viewModel: HomeViewModel = HomeViewModel()
    var body: some View {
        VStack {
            VStack {
                 Text("Albums")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                self.albumSection()
            } // VStack - album section
            
            VStack {
                Text("Playlist")
                   .font(.system(size: 24, weight: .semibold, design: .rounded))
                   .foregroundStyle(.white)
                   .frame(maxWidth: .infinity, alignment: .leading)
                self.playlistSection()
            }
            
            // recent play
            
            VStack {
                 Text("Recently Played")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                recentSongsSection()
                
            } // VStack - playlist section
            .padding(.trailing, 16)
            
            // recent play
            Spacer()
        }
        .padding(.leading, 16)
        .onAppear {
            viewModel.send(.fetchSongs)
        }
    }
    
    @ViewBuilder
    private func albumSection() -> some View {
        if viewModel.state.isLoading {
            skeletonView()
        } else if viewModel.state.albums.isEmpty {
            Text("Hiện tại chưa có album nào")
                .foregroundColor(.gray)
                .frame(height: 160)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(viewModel.state.albums) { album in
                        HomeCardView(
                            title: album.title,
                            imageName: "",
                            subTitle: ""
                        )
                        .frame(height: 160)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    @ViewBuilder
    private func playlistSection() -> some View {
        if viewModel.state.isLoading {
            skeletonView()
        } else if viewModel.state.playlists.isEmpty {
            Text("Hiện tại chưa có playlist nào")
                .foregroundColor(.gray)
                .frame(height: 160)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(viewModel.state.playlists) { playlist in
                        HomeCardView(
                            title: playlist.name,
                            imageName: "",
                            subTitle: ""
                        )
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    @ViewBuilder
    private func recentSongsSection() -> some View {
        if viewModel.state.isLoading {
            skeletonView(with: .reccent)
        } else if viewModel.state.recentSongs.isEmpty {
            Text("Hiện tại chưa có recent song nào")
                .foregroundColor(.gray)
                .frame(height: 160)
        } else {
            ScrollView(.horizontal) {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.state.recentSongs) { recenSong in
                        SongItemView()
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    @ViewBuilder
    private func skeletonView(with type: HomeSkeletonType = .others) -> some View {
        if type == .reccent {
            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        SongSkeletonItemView()
                    }
                }
            }
            .scrollIndicators(.hidden)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        HomeCardSkeletonView()
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .background(Color.backgroundColor)
    }
}
