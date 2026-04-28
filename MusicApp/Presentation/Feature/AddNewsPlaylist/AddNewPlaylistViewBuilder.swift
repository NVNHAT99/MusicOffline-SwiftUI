//
//  AddNewPlaylistViewBuilder.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/25/25.
//

import SwiftUI


@MainActor
struct AddNewPlaylistBuilder {
    let router: Router<AppRoute>
    let container: DIContainer

    init(router: any BaseRouterProtocol, container: DIContainer) {
        if let router = router as? Router<AppRoute> {
            self.router = router
        } else {
            self.router = Router()
        }
        self.container = container
    }

    func build() -> some View {
        let viewModel = container.makeAddNewPlaylistViewModel()
        return AddNewPlayListView(viewmodel: viewModel, router: router)
    }
}
