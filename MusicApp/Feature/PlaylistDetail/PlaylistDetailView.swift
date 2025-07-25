//
//  PlaylistDetail.swift
//  MusicApp
//
//  Created by Nhat on 7/13/23.
//

import SwiftUI
import CoreData

struct PlaylistDetailView: View {
    // MARK: - PROPERTIES
    // MARK: - PROPERTIES WRAPER
    @State var isPresented: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: PlaylistDetailViewModel
    @StateObject var addNewsSongVM: AddNewSongsViewModel

    init(viewModel: PlaylistDetailViewModel) {
        self.viewModel = viewModel
        self._addNewsSongVM = StateObject(wrappedValue: AddNewSongsViewModel(state: .init(playlist: viewModel.state.playlist)))
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading) {
                CustomNavigationBar(type: .twoButtons(leftView: {
                    AnyView(
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    )
                    
                }, rightView: {
                    AnyView(
                        NavigationLink(destination: {
                            AddNewSongsView(viewModel: addNewsSongVM) { result in
                                viewModel.send(intent: .handleAddNewSongs(result))
                            }
                        }, label: {
                            Text("Add news")
                        })
                    )
                }, title: viewModel.state.playlist?.name ?? String.empty)) // Custom NavigationBar
                .frame(height: 50)
                .background(Color.black)
                
                if (viewModel.state.playlist?.songsArray.count ?? 0) <= 0 {
                    VStack(alignment: .center) {
                        Spacer()
                        Text("The playlist is empty!")
                            .foregroundColor(.white)
                            .frame(alignment: .center)
                        Spacer()
                    }
                    .frame(width: proxy.size.width)
                } else {
                    List {
                        if let playlist = viewModel.state.playlist {
                            ForEach(playlist.songsArray, id: \.self) {
                                item in
                                SongItemView(urlMp3File: item)
                                    .foregroundColor(.white)
                                    .onTapGesture {
                                        viewModel.send(intent: .playSongAt(urlStr: item))
                                    }
                                    .background(Color.backgroundColor)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                                        return 0
                                    }
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { index in
                                    viewModel.send(intent: .deleteSong(index: index))
                                }
                            }
                        }
                    }
                    .modifier(ListBackgroundModifier())
                }
                Spacer()
            }
            .navigationBarHidden(true)
            .background(Color.black)
            .transition(.slide)
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

struct LibaryDetail_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistDetailView(viewModel: PlaylistDetailViewModel())
    }
}

