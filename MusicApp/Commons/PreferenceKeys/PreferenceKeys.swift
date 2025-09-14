//
//  PreferenceKeys.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/2/25.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
