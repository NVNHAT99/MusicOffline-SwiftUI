//
//  LibaryView.swift
//  MusicApp
//
//  Created by Nhat on 5/12/23.
//

import SwiftUI
import CoreData
import Combine

struct LibaryView<ViewModel: LibaryViewViewModelProtocol>: View {

    @StateObject private var handler: ViewModel
    @StateObject private var router: Router<AppRoute>
    @EnvironmentObject private var container: DIContainer

    // The FAB sits above the custom tab bar; when a song is loaded the mini
    // player also occupies the bottom, so lift the FAB further to clear it.
    @State private var isMiniPlayerVisible: Bool = false

    // Tab bar height + a small gap; mini player adds its own clearance on top.
    private let tabBarClearance: CGFloat = 100
    private let miniPlayerClearance: CGFloat = 76

    private var fabBottomInset: CGFloat {
        tabBarClearance + (isMiniPlayerVisible ? miniPlayerClearance : 0)
    }

    init(handler: ViewModel) {
        self._handler = StateObject(wrappedValue: handler)
        self._router = StateObject(wrappedValue: Router<AppRoute>())
    }
    var body: some View {
        ZStack(alignment: .leading, content: {

            Color.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(type: .large(title: "My Libary"))
                    .frame(height: 70)
                    .foregroundColor(.primaryText)
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 24)

                    if handler.state.isLoading {
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 8) {
                                ForEach(0..<3) { _ in SongSkeletonItemView() }
                            }
                        }
                        .scrollIndicators(.hidden)
                    } else {
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0, pinnedViews: []) {
                                // Regular Playlists
                                sectionHeader("Playlists")
                                if handler.state.playlist.isEmpty {
                                    emptyLabel("You don't have any playlist yet")
                                } else {
                                    ForEach(Array(handler.state.playlist.enumerated()), id: \.element.id) { index, item in
                                        PlayListItemView(
                                            playListName: item.name,
                                            onDelete: { handler.send(intent: .deletePlaylist(item)) },
                                            ontapItem: { router.route(to: .playlistDetail(id: item.id)) }
                                        )
                                        .entrance(index: index)
                                        if !handler.isLastItem(item: item) {
                                            Divider().background(Color.separator)
                                        }
                                    }
                                }

                                // Smart Playlists
                                sectionHeader("Smart Playlists ⚡")
                                    .padding(.top, 24)
                                if handler.state.smartPlaylists.isEmpty {
                                    emptyLabel("No smart playlists yet")
                                } else {
                                    ForEach(handler.state.smartPlaylists) { item in
                                        PlayListItemView(
                                            playListName: "⚡ \(item.name)",
                                            onDelete: { handler.send(intent: .deleteSmartPlaylist(item)) },
                                            ontapItem: { router.route(to: .smartPlaylistEditor(item.id)) }
                                        )
                                        if !handler.isLastSmartPlaylist(item: item) {
                                            Divider().background(Color.gray)
                                        }
                                    }
                                }

                                // Keep the last row clear of the FAB, tab bar,
                                // and mini player when scrolled to the bottom.
                                Color.clear.frame(height: fabBottomInset + 24)
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
            }

            // FAB — single button opens menu with two playlist creation modes
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        Button {
                            router.route(to: .importHub)
                        } label: {
                            Label("Add Music…", systemImage: "square.and.arrow.down")
                        }
                        Divider()
                        Button {
                            router.route(to: .addNewPlaylist)
                        } label: {
                            Label("New Playlist", systemImage: "music.note.list")
                        }
                        Button {
                            router.route(to: .smartPlaylistEditor(UUID?.none))
                        } label: {
                            Label("New Smart Playlist", systemImage: "wand.and.stars")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Circle().fill(Color.accentPrimary).shadow(color: Color.accentPrimary.opacity(0.4), radius: 8, x: 0, y: 4))
                    }
                    .buttonStyle(.pressScale)
                    .padding(.horizontal)
                    .padding(.bottom, fabBottomInset)
                }
            }
            .animation(MotionToken.springStandard, value: isMiniPlayerVisible)

        })
        .withRouting(router: router)
        .onAppear {
            router.factory = container
            handler.send(intent: .loadPlaylist)
            handler.send(intent: .loadSmartPlaylists)
        }
        .onReceive(PlayerManager.shared.statePublisher.map { $0.currentSong != nil }.removeDuplicates()) { hasSong in
            isMiniPlayerVisible = hasSong
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlaylistDetail)) { notif in
            if let playlist = notif.object as? Playlist {
                router.popToRoot()
                router.route(to: .playlistDetail(id: playlist.id))
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .foregroundColor(.primaryText)
            .font(AppFont.title())
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func emptyLabel(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
    }
}

struct LibaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DIContainer(
            appState: AppState.shared,
            useCases: DIContainer.UseCases.create(
                songRepository: SongRepository(coreData: CoreDataManager.shared),
                playlistRepository: PlaylistRepository(coreDataService: CoreDataManager.shared),
                songMetadataRepository: SongMetadataRepository(),
                webServerService: WebServerGCDService.shared,
                coreDataManager: CoreDataManager.shared
            ),
            services: DIContainer.Services.createDefault()
        )
        let viewModel = container.makeLibaryViewViewModel()
        return LibaryView(handler: viewModel)
    }
}
