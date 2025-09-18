//
//  ContentViewHandler.swift
//  MusicApp
//
//  Created by Nhat on 5/25/23.
//

import Foundation

enum Tab: Int {
    case home = 1
    case libary = 2
    case setting = 3
}

@MainActor
protocol ContentViewViewModelProtocol: ObservableObject {
    var tabItems: [TabItem] { get }
}

final class ContentViewViewModel: ContentViewViewModelProtocol {
    let tabItems = [TabItem(image: "house", title: ""),
                    TabItem(image: "book", title: ""),
                    TabItem(image: "gearshape", title: ""),
    ]
}
