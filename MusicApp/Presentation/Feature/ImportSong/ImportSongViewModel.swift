//
//  ImportSongViewModel.swift
//  MusicApp
//

import Foundation
import SwiftUI

@MainActor
protocol ImportSongViewModelProtocol: ObservableObject {
    var state: ImportSongState { get }
    func send(_ intent: ImportSongIntent)
}

final class ImportSongViewModel: ImportSongViewModelProtocol {

    @Published private(set) var state: ImportSongState = .init()
    private let importUseCase: ImportSongFromFilesUseCaseProtocol

    init(importUseCase: ImportSongFromFilesUseCaseProtocol = ImportSongFromFilesUseCase()) {
        self.importUseCase = importUseCase
    }

    func send(_ intent: ImportSongIntent) {
        switch intent {
        case .importFiles(let urls):
            startImport(urls: urls)
        case .dismissResults:
            state.isShowResults = false
            state.results = []
        }
    }

    private func startImport(urls: [URL]) {
        guard !urls.isEmpty else { return }
        state.isImporting = true
        state.progress = 0
        state.total = urls.count
        state.results = []

        Task {
            let results = await importUseCase.execute(urls: urls) { done, total in
                Task { @MainActor in
                    self.state.progress = done
                    self.state.total = total
                }
            }
            await MainActor.run {
                state.results = results
                state.isImporting = false
                state.isShowResults = true
            }
        }
    }
}
