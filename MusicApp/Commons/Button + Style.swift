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


/// Subtle press style: scale + dim while held (replaces the old red-flash).
struct AnimationPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(MotionToken.springSnappy, value: configuration.isPressed)
    }
}
