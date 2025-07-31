//
//  Button + Style.swift
//  MusicApp
//
//  Created by Nhat on 5/11/23.
//

import Foundation
import SwiftUI

struct NoAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}


struct AnimationPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.red : Color.backgroundColor)
    }
}
