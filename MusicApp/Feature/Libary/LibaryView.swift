//
//  LibaryView.swift
//  MusicApp
//
//  Created by Nhat on 5/12/23.
//

import SwiftUI

struct LibaryView: View {
    
    @ObservedObject private var handler: LibaryViewViewModel
    @State private var isPresented: Bool = false
    @StateObject private var router = Router<LibaryRouter>()
//    @State isPresented:
    init (handler: LibaryViewViewModel) {
        self.handler = handler
    }
    var body: some View {
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
                        router.route(to: .addPlaylist)
                    } label: {
                        Text("Add New")
                            .foregroundColor(.white)
                    } // Button Add new
                    
                    Spacer()
                        .frame(width: 10)
                }
                if false {
                    VStack(alignment: .center) {
                        Text("You don't have any play list yet")
                            .foregroundColor(.white)
                            .frame(alignment: .center)
                    }
                    .frame(height: 50)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(0...3, id: \.self) { _ in
                                NavigationLink {
                                    
                                } label: {
                                    PlayListItemView(playListName: "tex 1")
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
                        LazyVStack {
                            ForEach(0...9, id: \.self) { _ in
                                PlayListItemView(playListName: "Text")
                            } // LazyVGridView
                        }
                    } // ScrollView
                    .navigationBarHidden(true)
                } // VStack
                .padding([.leading, .trailing], 26)
            } // VStack
        } // VStack
        .onAppear {
            handler.send(intent: .loadPlaylist)
        }
        .background(Color.backgroundColor)
        .embedded(navigation: .stacks,
                  with: router)
        
    }
}

struct LibaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibaryView(handler: LibaryViewViewModel())
    }
}
