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
struct HomeView<ViewModel: HomeViewModelProtocol>: View {

    // MARK: - Properties
    @StateObject var viewModel: ViewModel
    var onPlaylistTap: (Playlist) -> Void
    
    init(viewModel: ViewModel,
         onPlaylistTap: @escaping (Playlist) -> Void) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.onPlaylistTap = onPlaylistTap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(content: {
                VStack {
                    VStack {
                        Text("Recently Played Playlists")
                            .font(AppFont.sectionHeader())
                            .foregroundStyle(Color.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        self.playlistSection()
                    }

                    // recent play

                    VStack {
                        Text("Recently Played Songs")
                            .font(AppFont.sectionHeader())
                            .foregroundStyle(Color.primaryText)
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

            // Bottom banner ad
            AdBanner()
        }
        .background(Color.backgroundColor)
        .onAppear {
            // Recently-played is pushed via refreshHomePubliser when a song starts,
            // but that fires while the user is on the Now Playing screen, not Home.
            // Re-fetch on appear so returning to this tab always shows fresh data.
            viewModel.send(.fetchData)
        }
    }
    
    @ViewBuilder
    private func albumSection() -> some View {
        if viewModel.state.isLoadingPlaylist {
            skeletonView()
        } else if viewModel.state.albums.isEmpty {
            Text("Hiện tại chưa có album nào")
                .foregroundColor(.secondaryText)
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
        if viewModel.state.isLoadingPlaylist {
            skeletonView()
        } else if viewModel.state.playlists.isEmpty {
            Text("There are no recently played playlists.")
                .foregroundColor(.secondaryText)
                .frame(height: 160)
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(viewModel.state.playlists.enumerated()), id: \.element.id) { index, playlist in
                        HomeCardView(
                            title: playlist.name,
                            imageName: "",
                            subTitle: ""
                        )
                        .entrance(index: index)
                        .onTapGesture {
                            self.onPlaylistTap(playlist)
                        }
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
            Text("There are no recently played songs.")
                .foregroundColor(.secondaryText)
                .frame(height: 160)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.state.recentSongs.enumerated()), id: \.element.id) { index, recentSong in
                    SongItemView(
                        song: recentSong.song,
                        onTapPlayAction: {
                            viewModel.send(.play(recentSong))
                        }
                    )
                    .entrance(index: index)
                }
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

struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DIContainer.preview
        HomeView(viewModel: container.makeHomeViewModel(), onPlaylistTap: { _ in })
            .environmentObject(container)
            .background(Color.backgroundColor)
    }
}
