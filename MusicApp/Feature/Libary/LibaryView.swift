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
    @State private var isPresented: Bool = false
//    @State isPresented:
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
                                    isPresented = true
                                } label: {
                                    Text("Add New")
                                } // Button Add new
                                .foregroundColor(.white)
                                .sheet(isPresented: $isPresented) {
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
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(handler.state.playlist) { item in
                                            NavigationLink {
                                                PlaylistDetail()
                                            } label: {
                                                PlayListItemView(
                                                    data: PlaylistItem(imageName: "templePlaylist",
                                                                       playlistName: item.wrappedName,
                                                                       subTitle: "\(item.songsArray.count) songs"),
                                                    sizeImage: CGSize(width: 241, height: 156))
                                            }
                                        }
                                    } // LazyHStack
                                    .frame(height: 210)
                                } // Scroll
                                .padding(.leading, 26)
                            }
                            
                            Spacer()
                                .frame(height: 15)
                            VStack (alignment: .leading) {
                                Text("Albums")
                                    .foregroundColor(.white)
                                ScrollView {
                                    LazyVGrid(columns: handler.columns) {
                                        ForEach(0...9, id: \.self) { _ in
                                            PlayListItemView(data: PlaylistItem(imageName: "templePlaylist", playlistName: "Nothing", subTitle: ""), sizeImage: CGSize(width: 150, height: 150))
                                        } // LazyVGridView
                                    }
                                } // ScrollView
                                .navigationBarHidden(true)
                            } // VStack
                            .padding([.leading, .trailing], 26)
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
