//
//  PlaylistDetail.swift
//  MusicApp
//
//  Created by Nhat on 7/13/23.
//

import SwiftUI
import CoreData

struct PlaylistDetailView<ViewModel: PlaylistDetailViewModelProtocol>: View {

    // MARK: - PROPERTIES WRAPER

    @StateObject var viewModel: ViewModel
    @ObservedObject var router: Router<LibaryRouter>

    init(
        viewModel: ViewModel,
        router: Router<LibaryRouter>
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._router = .init(wrappedValue: router)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            CustomNavigationBar(
                type: .custom(title: viewModel.getTitle(),
                              left: .init(icon: "chevron.left",
                                          action: {
                                              router.pop()
                                          }),
                              right: .init(title: "Edit",
                                           action: {
                                               router.route(to: .gotoEditPlaylist(viewModel.getPlaylistId(),
                                                                                  viewModel.getSongIds(),
                                                                                  viewModel.bindEditCompleted))
                                           }))) // Custom NavigationBar
            .frame(height: 50)
            
            VStack {
                if viewModel.state.isLoading {
                    ProgressView()
                } else {
                    self.playlistSection()
                }
            }.padding(.horizontal, 16)
            Spacer()
        }
        .navigationBarHidden(true)
        .background(Color.backgroundColor)
        
        .overlay(alignment: .bottom) {
            if viewModel.state.isShowToastView {
                ToastView(isShowView: viewModel.isShowToastView(),
                          message: viewModel.state.toastViewMessage,
                          timeShowView: .seconds(2))
                    .frame(height: 40)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            viewModel.send(.loadPlaylist)
        }
    }
    
    
    
    @ViewBuilder
    private func playlistSection() -> some View {
        if !viewModel.state.songs.isEmpty {
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(self.viewModel.state.songs) { song in
                        SongItemView(song: song,
                                     onTapPlayAction: {
                            self.viewModel.send(.playSongAt(song: song))
                        })
                        .frame(height: 54)
                    }
                }
            }
        } else {
            VStack(alignment: .center) {
                Spacer()
                Text("The playlist is empty!")
                    .foregroundColor(.white)
                    .frame(alignment: .center)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct LibaryDetail_Previews: PreviewProvider {
    static var previews: some View {
        let dependencies = AppDependencies.shared
        PlaylistDetailView(viewModel: dependencies.makePlaylistDetailViewModel(playlist: nil),
                           router: .init())
    }
}

