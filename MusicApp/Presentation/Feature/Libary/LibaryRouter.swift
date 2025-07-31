//
//  LibaryRouter.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/24/25.
//

import SwiftUI

enum LibaryRouter: Routable {
    case addPlaylist
    
    var presentationStyle: PresentationStyle {
        switch self {
        case .addPlaylist:
            return .fullScreen
        }
    }
    
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .addPlaylist:
            return AddNewPlaylistBuilder(router: router).build()
        }
    }
}
