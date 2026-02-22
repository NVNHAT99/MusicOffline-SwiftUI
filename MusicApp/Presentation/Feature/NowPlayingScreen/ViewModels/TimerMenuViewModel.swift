//
//  TimerMenuViewModel.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation
import SwiftUI

@MainActor
final class TimerMenuViewModel: ObservableObject {

    // MARK: - Callbacks
    var onCancelSleepTime: () -> Void = {}
    var onNavigateToPicker: () -> Void = {}

    // MARK: - Init
    init() {}

    // MARK: - Actions
    func navigateToPicker() {
        onNavigateToPicker()
    }

    func cancelSleepTime() {
        onCancelSleepTime()
    }
}
