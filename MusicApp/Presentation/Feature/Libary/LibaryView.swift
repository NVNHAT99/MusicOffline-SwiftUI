//
//  LibaryView.swift
//  MusicApp
//
//  Created by Nhat on 5/12/23.
//

import SwiftUI

struct LibaryView: View {
    
    @StateObject private var handler: LibaryViewViewModel
    @State private var isPresented: Bool = false
    @StateObject private var router = Router<LibaryRouter>()
    
    init (handler: LibaryViewViewModel) {
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
                            LazyVStack(spacing: 12) {
                                ForEach(handler.state.playlist) { item in
                                    PlayListItemView(playListName: item.name)
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
                                .padding(20)
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
        .onAppear {
            handler.send(intent: .loadPlaylist)
        }
        .embedded(navigation: .stacks,
                  with: router)
        
    }
}

struct LibaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibaryView(handler: LibaryViewViewModel())
    }
}
