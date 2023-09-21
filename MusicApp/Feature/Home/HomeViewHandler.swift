//
//  HomeViewVM.swift
//  MusicApp
//
//  Created by Nhat on 5/25/23.
//

import Foundation
import SwiftUI

final class HomeViewHandler: ObservableObject {
    let homeItems = [HomeItemViewData(imageName: "book.fill", title: "Libary", isHiddenBottom: true),
                     HomeItemViewData(imageName: "plus.rectangle.on.folder.fill", title: "Import new song", isHiddenBottom: true),
                     HomeItemViewData(imageName: "play.circle.fill", title: "Now Playing", isHiddenBottom: false)]
}
