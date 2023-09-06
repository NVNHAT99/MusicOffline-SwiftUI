//
//  Image + Modifier.swift
//  MusicApp
//
//  Created by Nhat on 8/29/23.
//

import Foundation
import SwiftUI

extension Image {
    
    func iconModifer(size: CGSize) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
    }
}
