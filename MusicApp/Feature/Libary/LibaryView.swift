//
//  LibaryView.swift
//  MusicApp
//
//  Created by Nhat on 5/12/23.
//

import SwiftUI

struct LibaryView: View {
    
    // MARK: - State and Properties
    @ObservedObject private var viewModel: LibaryViewViewModel
    @State private var isActive: Bool = false
    init (handler: LibaryViewViewModel) {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        self.viewModel = handler
    }
    var body: some View {
        
        GeometryReader { proxy in
            VStack {
                ZStack {
                    Color.black
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
                                        viewModel.send(intent: .addNewPlayList(name))
                                    }
                                }
                                Spacer()
                                    .frame(width: 10)
                            }
                            if viewModel.state.playlist.isEmpty {
                                VStack(alignment: .center) {
                                    Text("You don't have any play list yet")
                                        .foregroundColor(.white)
                                        .frame(alignment: .center)
                                        .transition(.opacity)
                                }
                                .frame(width: proxy.size.width)
                            } else {
                                List {
                                    ForEach(viewModel.state.playlist) { item in
                                        NavigationLink {
                                            PlaylistDetailView(viewModel: PlaylistDetailViewModel(state: .init(playlist: item)))
                                        } label: {
                                            PlayListItemView(playListName: item.name ?? String.empty)
                                                .foregroundColor(.white)
                                                
                                        }
                                    }
                                    .onDelete(perform: { indexSet in
                                        indexSet.forEach { index in
                                            viewModel.send(intent: .deletePlaylist(viewModel.state.playlist[index]))
                                        }
                                    })
                                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                                    .listRowBackground(Color.backgroundColor)
                                    .buttonStyle(AnimationPressStyle())
                                    .foregroundColor(.white)
                                    .listRowSeparatorTint(.gray)
                                }
                                .modifier(ListBackgroundModifier())
                            }
                            Spacer()
                        } // VStack
                    } // VStack
                    .padding(.top, Helper.shared.safeAreaInsets?.top)
                    .padding(.bottom, proxy.size.height * 0.11)
                } // ZStack
            }//VStack
            .ignoresSafeArea(.all)
            .task {
                viewModel.send(intent: .loadPlaylist)
            }
            .overlay(alignment: .bottom) {
                if viewModel.state.isShowToastView {
                    ToastView(isShowView: viewModel.isShowToastView(), message: viewModel.state.toastViewMessage, timeShowView: .seconds(2))
                        .frame(height: 40)
                        .padding(.bottom, 16)
                }
            }
        }
        
    }
}

struct LibaryTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibaryView(handler: LibaryViewViewModel())
    }
}
