//
//  ContentViewRouter.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/23/25.
//

import SwiftUI

enum MainTabViewRouter: Routable {
    case addPlayList
    
    var presentationStyle: PresentationStyle {
        switch self {
        case .addPlayList:
            return .fullScreen
        }
    }
    
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .addPlayList:
            return EmptyView()
        }
    }
}
