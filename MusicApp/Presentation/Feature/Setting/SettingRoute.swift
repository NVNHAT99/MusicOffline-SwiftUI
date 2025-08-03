//
//  SettingRoute.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/3/25.
//

import SwiftUI

enum SettingRoute: Routable {
    case transferAudio
    
    var presentationStyle: PresentationStyle {
        switch self {
        case .transferAudio:
            return .fullScreen
        }
    }
    
    @ViewBuilder
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .transferAudio:
            if let router = router as? Router<SettingRoute> {
                TransferView(navigationHandler: router)
            } else {
                EmptyView()
            }
        }
    }
    
}
