//
//  LibaryView.swift
//  MusicApp
//
//  Created by Nhat on 5/12/23.
//

import SwiftUI

struct LibaryView<ViewModel: LibaryViewViewModelProtocol>: View {

    @EnvironmentObject var reloadManager: TabReloadManager
    @StateObject private var handler: ViewModel
    @StateObject private var router = Router<LibaryRouter>()
    
    init (handler: ViewModel) {
        self._handler = StateObject(wrappedValue: handler)
    }
    var body: some View {
        ZStack(alignment: .leading, content: {
            
            Color.backgroundColor
                .ignoresSafeArea()
            
            VStack (spacing: 0) {
                CustomNavigationBar(type: .large(title: "My Libary"))
                    .frame(height: 70)
                    .foregroundColor(.white)
                VStack (alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: 24)
                    HStack {
                        Text("Playlists")
                            .foregroundColor(.white)
                            .font(.system(size: 28)) // text
                    }
                    .padding(.bottom, 24)
                    
                    if handler.state.isLoading  {
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 8) {
                                ForEach(0..<3) { _ in
                                    SongSkeletonItemView()
                                }
                            }
                        } // scrollview
                        .scrollIndicators(.hidden)
                        
                    } else if !handler.state.playlist.isEmpty {
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(handler.state.playlist) { item in
                                    PlayListItemView(playListName: item.name,
                                                     onDelete: {
                                        self.handler.send(intent: .deletePlaylist(item))
                                    },
                                                     ontapItem: {
                                        self.router.route(to: .gotoPlaylistDetail(item))
                                    })
                                    
                                    if !self.handler.isLastItem(item: item) {
                                        Divider()
                                            .background(Color.gray)
                                    }
                                }
                            }
                        } // Scroll
                        .scrollIndicators(.hidden)
                    } else {
                        VStack(alignment: .center) {
                            Text("You don't have any play list yet")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    
                    Spacer()
                }// VStack
                .padding(.horizontal, 16)
            } // VStack
            
            VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        Button {
                            router.route(to: .addPlaylist, dismissCompletion: {
                                self.handler.send(intent: .loadPlaylist)
                            })
                        } label: {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Color.cyan)
                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                                )
                        }
                        .padding()
                    }
                }

        }) // zstack
        .embedded(navigation: .stacks,
                  with: router)
        .onChange(of: reloadManager.resetTab) { _, newValue in
            if newValue.contains(.playlist) {
                self.handler.send(intent: .loadPlaylist)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPlaylistDetail)) { notif in
            if let playlist = notif.object as? Playlist {
                router.popToRoot()
                router.route(to: .gotoPlaylistDetail(playlist))
            }
        }
    }
}

struct LibaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        let dependencies = AppDependencies.shared
        LibaryView(handler: dependencies.makeLibaryViewViewModel())
        .environmentObject(TabReloadManager())
    }
}
