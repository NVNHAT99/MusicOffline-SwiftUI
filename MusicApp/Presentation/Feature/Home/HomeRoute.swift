//
//  HomeRoute.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/27/25.
//

import SwiftUI

enum HomeRoute: Routable {
    
    case nowPlaying
    
    var presentationStyle: PresentationStyle {
        switch self {
        case .nowPlaying:
            return .fullScreen
        }
    }
    
    
    @ViewBuilder
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .nowPlaying:
            EmptyView()
        }
    }
}
