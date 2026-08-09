//
//  AddNewSongs.swift
//  MusicApp
//
//  Created by Nhat on 8/5/23.
//

import SwiftUI

struct EditPlaylistView<ViewModel: EditPlaylistViewModelProtocol>: View {
    // MARK: - PROPERTIES
    @StateObject var viewModel: ViewModel
    @ObservedObject var router: Router<AppRoute>
    @Binding var isEditCompleted: Bool

    init(
        viewModel: ViewModel,
        router: Router<AppRoute>,
        isEditCompleted: Binding<Bool>
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._router = .init(wrappedValue: router)
        self._isEditCompleted = isEditCompleted
    }

    var body: some View {
        VStack {
            CustomNavigationBar(type: .custom(title: "Selection Songs",
                                              left: .init(icon: "chevron.left",
                                                          action: {
                self.router.dismiss()
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
                            .foregroundColor(.primaryText)
                            .font(AppFont.body())
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
                                        .foregroundColor(.primaryText)
                                        .frame(height: 56)
                                        .entrance(index: index)
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
                self.router.dismiss()
            }
        }
    }
}

struct AddNewSongs_Previews: PreviewProvider {
    static var previews: some View {
        let container = DIContainer.preview
        EditPlaylistView(
            viewModel: container.makeEditPlaylistViewModel(playlistId: UUID()),
            router: .init(),
            isEditCompleted: .constant(false)
        )
        .environmentObject(container)
    }
}
