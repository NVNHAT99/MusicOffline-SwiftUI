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
