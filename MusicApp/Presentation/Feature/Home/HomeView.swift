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
    @EnvironmentObject var reloadManager: TabReloadManager
    @StateObject var viewModel: HomeViewModel
    
    init(viewModel: HomeViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView(content: {
            VStack {
                VStack {
                    Text("Recently Played Playlists")
                       .font(.system(size: 24, weight: .semibold, design: .rounded))
                       .foregroundStyle(.white)
                       .frame(maxWidth: .infinity, alignment: .leading)
                    self.playlistSection()
                }
                
                // recent play
                
                VStack {
                     Text("Recently Played Songs")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    recentSongsSection()
                    
                } // VStack - playlist section
                .padding(.trailing, 16)
                
                // recent play
                Spacer()
            }
        })
        .padding(.leading, 16)
        .padding(.top, 54)
        .scrollContentBackground(.hidden) // 👈 Ẩn background
        .background(Color.backgroundColor)
        .onChange(of: reloadManager.resetTab) { _, newValue in
            if newValue.contains(.home) {
                self.viewModel.send(.fetchData)
            }
        }
    }
    
    @ViewBuilder
    private func albumSection() -> some View {
        if viewModel.state.isLoadingRecentSongs {
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
        if viewModel.state.isLoadingRecentSongs {
            skeletonView()
        } else if viewModel.state.playlists.isEmpty {
            Text("There are no recently played playlists.")
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
                    .frame(height: 160)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    @ViewBuilder
    private func recentSongsSection() -> some View {
        if viewModel.state.isLoadingRecentSongs {
            skeletonView(with: .reccent)
        } else if viewModel.state.recentSongs.isEmpty {
            // code này ở đây thì gây ra hiện tượng trên, thay bằng empty view thì không bị
            Text("There are no recently played songs.")
                .foregroundColor(.gray)
                .padding(.top, 54)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.state.recentSongs) { recenSong in
                    SongItemView(song: recenSong.song,
                                 onTapPlayAction: {
                        viewModel.send(.play(recenSong))
                    })
                }
            }
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
        HomeView(viewModel: .init())
            .background(Color.backgroundColor)
            .environmentObject(TabReloadManager())
    }
}
