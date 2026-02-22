//
//  TimerPickerViewModel.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation
import SwiftUI

@MainActor
final class TimerPickerViewModel: ObservableObject {

    // MARK: - State
    @Published var hours: Int = 0
    @Published var minutes: Int = 0
    @Published var seconds: Int = 0

    // MARK: - Callback
    var onSave: (Double, Double, Double) -> Void = { _, _, _ in }
    var onBack: () -> Void = {}

    // MARK: - Init
    init() {}

    // MARK: - Actions
    func save() {
        onSave(Double(hours), Double(minutes), Double(seconds))
        onBack()
    }

    func back() {
        onBack()
    }
}
