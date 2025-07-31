//
//  List + Modifier.swift
//  MusicApp
//
//  Created by Nhat on 8/14/23.
//

import Foundation
import SwiftUI

struct ListBackgroundModifier: ViewModifier {

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}
