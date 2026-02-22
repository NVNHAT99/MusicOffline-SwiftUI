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

    init(router: any BaseRouterProtocol) {
        if let router = router as? Router<AppRoute> {
            self.router = router
        } else {
            self.router = Router()
        }
    }

    func build() -> some View {
        let dependencies = AppDependencies.shared
        let viewModel = dependencies.makeAddNewPlaylistViewModel()
        return AddNewPlayListView(viewmodel: viewModel, router: router)
    }


}
