//
//  LibaryView.swift
//  MusicApp
//
//  Created by Nhat on 5/12/23.
//

import SwiftUI

struct LibaryView: View {
    
    // MARK: - State and Properties
    @State private var tabSelection = 1
    let tabItems = [TabItem(image: "house", title: ""),
                    TabItem(image: "book", title: ""),
                    TabItem(image: "gearshape", title: ""),
    ]
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 150)),
                               GridItem(.adaptive(minimum: 150))]
    
    init () {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some View {
        
        GeometryReader { proxy in
            VStack {
                ZStack {
                    Color.backgroundColor
                    VStack (spacing: 0) {
                        CustomNavigtionBar(title: "My Libary")
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
                                    
                                } label: {
                                    Text("Add new")
                                } // Button Add new
                                .foregroundColor(.white)
                                
                                Spacer()
                                    .frame(width: 10)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(0...3, id: \.self) { _ in
                                        NavigationLink {
                                            
                                        } label: {
                                            PlayListItemView(data: PlaylistItem(imageName: "templePlaylist",
                                                                                playlistName: "Nothing",
                                                                                subTitle: "30 songs"),
                                                             sizeImage: CGSize(width: 241, height: 156))
                                        }
                                    }
                                } // LazyHStack
                                .frame(height: 210)
                            } // Scroll
                            .padding(.leading, 26)
                            
                            Spacer()
                                .frame(height: 15)
                            VStack (alignment: .leading) {
                                Text("Albums")
                                    .foregroundColor(.white)
                                ScrollView {
                                    LazyVGrid(columns: columns) {
                                        ForEach(0...9, id: \.self) { _ in
                                            PlayListItemView(data: PlaylistItem(imageName: "templePlaylist", playlistName: "Nothing", subTitle: ""), sizeImage: CGSize(width: 150, height: 150))
                                        } // LazyVGridView
                                    }
                                } // ScrollView
                            } // VStack
                            .padding([.leading, .trailing], 26)
                        } // VStack
                    } // VStack
                    .padding(.top, Helper.shared.safeAreaInsets?.top)
                    .padding(.bottom, proxy.size.height * 0.11)
                } // ZStack
            }//VStack
            .ignoresSafeArea(.all)
        }
        
    }
}

struct LibaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibaryView()
    }
}
