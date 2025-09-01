//
//  AddNewSongs.swift
//  MusicApp
//
//  Created by Nhat on 8/5/23.
//

import SwiftUI

struct EditPlaylistView: View {
    // MARK: - PROPERTIES
    @StateObject var viewModel: EditPlaylistViewModel
    @ObservedObject var router: Router<LibaryRouter>
    @Binding var isEditCompleted: Bool
    
    init(viewModel: EditPlaylistViewModel = EditPlaylistViewModel(currenSongIDs: [],
                                                                  playlistID: String.empty),
         router: Router<LibaryRouter>,
         isEditCompleted: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._router = .init(wrappedValue: router)
        self._isEditCompleted = isEditCompleted
    }
    var body: some View {
        VStack {
            CustomNavigationBar(type: .custom(title: "Selection Songs",
                                              left: .init(icon: "chevron.left",
                                                          action: {
                self.router.pop()
            }),
                                              right: .init(title: "Save",
                                                           action: {
                self.viewModel.send(intent: .savePlaylist)
            }))) // custom navigationbar
            .frame(height: 50)
            
            if viewModel.state.isLoading {
                ProgressView()
            } else {
                if viewModel.state.allSongs.isEmpty {
                    VStack(alignment: .center) {
                        Spacer()
                        Text("You don't have any song to add")
                            .foregroundColor(.white)
                            .frame(alignment: .center)
                            .transition(.opacity)
                        Spacer()
                    }
                    .frame(width: Helper.shared.keyWindown?.bounds.width ?? 200)
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(Array(viewModel.state.allSongs.enumerated()),
                                    id: \.element.id) { index, songData in
                                Button {
                                    viewModel.send(intent: .toggleSelectedAt(index: index))
                                } label: {
                                    SelectedSongItemView(songData: songData)
                                        .foregroundColor(.white)
                                        .frame(height: 56)
                                        
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        } // VStack
        .background(Color.backgroundColor)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.send(intent: .loadListSong)
        }
        .onChange(of: self.viewModel.state.isSavePlaylistSuccess) { _, newValue in
            if newValue {
                self.isEditCompleted = true
                self.router.pop()
            }
        }
    }
}

struct AddNewSongs_Previews: PreviewProvider {
    static var previews: some View {
        EditPlaylistView(viewModel: .init(currenSongIDs: [],
                                          playlistID: String.empty),
                         router: .init(),
                         isEditCompleted: .constant(false))
    }
}
