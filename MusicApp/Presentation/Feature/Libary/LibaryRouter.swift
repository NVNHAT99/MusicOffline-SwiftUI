//
//  LibaryRouter.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/24/25.
//

import SwiftUI

enum LibaryRouter: Routable {
    case addPlaylist
    case gotoPlaylistDetail(_ playlist: Playlist?)
    case gotoEditPlaylist(_ playlistID: String, _ songIds: [UUID], _ isEditCompleted: Binding<Bool>)
    
    var presentationStyle: PresentationStyle {
        switch self {
        case .addPlaylist:
            return .fullScreen
        case .gotoPlaylistDetail:
            return .navigationLink
        case .gotoEditPlaylist:
            return .navigationLink
        }
    }
    
    @ViewBuilder
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .addPlaylist:
             AddNewPlaylistBuilder(router: router).build()
        case .gotoPlaylistDetail(let playlist):
            if let router = router as? Router<LibaryRouter> {
                let viewModel = PlaylistDetailViewModel(playlist: playlist)
                PlaylistDetailView(viewModel: viewModel, router: router)
            } else {
                EmptyView()
            }
        case .gotoEditPlaylist(let playlistID, let songIds, let isEditCompleted):
            if let router = router as? Router<LibaryRouter> {
                let viewModel = EditPlaylistViewModel(currenSongIDs: songIds, playlistID: playlistID)
                EditPlaylistView(viewModel: viewModel, router: router, isEditCompleted: isEditCompleted)
            } else {
                EmptyView()
            }
        }
    }
}
