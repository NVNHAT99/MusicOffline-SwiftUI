//
//  PlaylistDetail.swift
//  MusicApp
//

import SwiftUI
import CoreData

struct PlaylistDetailView<ViewModel: PlaylistDetailViewModelProtocol>: View {

    @StateObject var viewModel: ViewModel
    @ObservedObject var router: Router<AppRoute>

    init(viewModel: ViewModel, router: Router<AppRoute>) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._router = .init(wrappedValue: router)
    }

    var body: some View {
        VStack(alignment: .leading) {
            CustomNavigationBar(
                type: .custom(
                    title: viewModel.getTitle(),
                    left: .init(icon: "chevron.left", action: { router.dismiss() }),
                    right: .init(title: viewModel.state.isEditMode ? "Done" : "Edit", action: {
                        viewModel.send(.toggleEditMode)
                    })
                )
            )
            .frame(height: 50)

            // Sort + bulk-delete toolbar
            if !viewModel.state.songs.isEmpty {
                HStack {
                    sortMenuButton()
                    Spacer()
                    if viewModel.state.isEditMode && !viewModel.state.selectedSongIDs.isEmpty {
                        Button(action: { viewModel.send(.bulkDelete) }) {
                            Label("Delete (\(viewModel.state.selectedSongIDs.count))", systemImage: "trash")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                    Button(action: {
                        router.route(to: .editPlaylist(playlistId: viewModel.getPlaylistId()))
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            VStack {
                if viewModel.state.isLoading {
                    ProgressView()
                } else {
                    playlistSection()
                }
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .navigationBarHidden(true)
        .background(Color.backgroundColor)
        .overlay(alignment: .bottom) {
            if viewModel.state.isShowToastView {
                ToastView(
                    isShowView: viewModel.isShowToastView(),
                    message: viewModel.state.toastViewMessage,
                    timeShowView: .seconds(2)
                )
                .frame(height: 40)
                .padding(.bottom, 16)
            }
        }
        .onAppear { viewModel.send(.loadPlaylist) }
    }

    @ViewBuilder
    private func playlistSection() -> some View {
        if !viewModel.state.songs.isEmpty {
            List {
                ForEach(Array(viewModel.state.songs.enumerated()), id: \.element.id) { index, song in
                    songRow(song: song, index: index)
                        .listRowBackground(Color.backgroundColor)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                }
                .onMove { from, to in viewModel.send(.reorderSongs(from: from, to: to)) }
                .onDelete { offsets in
                    offsets.forEach { viewModel.send(.deleteSong(index: $0)) }
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(viewModel.state.isEditMode ? .active : .inactive))
        } else {
            VStack(alignment: .center) {
                Spacer()
                Text("The playlist is empty!")
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func songRow(song: SongModel, index: Int) -> some View {
        HStack(spacing: 8) {
            if viewModel.state.isEditMode {
                Image(systemName: viewModel.state.selectedSongIDs.contains(song.id)
                      ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.state.selectedSongIDs.contains(song.id) ? .blue : .gray)
                    .onTapGesture { viewModel.send(.toggleSongSelection(id: song.id)) }
            }
            SongItemView(song: song, onTapPlayAction: {
                viewModel.send(.playSongAt(song: song))
            })
            .frame(height: 54)
        }
    }

    @ViewBuilder
    private func sortMenuButton() -> some View {
        Menu {
            Button("Name A–Z") { viewModel.send(.setSortOption(.nameAscending)) }
            Button("Date Added") { viewModel.send(.setSortOption(.dateCreated)) }
            Button("Song Count") { viewModel.send(.setSortOption(.songCount)) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                Text("Sort")
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct LibaryDetail_Previews: PreviewProvider {
    static var previews: some View {
        let container = DIContainer.preview
        PlaylistDetailView(
            viewModel: container.makePlaylistDetailViewModel(playlist: nil),
            router: .init()
        )
        .environmentObject(container)
    }
}
