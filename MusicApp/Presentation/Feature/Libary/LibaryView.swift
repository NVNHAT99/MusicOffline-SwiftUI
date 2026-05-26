//
//  LibaryView.swift
//  MusicApp
//
//  Created by Nhat on 5/12/23.
//

import SwiftUI
import CoreData

struct LibaryView<ViewModel: LibaryViewViewModelProtocol>: View {

    @StateObject private var handler: ViewModel
    @StateObject private var router: Router<AppRoute>
    @EnvironmentObject private var container: DIContainer

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
                    .foregroundColor(.white)
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
                                    ForEach(handler.state.playlist) { item in
                                        PlayListItemView(
                                            playListName: item.name,
                                            onDelete: { handler.send(intent: .deletePlaylist(item)) },
                                            ontapItem: { router.route(to: .playlistDetail(id: item.id)) }
                                        )
                                        if !handler.isLastItem(item: item) {
                                            Divider().background(Color.gray)
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
                            .background(Circle().fill(Color.cyan).shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3))
                    }
                    .padding()
                }
            }

        })
        .withRouting(router: router)
        .onAppear {
            router.factory = container
            handler.send(intent: .loadPlaylist)
            handler.send(intent: .loadSmartPlaylists)
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
            .foregroundColor(.white)
            .font(.system(size: 22, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func emptyLabel(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.white.opacity(0.6))
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
