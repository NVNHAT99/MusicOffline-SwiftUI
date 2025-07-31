//
//  AddNewPlaylistViewBuilder.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/25/25.
//

import SwiftUI


@MainActor
struct AddNewPlaylistBuilder {
    let router: Router<LibaryRouter>

    init(router: any RouterHandling) {
        guard let router = router as? Router<LibaryRouter> else {
            self.router = .init()
            return
        }
        self.router = router
    }

    func build() -> some View {

        return AddNewPlayListView(router: router)
    }
}
