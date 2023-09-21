//
//  LibaryView.swift
//  MusicApp
//
//  Created by Nhat on 5/12/23.
//

import SwiftUI

struct LibaryView: View {
    
    // MARK: - State and Properties
    @ObservedObject private var handler: LibaryViewHandler
    @State private var isActive: Bool = false
    init (handler: LibaryViewHandler) {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        self.handler = handler
    }
    var body: some View {
        
        GeometryReader { proxy in
            VStack {
                ZStack {
                    Color.backgroundColor
                    VStack (spacing: 0) {
                        CustomNavigationBar(type: .larger("My Libary"))
                            .frame(height: 70)
                            .padding(.leading, 26)
                            .foregroundColor(.white)
                        VStack (alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Playlists")
                                    .padding(26)
                                    .foregroundColor(.white)
                                    .font(.system(size: 28))
                                
                                Spacer()
                                
                                Button {
                                    isActive = true
                                } label: {
                                    Text("Add New")
                                } // Button Add new
                                .foregroundColor(.white)
                                .sheet(isPresented: $isActive) {
                                    AddNewPlayListView { name in
                                        handler.send(intent: .addNewPlayList(name))
                                    }
                                }
                                Spacer()
                                    .frame(width: 10)
                            }
                            if handler.state.playlist.isEmpty {
                                VStack(alignment: .center) {
                                    Text("You don't have any play list yet")
                                        .foregroundColor(.white)
                                        .frame(alignment: .center)
                                }
                                .frame(width: proxy.size.width,height: 50)
                            } else {
                                LazyVStack {
                                    ForEach(handler.state.playlist) { item in
                                        NavigationLink {
                                            PlaylistDetailView(handler: PlaylistDetailsHandler(state: .init(playlist: item)))
                                        } label: {
                                            SwiperToDeleteView {
                                                PlayListItemView(playListName: item.name ?? String.empty)
                                                    .frame(height: 40)
                                                    .background(Color.backgroundColor)
                                            } deleteAction: {
                                                withAnimation {
                                                    handler.send(intent: .deletePlaylist(item))
                                                }
                                            }
                                            .frame(height: 40)
                                            .foregroundColor(.white)
                                        }
                                        .buttonStyle(NoAnimationButtonStyle())
                                    }
                                }
                                .padding(.leading, 16)
                            }
                            Spacer()
                        } // VStack
                    } // VStack
                    .padding(.top, Helper.shared.safeAreaInsets?.top)
                    .padding(.bottom, proxy.size.height * 0.11)
                } // ZStack
            }//VStack
            .ignoresSafeArea(.all)
            .onAppear {
                handler.send(intent: .loadPlaylist)
            }
        }
        
    }
}

struct LibaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibaryView(handler: LibaryViewHandler())
    }
}
